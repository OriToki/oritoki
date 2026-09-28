# Cuts the two carabiner-and-knot assemblies out of the owner's finished drawing so they can turn
# with their ropes, and leaves everything else - the lettering and both bolt hangers - behind.
#
# READ THIS BEFORE CHANGING IT. The mark was once BUILT from separate pieces fitted back against
# the finished drawing, and that is what put a rope loop on top of a carabiner instead of through
# it: a fit can be right on every piece and still stack them wrong. Nothing is fitted here. Every
# pixel written out is a pixel OF THE FINISHED DRAWING, and each one goes to exactly one layer
# (black outlines to every layer they touch), so stacking the layers with no rotation reproduces
# the drawing exactly. The script checks that before it writes anything.
#
# The cut is made along the drawing's OWN boundaries, not along a line drawn over it: the picture
# is split into blobs of light ink, each blob being one piece of the drawing because a black
# outline separates it from its neighbours, and each blob then goes whole to one layer or the
# other. Cutting by a geometric line instead would slice the anchor's plate in half, because the
# plate and the carabiner's ring overlap in every row they share.
#
# Order on the page is what makes it read right: both moving layers go UNDER the static one. In
# this drawing the hanger is in front of its carabiner and the lettering is in front of both, so
# "static on top" is true everywhere, and a carabiner that turns simply slides under them.
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\parts\final logo.png",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [int]$OutW = 400,
  [switch]$DryRun
)
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap($Src)
$rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
$dat = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $dat.Stride
$buf = New-Object 'byte[]' ($stride * $bmp.Height)
[System.Runtime.InteropServices.Marshal]::Copy($dat.Scan0, $buf, 0, $buf.Length)
$bmp.UnlockBits($dat)
$wid = $bmp.Width; $hei = $bmp.Height
"source: $wid x $hei"

# ---- the two assemblies, in the DRAWING's own pixels ------------------------------------------
# A blob belongs to an assembly when its centre of mass falls in that assembly's box and not on
# its hanger's diagonal bar. The bar is the one piece of hanger whose centre lands inside the box
# - the plate's is above it - and it has to be kept out by shape, because it crosses the ring.
# The lower assembly is the upper one moved by the distance between the two pivots the owner
# marked: (151, 474).
$dx = 151; $dy = 474
$upBox = @(780, 170, 1015, 770)
$loBox = @((780 + $dx), (170 + $dy), (1015 + $dx), (770 + $dy))
$upBar = @(@(824, 107), @(846, 95), @(938, 263), @(916, 275))
$loBar = @()
foreach ($p in $upBar) { $loBar += ,@(($p[0] + $dx), ($p[1] + $dy)) }

function InBox($bx, $x, $y) { return ($x -ge $bx[0] -and $x -le $bx[2] -and $y -ge $bx[1] -and $y -le $bx[3]) }
function InPoly($poly, [double]$px, [double]$py) {
  $inside = $false; $n = $poly.Count; $j = $n - 1
  for ($i = 0; $i -lt $n; $i++) {
    $xi = $poly[$i][0]; $yi = $poly[$i][1]; $xj = $poly[$j][0]; $yj = $poly[$j][1]
    if ((($yi -gt $py) -ne ($yj -gt $py)) -and
        ($px -lt ($xj - $xi) * ($py - $yi) / ($yj - $yi) + $xi)) { $inside = -not $inside }
    $j = $i
  }
  return $inside
}

# ---- segment the LIGHT ink into blobs ---------------------------------------------------------
# Light = drawn and not outline. The outlines are what separate one piece of the drawing from the
# next, so flooding over light ink alone gives one blob per piece.
$LIGHT = 90
$owner = New-Object 'byte[]' ($wid * $hei)      # 0 = static, 1 = upper, 2 = lower
$seen = New-Object 'bool[]' ($wid * $hei)
$blobs = @()
for ($y = 0; $y -lt $hei; $y++) {
  for ($x = 0; $x -lt $wid; $x++) {
    $i = $y * $wid + $x
    if ($seen[$i]) { continue }
    $p = $y * $stride + $x * 4
    if ($buf[$p + 3] -le 40) { $seen[$i] = $true; continue }
    $g = ([int]$buf[$p] + [int]$buf[$p + 1] + [int]$buf[$p + 2]) / 3
    if ($g -le $LIGHT) { $seen[$i] = $true; continue }
    $stk = New-Object System.Collections.Generic.Stack[int]
    $stk.Push($i); $seen[$i] = $true
    $cells = New-Object System.Collections.Generic.List[int]
    $sx = 0.0; $sy = 0.0
    while ($stk.Count -gt 0) {
      $j = $stk.Pop()
      $jy = [Math]::Floor($j / $wid); $jx = $j - $jy * $wid
      $cells.Add($j); $sx += $jx; $sy += $jy
      foreach ($dd in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $jx + $dd[0]; $ny = $jy + $dd[1]
        if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $wid -or $ny -ge $hei) { continue }
        $k = $ny * $wid + $nx
        if ($seen[$k]) { continue }
        $seen[$k] = $true
        $q = $ny * $stride + $nx * 4
        if ($buf[$q + 3] -le 40) { continue }
        $gg = ([int]$buf[$q] + [int]$buf[$q + 1] + [int]$buf[$q + 2]) / 3
        if ($gg -le $LIGHT) { continue }
        $stk.Push($k)
      }
    }
    $n = $cells.Count
    if ($n -lt 30) { continue }
    $cx = $sx / $n; $cy = $sy / $n
    $who = 0
    if ((InBox $upBox $cx $cy) -and -not (InPoly $upBar $cx $cy)) { $who = 1 }
    elseif ((InBox $loBox $cx $cy) -and -not (InPoly $loBar $cx $cy)) { $who = 2 }
    if ($who -ne 0) { foreach ($c in $cells) { $owner[$c] = $who } }
    $blobs += ,@{ n = $n; x = $cx; y = $cy; who = $who }
  }
}
"blobs of 30px or more: $($blobs.Count)"
foreach ($b in ($blobs | Sort-Object { -$_.n } | Select-Object -First 26)) {
  "  {0,7} px at ({1,6:N0},{2,6:N0})  ->  {3}" -f $b.n, $b.x, $b.y, @("static", "UPPER", "LOWER")[$b.who]
}

# ---- outlines -------------------------------------------------------------------------------
# A black pixel goes to EVERY layer whose light ink it touches, and to the static one if it
# touches none. Sharing it is what keeps both sides of a boundary outlined once they move apart;
# giving it to one side would leave the other with a bare edge.
# Only SOLID black is shared. A half-transparent edge pixel drawn twice composites with itself and
# comes out darker and more opaque than the drawing, which the check at the end catches as a
# difference - so those go to the static layer alone, where they were going to be covered anyway.
$blk = New-Object 'byte[]' ($wid * $hei)        # bit 0 = static, bit 1 = upper, bit 2 = lower
for ($y = 0; $y -lt $hei; $y++) {
  for ($x = 0; $x -lt $wid; $x++) {
    $p = $y * $stride + $x * 4
    if ($buf[$p + 3] -eq 0) { continue }
    $g = ([int]$buf[$p] + [int]$buf[$p + 1] + [int]$buf[$p + 2]) / 3
    if ($g -gt $LIGHT) { continue }
    $m = 0
    if ($buf[$p + 3] -ge 250) {
      for ($ddy = -3; $ddy -le 3; $ddy++) {
        for ($ddx = -3; $ddx -le 3; $ddx++) {
          $nx = $x + $ddx; $ny = $y + $ddy
          if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $wid -or $ny -ge $hei) { continue }
          $o = $owner[$ny * $wid + $nx]
          if ($o -eq 1) { $m = $m -bor 2 } elseif ($o -eq 2) { $m = $m -bor 4 }
        }
      }
    }
    if ($m -eq 0) { $m = 1 } else { $m = $m -bor 1 }   # keep the static copy too - it is on top
    $blk[$y * $wid + $x] = $m
  }
}

# ---- write the three layers, all on the mark's own cropped box --------------------------------
$lx = $wid; $hx = -1; $ly = $hei; $hy = -1
for ($y = 0; $y -lt $hei; $y++) { for ($x = 0; $x -lt $wid; $x++) {
  if ($buf[$y * $stride + $x * 4 + 3] -le 40) { continue }
  if ($x -lt $lx) { $lx = $x }; if ($x -gt $hx) { $hx = $x }
  if ($y -lt $ly) { $ly = $y }; if ($y -gt $hy) { $hy = $y } } }
$bw = $hx - $lx + 1; $bh = $hy - $ly + 1
"ink box: x $lx..$hx  y $ly..$hy   ($bw x $bh)"

$layers = @{}
foreach ($nm in @("rest", "work", "back")) {
  $layers[$nm] = New-Object System.Drawing.Bitmap($bw, $bh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
for ($y = $ly; $y -le $hy; $y++) {
  for ($x = $lx; $x -le $hx; $x++) {
    $p = $y * $stride + $x * 4
    # every drawn pixel, down to the faintest edge: dropping those at 40 or less left 3005 of them
    # out and the stack no longer matched the drawing on alpha
    if ($buf[$p + 3] -eq 0) { continue }
    $c = [System.Drawing.Color]::FromArgb($buf[$p + 3], $buf[$p + 2], $buf[$p + 1], $buf[$p])
    $g = ([int]$buf[$p] + [int]$buf[$p + 1] + [int]$buf[$p + 2]) / 3
    $tx = $x - $lx; $ty = $y - $ly
    if ($g -gt $LIGHT) {
      $o = $owner[$y * $wid + $x]
      $layers[@("rest", "work", "back")[$o]].SetPixel($tx, $ty, $c)
    } else {
      $m = $blk[$y * $wid + $x]
      if ($m -band 1) { $layers["rest"].SetPixel($tx, $ty, $c) }
      if ($m -band 2) { $layers["work"].SetPixel($tx, $ty, $c) }
      if ($m -band 4) { $layers["back"].SetPixel($tx, $ty, $c) }
    }
  }
}

# ---- check: the three, stacked as the page stacks them, must BE the drawing -------------------
$flat = New-Object System.Drawing.Bitmap($bw, $bh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gf = [System.Drawing.Graphics]::FromImage($flat)
foreach ($nm in @("work", "back", "rest")) { $gf.DrawImage($layers[$nm], 0, 0) }
$gf.Dispose()
# Colour is only compared where the drawing is SOLID. GDI+ composites source-over onto an empty
# bitmap as if the empty part were opaque black, so a half-transparent edge pixel comes back with
# its colour dragged towards black even when nothing is wrong with it. Alpha is compared
# everywhere, and alpha is what would actually show a pixel going to the wrong layer or to none.
$badA = 0; $worstA = 0; $badC = 0; $worstC = 0
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    $p = ($y + $ly) * $stride + ($x + $lx) * 4
    $o = $flat.GetPixel($x, $y)
    $da = [Math]::Abs([int]$o.A - [int]$buf[$p + 3])
    if ($da -gt 8) { $badA++; if ($da -gt $worstA) { $worstA = $da } }
    if ($buf[$p + 3] -lt 250) { continue }
    $dr = [Math]::Abs([int]$o.R - [int]$buf[$p + 2])
    $dg = [Math]::Abs([int]$o.G - [int]$buf[$p + 1])
    $db = [Math]::Abs([int]$o.B - [int]$buf[$p])
    $m = [Math]::Max($dr, [Math]::Max($dg, $db))
    if ($m -gt 8) { $badC++; if ($m -gt $worstC) { $worstC = $m } }
  }
}
"stacked-vs-drawing, out of $($bw * $bh) px:"
"   alpha  : $badA differ by more than 8 (worst $worstA)"
"   colour : $badC of the solid pixels differ by more than 8 (worst $worstC)"
$flat.Dispose()

if ($DryRun) { foreach ($nm in $layers.Keys) { $layers[$nm].Dispose() }; $bmp.Dispose(); return }

$outH = [int][Math]::Round($OutW * $bh / $bw)
foreach ($nm in @("rest", "work", "back")) {
  $small = New-Object System.Drawing.Bitmap($OutW, $outH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g2 = [System.Drawing.Graphics]::FromImage($small)
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g2.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g2.DrawImage($layers[$nm], (New-Object System.Drawing.Rectangle 0, 0, $OutW, $outH), 0, 0, $bw, $bh, [System.Drawing.GraphicsUnit]::Pixel)
  $g2.Dispose()
  $f = Join-Path $OutDir ("logo-" + $nm + ".png")
  $small.Save($f, [System.Drawing.Imaging.ImageFormat]::Png)
  $small.Dispose(); $layers[$nm].Dispose()
  "wrote $f   ($OutW x $outH)"
}
$bmp.Dispose()
