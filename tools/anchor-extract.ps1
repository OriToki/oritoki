# Repo root, resolved from this script's location.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Cuts one anchor (bolt hanger + locking carabiner + knot) out of the owner's anchors.png and
# saves it as a transparent PNG for index.html to hang the ropes from.
#
# Only the OUTER white is removed: the white inside the carabiner and the knot is part of the
# drawing, exactly as in climber.png, and keying every white pixel would leave the hardware hollow
# on the dark theme. A flood fill from the border tells the two apart.
param(
  [int]$X1 = 1014, [int]$Y1 = 540, [int]$X2 = 1298, [int]$Y2 = 1552,   # the right-hand anchor
  [int]$OutW = 112,                                                     # 8x its on-page size
  [string]$Out = "$REPO\images\anchor.png"
)
Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap("C:\Users\gilmo\OneDrive\Desktop\anchors.png")
$w = $X2 - $X1; $h = $Y2 - $Y1
$crop = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($crop)
$g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)),
                   (New-Object System.Drawing.Rectangle($X1, $Y1, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $src.Dispose()

# flood fill the outer white from the border
$N = $w * $h
$bg = New-Object bool[] $N
$stack = New-Object System.Collections.Generic.Stack[int]
function IsPale([System.Drawing.Color]$c) { return (($c.R + $c.G + $c.B) / 3) -gt 233 }
for ($x = 0; $x -lt $w; $x++) { foreach ($y in 0, ($h - 1)) { $i = $y * $w + $x
  if (-not $bg[$i] -and (IsPale $crop.GetPixel($x, $y))) { $bg[$i] = $true; $stack.Push($i) } } }
for ($y = 0; $y -lt $h; $y++) { foreach ($x in 0, ($w - 1)) { $i = $y * $w + $x
  if (-not $bg[$i] -and (IsPale $crop.GetPixel($x, $y))) { $bg[$i] = $true; $stack.Push($i) } } }
while ($stack.Count -gt 0) {
  $i = $stack.Pop(); $x = $i % $w; $y = [int](($i - $x) / $w)
  foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) {
    $nx = $x + $d[0]; $ny = $y + $d[1]
    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) {
      $j = $ny * $w + $nx
      if (-not $bg[$j] -and (IsPale $crop.GetPixel($nx, $ny))) { $bg[$j] = $true; $stack.Push($j) } } } }

$cut = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
  if ($bg[$y * $w + $x]) { $cut.SetPixel($x, $y, $clear) } else { $cut.SetPixel($x, $y, $crop.GetPixel($x, $y)) } } }
$crop.Dispose()

# scale down to the asset size
$oh = [int]([math]::Round($h * $OutW / $w))
$dst = New-Object System.Drawing.Bitmap($OutW, $oh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g2 = [System.Drawing.Graphics]::FromImage($dst)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.DrawImage($cut, 0, 0, $OutW, $oh)
$g2.Dispose(); $cut.Dispose()
$dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
"saved: $Out  ({0}x{1} from a {2}x{3} crop)" -f $OutW, $oh, $w, $h


