# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Renders the rope tip at several cut heights and lays them out side by side, zoomed, so the
# exact relationship between the rope's end and the descender's black outline is visible.
Add-Type -AssemblyName System.Drawing
$dir = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad"
$variants = @(0.34, 0.345, 0.352)
$labels   = @("A  0.340  (now)", "B  0.345  (at the outline)", "C  0.352  (into the outline)")

$crops = @()
foreach ($v in $variants) {
  $f = "$dir\cmp-$($v.ToString('0.000')).png"
  & "$dir\make-preview.ps1" -FrontEndY $v -BackEndY 0.40 -Out $f | Out-Null
  $crops += $f
}

# crop window on the 1120x1372 art (40px pad), around the descender
$cx = [int](40 + 0.38 * 1120); $cw = [int](0.16 * 1120)
$cy = [int](40 + 0.27 * 1372); $ch = [int](0.12 * 1372)
$z = 3
$cellW = $cw * $z; $cellH = $ch * $z
$GAP = 20; $TOP = 44
$bmp = New-Object System.Drawing.Bitmap((($cellW * 3) + ($GAP * 4)), ($cellH + $TOP + $GAP))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$f = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(20,20,20))
$penBox = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180,180,180)), 1

for ($i = 0; $i -lt 3; $i++) {
  $src = [System.Drawing.Image]::FromFile($crops[$i])
  $dx = $GAP + $i * ($cellW + $GAP)
  $g.DrawImage($src, (New-Object System.Drawing.Rectangle($dx, $TOP, $cellW, $cellH)),
                     (New-Object System.Drawing.Rectangle($cx, $cy, $cw, $ch)), [System.Drawing.GraphicsUnit]::Pixel)
  $g.DrawRectangle($penBox, $dx, $TOP, $cellW, $cellH)
  $g.DrawString($labels[$i], $f, $br, [single]$dx, [single]12)
  $src.Dispose()
}
$g.Dispose()
$bmp.Save("C:\Users\gilmo\Downloads\rope-tip-compare.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"saved: C:\Users\gilmo\Downloads\rope-tip-compare.png"

