# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Turns the owner's flat icon into line art that matches climber.png's style:
#   fill = the icon's silhouette, lines = its interior gaps, plus a black contour around it.
# The icon has NO black pixels of its own - its "lines" are gaps, and many of them open onto
# the background, so a plain flood fill can't tell line from background. A morphological
# CLOSING can: it seals gaps narrower than the brush while leaving the open background alone.
param(
  [int]$Size = 260,          # working resolution
  [int]$CloseR = 7,          # half-width of the closing brush (seals the line gaps)
  [int]$OutlineR = 3,        # thickness of the black contour
  [int]$Fill = 150, [double]$CutX = 520,          # grey of the body
  [string]$Out = "C:\Users\gilmo\Downloads\device-lineart.png"
)
Add-Type -AssemblyName System.Drawing
$icon = New-Object System.Drawing.Bitmap("C:\Users\gilmo\OneDrive\Desktop\Gear iqones\back up device back ground.png")
$small = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($small)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($icon, 0, 0, $Size, $Size)
$g.Dispose(); $icon.Dispose()

$N = $Size * $Size
$ink = New-Object bool[] $N
# The icon carries its own absorber tube on the left; the artwork already HAS an absorber, so
# the tube is cut off here - before the outline is computed, so the cut edge gets a contour too.
$cut = [int]($CutX * $Size / 1254)
for ($y = 0; $y -lt $Size; $y++) { for ($x = 0; $x -lt $Size; $x++) {
  if ($x -ge $cut -and $small.GetPixel($x, $y).A -gt 60) { $ink[$y*$Size + $x] = $true } } }

# separable square dilate / erode
function Grow([bool[]]$m, [int]$r, [bool]$dilate) {
  $tmp = New-Object bool[] $N; $res = New-Object bool[] $N
  for ($y = 0; $y -lt $Size; $y++) { $row = $y*$Size
    for ($x = 0; $x -lt $Size; $x++) {
      $v = -not $dilate
      for ($k = -$r; $k -le $r; $k++) { $xx = $x + $k
        if ($xx -lt 0 -or $xx -ge $Size) { $s = -not $dilate } else { $s = $m[$row + $xx] }
        if ($dilate) { if ($s) { $v = $true; break } } else { if (-not $s) { $v = $false; break } } }
      $tmp[$row + $x] = $v } }
  for ($x = 0; $x -lt $Size; $x++) {
    for ($y = 0; $y -lt $Size; $y++) {
      $v = -not $dilate
      for ($k = -$r; $k -le $r; $k++) { $yy = $y + $k
        if ($yy -lt 0 -or $yy -ge $Size) { $s = -not $dilate } else { $s = $tmp[$yy*$Size + $x] }
        if ($dilate) { if ($s) { $v = $true; break } } else { if (-not $s) { $v = $false; break } } }
      $res[$y*$Size + $x] = $v } }
  return $res
}

$closed  = Grow (Grow $ink $CloseR $true) $CloseR $false     # closing: seals the line gaps
$outline = Grow $closed $OutlineR $true                       # ring around the whole device

$res = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$black = [System.Drawing.Color]::FromArgb(255, 24, 24, 24)
$body  = [System.Drawing.Color]::FromArgb(255, $Fill, $Fill, $Fill)
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
for ($y = 0; $y -lt $Size; $y++) { for ($x = 0; $x -lt $Size; $x++) { $i = $y*$Size + $x
  if ($ink[$i])        { $res.SetPixel($x, $y, $body) }
  elseif ($closed[$i]) { $res.SetPixel($x, $y, $black) }
  elseif ($outline[$i]){ $res.SetPixel($x, $y, $black) }
  else                 { $res.SetPixel($x, $y, $clear) } } }
$res.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"saved: $Out  ($Size px, close $CloseR, outline $OutlineR, fill $Fill)"
$res.Dispose(); $small.Dispose()



