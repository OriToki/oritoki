# Splits the anchor into the bolt hanger and the carabiner-with-knot-and-rope, and gives the rope
# the site's braided texture.
#
# WHERE THE BOUNDARY COMES FROM: the owner drew it. The two objects interlock in the drawing - the
# hanger's tongue crosses the carabiner's frame - and no rule I tried could tell which outline
# belonged to which; each attempt left a shred of one object attached to the other, which showed
# the moment the carabiner turned. So the split is now read straight off a marked-up copy of the
# artwork: YELLOW strokes trace the hanger, GREEN the carabiner. Those strokes seed the two labels,
# and everything else inked is handed out by a race between them - each pixel goes to whichever
# label reaches it first, which is the object whose line it lies nearest.
#
# Re-marking is the way to change the split: edit the marked file, run this again.
param(
  [string]$Marked = "C:\Users\gilmo\OneDrive\Desktop\anchor carabiner.png",
  [int]$MarkPad = 54, [int]$MarkZoom = 3,   # how that file maps back to the artwork
  [int]$X1 = 1014, [int]$Y1 = 540, [int]$X2 = 1298, [int]$Y2 = 1552,
  [int[]]$Holes = @(150,350,  # the carabiner's opening
                    102,92),  # the hanger's eye, above the carabiner's bar
  [int[]]$RopeSeed = @(119,900),          # the rope below the knot - carabiner's side
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

# ---- the owner's strokes, sampled back onto the artwork -------------------------------------
$mk = New-Object System.Drawing.Bitmap($Marked)
$mark = New-Object byte[] $N                       # 1 = hanger (yellow), 2 = carabiner (green)
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
  $mx = $MarkPad + $x * $MarkZoom; $my = $MarkPad + $y * $MarkZoom
  if ($mx -lt 0 -or $my -lt 0 -or $mx -ge $mk.Width - 2 -or $my -ge $mk.Height - 2) { continue }
  for ($dy = 0; $dy -lt $MarkZoom; $dy++) { for ($dx = 0; $dx -lt $MarkZoom; $dx++) {
    $c = $mk.GetPixel($mx + $dx, $my + $dy)
    if ($c.R -gt 180 -and $c.G -gt 150 -and $c.B -lt 120) { $mark[$y*$w + $x] = 1 }
    elseif ($c.R -lt 140 -and $c.G -gt 110 -and $c.B -lt 140 -and ($c.G - $c.R) -gt 40) {
      if ($mark[$y*$w + $x] -eq 0) { $mark[$y*$w + $x] = 2 } } } } } }
$mk.Dispose()

function Flood([int]$sx, [int]$sy, [byte[]]$into, [byte]$val) {
  $s0 = $sy*$w + $sx
  if ($lum[$s0] -le 233) { return }
  $st = New-Object System.Collections.Generic.Stack[int]; $st.Push($s0); $into[$s0] = $val
  while ($st.Count -gt 0) { $i = $st.Pop(); $x = $i % $w; $y = [int](($i - $x) / $w)
    foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) { $nx = $x + $d[0]; $ny = $y + $d[1]
      if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
        if ($into[$j] -eq 0 -and $lum[$j] -gt 233) { $into[$j] = $val; $st.Push($j) } } } }
}

# 1 = hanger, 2 = carabiner, 3 = background or hole
$own = New-Object byte[] $N
for ($x = 0; $x -lt $w; $x++) { Flood $x 0 $own 3; Flood $x ($h-1) $own 3 }
for ($y = 0; $y -lt $h; $y++) { Flood 0 $y $own 3; Flood ($w-1) $y $own 3 }
for ($k = 0; $k -lt $Holes.Length; $k += 2) { Flood $Holes[$k] $Holes[$k+1] $own 3 }
# The rope and knot are filled with one flat grey (206,207,209). Testing for a range of greys is
# not enough: every black-on-white edge in the drawing is anti-aliased through those same greys, so
# a plain range marks the whole linework as rope - which then dragged entire objects onto the
# carabiner's side. A pixel counts as rope only if its neighbours are that grey too, which one-pixel
# edges never are.
$isRope = New-Object bool[] $N
for ($y = 1; $y -lt $h-1; $y++) { for ($x = 1; $x -lt $w-1; $x++) { $i = $y*$w + $x
  if ($lum[$i] -lt 196 -or $lum[$i] -gt 218) { continue }
  $same = 0
  for ($dy = -1; $dy -le 1; $dy++) { for ($dx = -1; $dx -le 1; $dx++) {
    $L = $lum[($y+$dy)*$w + ($x+$dx)]; if ($L -ge 196 -and $L -le 218) { $same++ } } }
  if ($same -ge 7) { $isRope[$i] = $true } } }

# The strokes are drawn just OUTSIDE each object's outline, not on it, so they cannot seed the ink
# directly. They are used as guides instead: every pixel takes the label of whichever stroke is
# nearest to it, worked out by growing both labels a pixel at a time across the whole image. An
# inked pixel then belongs to the object whose outline was drawn closest to it.
$near = New-Object byte[] $N
$q = New-Object System.Collections.Generic.Queue[int]
for ($i = 0; $i -lt $N; $i++) { if ($mark[$i] -ne 0) { $near[$i] = $mark[$i]; $q.Enqueue($i) } }
while ($q.Count -gt 0) { $i = $q.Dequeue(); $v = $near[$i]; $x = $i % $w; $y = [int](($i - $x) / $w)
  foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) { $nx = $x + $d[0]; $ny = $y + $d[1]
    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
      if ($near[$j] -eq 0) { $near[$j] = $v; $q.Enqueue($j) } } } }
# A closed shape in the drawing belongs to ONE object, so it is never split down the middle: each
# fill is taken whole and given to the label most of it lies nearest to. (Assigning pixel by pixel
# instead cut bites out of both objects wherever the two strokes ran close together.)
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) { $i0 = $y*$w + $x
  if ($own[$i0] -ne 0) { continue }
  $kindPale = ($lum[$i0] -gt 233)
  if (-not $kindPale -and -not $isRope[$i0]) { continue }
  # flood within ONE kind only - a white fill never merges with the rope through a stray edge pixel
  $cells = New-Object System.Collections.Generic.List[int]
  $st = New-Object System.Collections.Generic.Stack[int]; $st.Push($i0); $own[$i0] = 9   # 9 = seen
  $vote1 = 0; $vote2 = 0
  while ($st.Count -gt 0) { $i = $st.Pop(); $cells.Add($i) | Out-Null
    if ($near[$i] -eq 1) { $vote1++ } elseif ($near[$i] -eq 2) { $vote2++ }
    $cx = $i % $w; $cy = [int](($i - $cx) / $w)
    foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) { $nx = $cx + $d[0]; $ny = $cy + $d[1]
      if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
        if ($own[$j] -ne 0) { continue }
        $ok = if ($kindPale) { $lum[$j] -gt 233 } else { $isRope[$j] }
        if ($ok) { $own[$j] = 9; $st.Push($j) } } } }
  # the rope and its knot are always the carabiner's; a white fill goes where its stroke says
  if (-not $kindPale) { $lab = [byte]2 } elseif ($vote1 -ge $vote2) { $lab = [byte]1 } else { $lab = [byte]2 }
  if ($cells.Count -gt 400) { "    shape {0,6} px at ({1},{2})  H={3} C={4} {5} -> {6}" -f $cells.Count, ($i0 % $w), [int](($i0 - ($i0 % $w))/$w), $vote1, $vote2, $(if($kindPale){"fill"}else{"rope"}), $lab }
  foreach ($c in $cells) { $own[$c] = $lab } } }

# the outlines are then handed out by a race between the labelled fills: each line pixel goes to
# whichever object reaches it first, which is the one it was drawn for
$q2 = New-Object System.Collections.Generic.Queue[int]
for ($i = 0; $i -lt $N; $i++) { if ($own[$i] -eq 1 -or $own[$i] -eq 2) { $q2.Enqueue($i) } }
while ($q2.Count -gt 0) { $i = $q2.Dequeue(); $v = $own[$i]; $x = $i % $w; $y = [int](($i - $x) / $w)
  foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) { $nx = $x + $d[0]; $ny = $y + $d[1]
    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
      if ($own[$j] -eq 0) { $own[$j] = $v; $q2.Enqueue($j) } } } }

$core = [System.Drawing.Color]::FromArgb(255,238,238,238)
$dark = [System.Drawing.Color]::FromArgb(255,21,21,21)
$edge = [System.Drawing.Color]::FromArgb(255,97,97,97)
$clear = [System.Drawing.Color]::FromArgb(0,0,0,0)
$r2 = [math]::Sqrt(2)
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
$hn = 0; $cn = 0
for ($i = 0; $i -lt $N; $i++) { if ($own[$i] -eq 1) { $hn++ } elseif ($own[$i] -eq 2) { $cn++ } }
"hanger {0} px, carabiner {1} px" -f $hn, $cn
Emit 1 "anchor-bolt.png"
Emit 2 "anchor-hang.png"
$crop.Dispose()
