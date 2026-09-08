# Renders the top of the climber strip at 4x device pixels - the size the owner has been looking
# at it - and lays a numbered grid over it, so a detail can be pointed at by its coordinates
# instead of described. Same idea as tools/climber-grid.ps1, but over the LIVE page rather than
# the artwork, because what is being judged here is what the browser draws.
param([int]$DSF = 4,
      [int]$CropX = 0, [int]$CropY = 0, [int]$CropW = 520, [int]$CropH = 640,
      [int]$Zoom = 2, [int]$Step = 20, [int]$Label = 40,
      [string]$Out = "C:\Users\gilmo\Downloads\anchor-grid.png")
$sc = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad"
$shot = "$sc\hi$DSF.png"
if (Test-Path $shot) { [System.IO.File]::Delete($shot) }
$udd = Join-Path $sc ("cp" + (Get-Random))
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-sandbox `
  --user-data-dir="$udd" --hide-scrollbars --force-device-scale-factor=$DSF --virtual-time-budget=5000 `
  --window-size=1200,900 --screenshot="$shot" `
  "file:///c:/Users/gilmo/OneDrive/Documents/GitHub/oritoki/index.html" | Out-Null
for ($i = 0; $i -lt 60; $i++) { if ((Test-Path $shot) -and (Get-Item $shot).Length -gt 10000) { break }; Start-Sleep -Milliseconds 400 }

Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap($shot)
$mrg = 46                                    # room for the rulers
$W = $CropW * $Zoom + $mrg; $H = $CropH * $Zoom + $mrg
$canvas = New-Object System.Drawing.Bitmap $W,$H,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(255,24,24,28))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($src, (New-Object System.Drawing.Rectangle $mrg,$mrg,($CropW*$Zoom),($CropH*$Zoom)),
                   (New-Object System.Drawing.Rectangle $CropX,$CropY,$CropW,$CropH), [System.Drawing.GraphicsUnit]::Pixel)
$src.Dispose()

$thin = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70,255,0,255)),1
$fat  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(170,255,0,255)),1
$f = New-Object System.Drawing.Font("Consolas",11,[System.Drawing.FontStyle]::Bold)
$ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,80,255))
for ($x = 0; $x -le $CropW; $x += $Step) {
  $px = $mrg + $x * $Zoom
  $g.DrawLine($(if ($x % $Label -eq 0) { $fat } else { $thin }), $px, $mrg, $px, $H)
  # numbers are absolute in the render, not relative to the crop, so they mean the same thing
  # whichever part of the strip is cut out next time
  if ($x % $Label -eq 0) { $g.DrawString(("{0:000}" -f ($CropX + $x)), $f, $ink, [single]($px - 15), [single]6) } }
for ($y = 0; $y -le $CropH; $y += $Step) {
  $py = $mrg + $y * $Zoom
  $g.DrawLine($(if ($y % $Label -eq 0) { $fat } else { $thin }), $mrg, $py, $W, $py)
  if ($y % $Label -eq 0) { $g.DrawString(("{0:000}" -f ($CropY + $y)), $f, $ink, [single]2, [single]($py - 8)) } }
$g.Dispose()
$canvas.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $canvas.Dispose()
"$Out   grid step $Step, numbers every $Label (both in ${DSF}x device pixels)"
