# Splits the anchor into the two things it actually is - the bolt hanger, and the carabiner with
# its knot and rope - and gives the rope the site's own braided texture.
#
# The two interlock in the drawing: the hanger's tongue crosses the carabiner's frame. Cutting them
# apart along a row, or along a hand-drawn band, always left a shred of one piece attached to the
# other, which showed the moment the carabiner turned. So nothing is cut here. Instead EVERY inked
# pixel is assigned to whichever object it belongs to:
#
#   1. the drawing's closed fills are labelled by hand-picked seeds - plate, nut, bolt head and
#      tongue belong to the hanger; the frame, gate, nose, knot and rope to the carabiner;
#   2. the black linework between them is then handed out by a race: both labels grow outwards a
#      pixel at a time and each outline pixel goes to whichever object reaches it first, which is
#      the one it was drawn for.
#
# The result is two full-size images that overlay exactly, each holding only its own object.
param(
  [int]$X1 = 1014, [int]$Y1 = 540, [int]$X2 = 1298, [int]$Y2 = 1552,
  # a pixel inside each closed fill of the HANGER
  [int[]]$Hanger = @(169,13,   # the plate
                     173,25,   # the nut's face
                     170,39,   # the bolt head
                     72,38,    # the tongue
                     115,131), # the sliver of plate the tongue cuts off
  # ...and of the CARABINER and what hangs from it
  [int[]]$Carab  = @(90,136,   # the frame's left arm
                     121,143,  # its top bar
                     136,180,  # the wedge under the tongue - frame, not a hole
                     223,201,  # the nose, where the gate closes
                     119,900), # the rope below the knot
  # openings you can see through
  [int[]]$Holes  = @(150,350,  # the carabiner's
                     102,92),  # the hanger's eye, above the carabiner's bar
  [double]$Tile = 14.0, [double]$LineW = 5.0,
  [int]$OutW = 128,
  [string]$OutDir = "c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images"
)
Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap("C:\Users\gilmo\OneDrive\Desktop\anchors.png")
$w = $X2 - $X1; $h = $Y2 - $Y1; $N = $w * $h
$crop = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g0 = [System.Drawing.Graphics]::FromImage($crop)
$g0.DrawImage($src, (New-Object System.Drawing.Rectangle(0,0,$w,$h)), (New-Object System.Drawing.Rectangle($X1,$Y1,$w,$h)), [System.Drawing.GraphicsUnit]::Pixel)
$g0.Dispose(); $src.Dispose()

$lum = New-Object byte[] $N
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
  $c = $crop.GetPixel($x, $y); $lum[$y*$w + $x] = [byte](($c.R + $c.G + $c.B) / 3) } }

function Flood([int]$sx, [int]$sy, [byte[]]$into, [byte]$val) {
  $s0 = $sy*$w + $sx
  if ($lum[$s0] -le 233) { return }
  $st = New-Object System.Collections.Generic.Stack[int]; $st.Push($s0); $into[$s0] = $val
  while ($st.Count -gt 0) { $i = $st.Pop(); $x = $i % $w; $y = [int](($i - $x) / $w)
    foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) { $nx = $x + $d[0]; $ny = $y + $d[1]
      if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
        if ($into[$j] -eq 0 -and $lum[$j] -gt 233) { $into[$j] = $val; $st.Push($j) } } } }
}

# 1 = hanger, 2 = carabiner, 3 = background or hole (not part of either)
$own = New-Object byte[] $N
for ($x = 0; $x -lt $w; $x++) { Flood $x 0 $own 3; Flood $x ($h-1) $own 3 }
for ($y = 0; $y -lt $h; $y++) { Flood 0 $y $own 3; Flood ($w-1) $y $own 3 }
for ($k = 0; $k -lt $Holes.Length;  $k += 2) { Flood $Holes[$k]  $Holes[$k+1]  $own 3 }
for ($k = 0; $k -lt $Hanger.Length; $k += 2) { Flood $Hanger[$k] $Hanger[$k+1] $own 1 }
for ($k = 0; $k -lt $Carab.Length;  $k += 2) { Flood $Carab[$k]  $Carab[$k+1]  $own 2 }
# the rope's own fill is the carabiner's side too, wherever it runs
for ($i = 0; $i -lt $N; $i++) { if ($own[$i] -eq 0 -and $lum[$i] -ge 190 -and $lum[$i] -le 228) { $own[$i] = 2 } }

# the race for the linework: both labels grow a pixel at a time over everything still unclaimed
$q = New-Object System.Collections.Generic.Queue[int]
for ($i = 0; $i -lt $N; $i++) { if ($own[$i] -eq 1 -or $own[$i] -eq 2) { $q.Enqueue($i) } }
while ($q.Count -gt 0) { $i = $q.Dequeue(); $v = $own[$i]; $x = $i % $w; $y = [int](($i - $x) / $w)
  foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) { $nx = $x + $d[0]; $ny = $y + $d[1]
    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
      if ($own[$j] -eq 0) { $own[$j] = $v; $q.Enqueue($j) } } } }

# paint: rope fill -> weave, rope outline -> the drawn rope's edge grey, everything else as drawn
$core = [System.Drawing.Color]::FromArgb(255,238,238,238)
$dark = [System.Drawing.Color]::FromArgb(255,21,21,21)
$edge = [System.Drawing.Color]::FromArgb(255,97,97,97)
$clear = [System.Drawing.Color]::FromArgb(0,0,0,0)
$r2 = [math]::Sqrt(2)
$isRope = New-Object bool[] $N
for ($i = 0; $i -lt $N; $i++) { if ($lum[$i] -ge 190 -and $lum[$i] -le 228) { $isRope[$i] = $true } }
function NearRope([int]$x, [int]$y) {
  for ($dy = -3; $dy -le 3; $dy++) { for ($dx = -3; $dx -le 3; $dx++) {
    $nx = $x+$dx; $ny = $y+$dy
    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { if ($isRope[$ny*$w + $nx]) { return $true } } } }
  return $false
}
function Emit([byte]$which, [string]$name) {
  $piece = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) { $i = $y*$w + $x
    if ($own[$i] -ne $which) { $piece.SetPixel($x, $y, $clear); continue }
    if ($isRope[$i]) {
      $u = (($x + $y) / $r2) % $Tile; if ($u -lt 0) { $u += $Tile }
      $v = (($x - $y) / $r2) % $Tile; if ($v -lt 0) { $v += $Tile }
      if ($u -lt $LineW -or $v -lt $LineW) { $piece.SetPixel($x, $y, $dark) } else { $piece.SetPixel($x, $y, $core) }
    } elseif ($lum[$i] -lt 120 -and (NearRope $x $y)) { $piece.SetPixel($x, $y, $edge) }
    else { $piece.SetPixel($x, $y, $crop.GetPixel($x, $y)) } } }
  $oh = [int]([math]::Round($h * $OutW / $w))
  $outB = New-Object System.Drawing.Bitmap($OutW, $oh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g2 = [System.Drawing.Graphics]::FromImage($outB)
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g2.DrawImage($piece, 0, 0, $OutW, $oh); $g2.Dispose(); $piece.Dispose()
  $outB.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png); $outB.Dispose()
  "  $name  ${OutW}x$oh"
}
Emit 1 "anchor-bolt.png"
Emit 2 "anchor-hang.png"
$crop.Dispose()
"both pieces are full size and overlay exactly; the hanging one turns about (118,168) of $w x $h"
