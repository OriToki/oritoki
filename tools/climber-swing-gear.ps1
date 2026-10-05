# Swings the flat figure's back-up gear (absorber + ASAP) toward him so the backup rope hangs plumb.
#
# The owner supplied the SAME drawing without that gear (Desktop\Perfect 2.png, pixel-identical
# elsewhere - diffed: only the gear differs). So the gear is lifted cleanly as "what differs", the
# absorber is turned about the point where it clips to his chest ring, and the ASAP is moved (not
# turned - it stays upright on its rope) so the rope point through its centre lands on the plumb
# line $TargetX. Output is a new source figure for tools/climber-assemble.ps1 -AllBaked.
param(
  [string]$WithGear = "C:\Users\gilmo\OneDrive\Desktop\perfect.png",
  [string]$NoGear   = "C:\Users\gilmo\OneDrive\Desktop\Perfect 2.png",
  [string]$Out,
  [double]$PivotX = 565, [double]$PivotY = 438,      # the absorber's clip on the chest ring
  [double]$RopeX = 737.5, [double]$RopeY = 191,      # the ASAP's centre, where the backup rope runs
  [double]$TargetX = 696.2,                          # the plumb backup rope, from the rope gap
  [int]$AsapFromX = 716                              # gear pixels right of this are the ASAP itself
)
Add-Type -AssemblyName System.Drawing
function L($p) { $b = New-Object System.Drawing.Bitmap $p
  $c = New-Object System.Drawing.Bitmap $b.Width, $b.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($c); $g.DrawImage($b, 0, 0, $b.Width, $b.Height); $g.Dispose(); $b.Dispose(); $c }
$a = L $WithGear; $n = L $NoGear; $W = $a.Width; $H = $a.Height
# the gear = where the two differ, grown by one pixel so its antialiased rim comes too
$diff = New-Object 'bool[,]' $W, $H
for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) {
  $p = $a.GetPixel($x, $y); $q = $n.GetPixel($x, $y)
  if ([Math]::Abs($p.A - $q.A) + [Math]::Abs($p.R - $q.R) + [Math]::Abs($p.G - $q.G) + [Math]::Abs($p.B - $q.B) -gt 25) { $diff[$x, $y] = $true } } }
$sorb = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$asap = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 1; $y -lt $H - 1; $y++) { for ($x = 1; $x -lt $W - 1; $x++) {
  if (-not ($diff[$x, $y] -or $diff[($x - 1), $y] -or $diff[($x + 1), $y] -or $diff[$x, ($y - 1)] -or $diff[$x, ($y + 1)])) { continue }
  $c = $a.GetPixel($x, $y); if ($c.A -eq 0) { continue }
  if ($x -ge $AsapFromX) { $asap.SetPixel($x, $y, $c) } else { $sorb.SetPixel($x, $y, $c) } } }
# solve: keep the pivot-to-rope distance, put the rope point on TargetX
$vx = $RopeX - $PivotX; $vy = $RopeY - $PivotY; $len = [Math]::Sqrt($vx * $vx + $vy * $vy)
$nx = $TargetX - $PivotX; $ny = -[Math]::Sqrt($len * $len - $nx * $nx)
$rot = ([Math]::Atan2($ny, $nx) - [Math]::Atan2($vy, $vx)) * 180 / [Math]::PI
$dx = $TargetX - $RopeX; $dy = ($PivotY + $ny) - $RopeY
"absorber turned {0:N1} deg about ({1},{2}); ASAP moved ({3:N1}, {4:N1}); rope now through ({5:N1}, {6:N1})" -f $rot, $PivotX, $PivotY, $dx, $dy, $TargetX, ($PivotY + $ny)
$o = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($o)
$g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.SmoothingMode = 'AntiAlias'
$g.DrawImage($n, 0, 0, $W, $H)
$g.TranslateTransform([single]$PivotX, [single]$PivotY); $g.RotateTransform([single]$rot); $g.TranslateTransform([single](-$PivotX), [single](-$PivotY))
$g.DrawImage($sorb, 0, 0, $W, $H); $g.ResetTransform()
$g.DrawImage($asap, [single]$dx, [single]$dy, [single]$W, [single]$H)
$g.Dispose(); $o.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$a.Dispose(); $n.Dispose(); $sorb.Dispose(); $asap.Dispose(); $o.Dispose()
$Out
