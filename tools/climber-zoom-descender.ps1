# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Big zoom on the descender with fine gridlines, to pick the exact y where the device's
# black outline crosses the rope column (x = 0.44).
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("$REPO\images\climber.png")
$x0 = 0.36; $x1 = 0.56; $y0 = 0.27; $y1 = 0.41
$z = 8
$sx = [int]($x0 * $img.Width); $sw = [int](($x1 - $x0) * $img.Width)
$sy = [int]($y0 * $img.Height); $sh = [int](($y1 - $y0) * $img.Height)
$PAD = 60
$bmp = New-Object System.Drawing.Bitmap((($sw * $z) + $PAD + 20), (($sh * $z) + $PAD + 20))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($img, (New-Object System.Drawing.Rectangle($PAD, $PAD, ($sw * $z), ($sh * $z))),
                   (New-Object System.Drawing.Rectangle($sx, $sy, $sw, $sh)), [System.Drawing.GraphicsUnit]::Pixel)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

$penT = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120,255,0,0)), 1
$penL = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220,200,0,0)), 2
$f    = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$br   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180,0,0))

# horizontal lines every 0.005 of the figure height, labelled
for ($v = 0.27; $v -le 0.4101; $v += 0.005) {
  $py = $PAD + ((($v * $img.Height) - $sy) * $z)
  if ([math]::Abs(($v * 200) - [math]::Round($v * 200)) -lt 0.001 -and ([int][math]::Round($v * 1000)) % 10 -eq 0) { $pen = $penL } else { $pen = $penT }
  $g.DrawLine($pen, [single]$PAD, [single]$py, [single]($PAD + $sw * $z), [single]$py)
  $g.DrawString($v.ToString("0.000"), $f, $br, [single]2, [single]($py - 10))
}
# the rope column
$penRope = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200,0,90,255)), 3
$rx = $PAD + (((0.44 * $img.Width) - $sx) * $z)
$g.DrawLine($penRope, [single]$rx, [single]$PAD, [single]$rx, [single]($PAD + $sh * $z))
$g.DrawString("x = 0.44", $f, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0,90,255))), [single]($rx - 30), [single]8)

$g.Dispose()
$bmp.Save("C:\Users\gilmo\Downloads\descender-zoom.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $img.Dispose()
"saved"

