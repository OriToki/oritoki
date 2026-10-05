# A marking sheet of the climber AS THE PAGE STACKS HIM: man-body, then man-rig, then man-glove,
# with the back-up rope behind them on its plumb line. A numbered grid in the shipped layers' own
# pixels (760 x 852) goes over it, so a point the owner marks can be read back exactly.
# Cyan dots: where the back-up rope pivots now (A.asapIn / A.asapOut).
param(
  [double]$RopeFrac = 0.5486,                 # A.asapIn.x - the back-up rope's line
  [double]$InY = 0.0471, [double]$OutY = 0.1292,   # A.asapIn.y / A.asapOut.y
  [int]$Zoom = 1, [int]$X0 = 0, [int]$Y0 = 0, [int]$W = 760, [int]$H = 852,
  [int]$Step = 20, [int]$Label = 100,
  [string]$Out = "C:\Users\gilmo\Downloads\climber-sheet.png"
)
Add-Type -AssemblyName System.Drawing
$IMG = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path "images"
$body = New-Object System.Drawing.Bitmap "$IMG\man-body.png"; $SW = $body.Width; $SH = $body.Height
$st = New-Object System.Drawing.Bitmap $SW, $SH
$g = [System.Drawing.Graphics]::FromImage($st); $g.Clear([System.Drawing.Color]::FromArgb(255, 20, 24, 38))
$g.SmoothingMode = 'AntiAlias'
$rx = $RopeFrac * $SW
$g.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 6), [single]$rx, 0, [single]$rx, [single]$SH)
$g.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 213, 214, 216)), 4), [single]$rx, 0, [single]$rx, [single]$SH)
$g.DrawImage($body, 0, 0, $SW, $SH)
foreach ($n in "man-rig.png", "man-glove.png") { $b = New-Object System.Drawing.Bitmap "$IMG\$n"; $g.DrawImage($b, 0, 0, $SW, $SH); $b.Dispose() }
$cy = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 230, 255))
foreach ($fy in $InY, $OutY) { $g.FillEllipse($cy, [single]($rx - 2.5), [single]($fy * $SH - 2.5), 5, 5) }
$g.Dispose(); $body.Dispose()

$mrg = 46
$o = New-Object System.Drawing.Bitmap ($W * $Zoom + $mrg), ($H * $Zoom + $mrg)
$g = [System.Drawing.Graphics]::FromImage($o); $g.Clear([System.Drawing.Color]::FromArgb(255, 60, 60, 70))
$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
$g.DrawImage($st, (New-Object System.Drawing.Rectangle $mrg, $mrg, ($W * $Zoom), ($H * $Zoom)), (New-Object System.Drawing.Rectangle $X0, $Y0, $W, $H), [System.Drawing.GraphicsUnit]::Pixel)
$thin = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 255, 0, 255)), 1
$fat = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(170, 255, 0, 255)), 1
$f = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 230, 0))
for ($x = [Math]::Ceiling($X0 / $Step) * $Step; $x -le $X0 + $W; $x += $Step) { $px = $mrg + ($x - $X0) * $Zoom
  $g.DrawLine($(if ($x % $Label -eq 0) { $fat } else { $thin }), $px, $mrg, $px, $o.Height)
  if ($x % $Label -eq 0) { $g.DrawString("$x", $f, $ink, [single]($px - 12), [single]4) } }
for ($y = [Math]::Ceiling($Y0 / $Step) * $Step; $y -le $Y0 + $H; $y += $Step) { $py = $mrg + ($y - $Y0) * $Zoom
  $g.DrawLine($(if ($y % $Label -eq 0) { $fat } else { $thin }), $mrg, $py, $o.Width, $py)
  if ($y % $Label -eq 0) { $g.DrawString("$y", $f, $ink, [single]2, [single]($py - 7)) } }
$g.Dispose(); $o.Save($Out); $o.Dispose(); $st.Dispose()
"$Out   (grid every $Step px, numbered every $Label, in the shipped layers' 760 x 852 pixels)"
