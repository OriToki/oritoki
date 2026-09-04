# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Drops the line-art device (device-lineart.png) into climber.png in place of the old plate.
# Only the device BODY is used - the artwork keeps its own absorber + carabiner, and the body
# is placed so that carabiner clips into it.
param(
  [int]$EraseX = 297, [int]$EraseY = 61, [int]$EraseW = 57, [int]$EraseH = 79,
  [double]$CX = 324, [double]$CY = 102, [double]$BodyH = 65, [double]$Rot = 0,
  # body box inside device-lineart.png (260x260), = icon px 505/195..1195/1065 scaled by 260/1254
  [double]$BX1 = 104.7, [double]$BY1 = 40.4, [double]$BX2 = 247.7, [double]$BY2 = 220.7,
  [string]$Out = "$REPO\images\climber-newdevice.png"
)
Add-Type -AssemblyName System.Drawing
$dev = New-Object System.Drawing.Bitmap("C:\Users\gilmo\Downloads\device-lineart.png")
$src = New-Object System.Drawing.Bitmap("$REPO\images\climber.png")
$dst = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.DrawImage($src, 0, 0, $src.Width, $src.Height)
$g.Dispose()

for ($y = $EraseY; $y -lt $EraseY + $EraseH; $y++) {
  for ($x = $EraseX; $x -lt $EraseX + $EraseW; $x++) {
    if ($x -ge 0 -and $y -ge 0 -and $x -lt $dst.Width -and $y -lt $dst.Height) {
      $dst.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0,0,0,0)) } } }

$bw = $BX2 - $BX1; $bh = $BY2 - $BY1
$scale = $BodyH / $bh
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TranslateTransform([single]$CX, [single]$CY)
if ($Rot -ne 0) { $g.RotateTransform([single]$Rot) }
$dw = [single]($bw * $scale); $dh = [single]($bh * $scale)
$dstRect = New-Object System.Drawing.RectangleF([single](-$dw/2), [single](-$dh/2), $dw, $dh)
$srcRect = New-Object System.Drawing.RectangleF([single]$BX1, [single]$BY1, [single]$bw, [single]$bh)
$g.DrawImage($dev, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

$dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"saved: $Out   body {0:N1}x{1:N1}px at {2}/{3}, rot {4}" -f $dw, $dh, $CX, $CY, $Rot
$dst.Dispose(); $src.Dispose(); $dev.Dispose()

