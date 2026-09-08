# Renders index.html in headless Chrome and zooms the rope strip, so a change to the braid can be
# judged at the size it is actually seen instead of guessed at.
param([int]$SrcY = 20, [int]$SrcW = 110, [int]$SrcH = 200, [int]$Zoom = 8,
      [string]$Out = "C:\Users\gilmo\Downloads\_rope-zoom.png")
$sc = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad"
# Two ways this lies about a change: Chrome caches the file:// page between runs (so use a fresh
# profile every time), and it finishes writing the screenshot AFTER the process exits (so delete
# the old one and wait for the new, or the previous render is measured instead).
if (Test-Path "$sc\page.png") { [System.IO.File]::Delete("$sc\page.png") }
$udd = Join-Path $sc ("cp" + (Get-Random))
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-sandbox `
  --user-data-dir="$udd" --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=5000 `
  --window-size=1200,900 --screenshot="$sc\page.png" `
  "file:///c:/Users/gilmo/OneDrive/Documents/GitHub/oritoki/index.html" | Out-Null
for ($i = 0; $i -lt 40; $i++) { if ((Test-Path "$sc\page.png") -and (Get-Item "$sc\page.png").Length -gt 10000) { break }; Start-Sleep -Milliseconds 400 }
Add-Type -AssemblyName System.Drawing
$s = New-Object System.Drawing.Bitmap("$sc\page.png")
$z = New-Object System.Drawing.Bitmap ($SrcW*$Zoom),($SrcH*$Zoom)
$gz = [System.Drawing.Graphics]::FromImage($z)
$gz.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$gz.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$gz.DrawImage($s, (New-Object System.Drawing.Rectangle 0,0,($SrcW*$Zoom),($SrcH*$Zoom)),
                  (New-Object System.Drawing.Rectangle 0,$SrcY,$SrcW,$SrcH), [System.Drawing.GraphicsUnit]::Pixel)
$gz.Dispose(); $z.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $z.Dispose()
# how much the rope actually swings between light and dark, down one column
$col = 0
for ($x = 0; $x -lt 110; $x++) { $c = $s.GetPixel($x, $SrcY + 150); if ((($c.R+$c.G+$c.B)/3) -gt 90) { $col = $x; break } }
$vals = @(); for ($y = $SrcY + 120; $y -lt $SrcY + 180; $y++) { $c = $s.GetPixel($col, $y); $vals += [int](($c.R+$c.G+$c.B)/3) }
"rope column $col : {0}..{1}  (contrast {2})" -f ($vals | Measure-Object -Minimum).Minimum, ($vals | Measure-Object -Maximum).Maximum, (($vals | Measure-Object -Maximum).Maximum - ($vals | Measure-Object -Minimum).Minimum)
$s.Dispose()
$Out
