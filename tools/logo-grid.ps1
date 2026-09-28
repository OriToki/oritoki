# The mark with its carabiners turned, under a numbered grid, so a fault that only shows once the
# technician is dragged can be pointed at by its coordinates.
#
# The numbers are the MARK's own pixels - the 400-wide box the three layers share - so anything
# marked on this grid can be found directly in images/logo-*.png and in tools/logo-layers.ps1.
# It is drawn from the layers rather than from a screenshot of the page because the page will not
# hold a drag still for a headless render.
param([switch]$Light, [double]$Deg = 45, [int]$Zoom = 3, [int]$Step = 10, [int]$Label = 40,
      [string]$Out = "C:\Users\gilmo\Downloads\logo-grid.png",
      [string]$Dir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
      # the two hinges, as fractions of the mark - keep in step with A.pivotWork / A.pivotBack
      [double]$WorkPX = 0.7375, [double]$WorkPY = 0.1266,
      [double]$BackPX = 0.8804, [double]$BackPY = 0.5356)
Add-Type -AssemblyName System.Drawing
function Open($path) {
  $fs = [System.IO.File]::OpenRead($path)
  $im = [System.Drawing.Image]::FromStream($fs)
  $bm = New-Object System.Drawing.Bitmap($im)
  $im.Dispose(); $fs.Close(); $fs.Dispose(); return $bm
}
$work = Open (Join-Path $Dir "logo-work.png")
$back = Open (Join-Path $Dir "logo-back.png")
$rest = Open (Join-Path $Dir "logo-rest.png")
$plate = Open (Join-Path $Dir "logo-plate.png")
$barlow = Open (Join-Path $Dir "logo-barlow.png")
$W = $rest.Width; $H = $rest.Height

$lay = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gl = [System.Drawing.Graphics]::FromImage($lay)
$gl.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
# the page's order: plate under everything, then the BACKUP carabiner, then the WORKING one - the
# main rope runs past the lower anchor on its way down, so it is in front of it - then the
# lettering and the hangers' bars on top.
$gl.DrawImage($plate, 0, 0, $W, $H)
foreach ($job in @(@($back, $BackPX, $BackPY), @("bar", 0, 0), @($work, $WorkPX, $WorkPY))) {
  if ($job[0] -eq "bar") { $gl.ResetTransform(); $gl.DrawImage($barlow, 0, 0, $W, $H); continue }
  $gl.ResetTransform()
  $gl.TranslateTransform([single]($job[1] * $W), [single]($job[2] * $H))
  $gl.RotateTransform([single]$Deg)
  $gl.TranslateTransform([single](-$job[1] * $W), [single](-$job[2] * $H))
  $gl.DrawImage($job[0], 0, 0, $W, $H)
}
$gl.ResetTransform()
$gl.DrawImage($rest, 0, 0, $W, $H)
$gl.Dispose()

$mrg = 46
# NOTE: not $out - that is the PATH parameter, and PowerShell would treat them as one variable.
$canvas = New-Object System.Drawing.Bitmap (($W * $Zoom) + $mrg), (($H * $Zoom) + $mrg), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(255, 24, 24, 28))
# the page's own background behind the mark, so the drawing reads the way it does on the site
# The page has two themes and a black speck is all but invisible on the dark one - which is how a
# couple of them survived three rounds of "gone". Check on the LIGHT background; that is where the
# owner looks.
$bg = $(if ($Light) { [System.Drawing.Color]::FromArgb(255, 234, 234, 226) } else { [System.Drawing.Color]::FromArgb(255, 15, 20, 40) })
$g.FillRectangle((New-Object System.Drawing.SolidBrush $bg),
                 $mrg, $mrg, ($W * $Zoom), ($H * $Zoom))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($lay, (New-Object System.Drawing.Rectangle $mrg, $mrg, ($W * $Zoom), ($H * $Zoom)))

$thin = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(60, 255, 0, 255)), 1
$fat = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150, 255, 0, 255)), 1
$f = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
$ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 80, 255))
for ($x = 0; $x -le $W; $x += $Step) {
  $px = $mrg + $x * $Zoom
  $g.DrawLine($(if ($x % $Label -eq 0) { $fat } else { $thin }), $px, $mrg, $px, $canvas.Height)
  if ($x % $Label -eq 0) { $g.DrawString(("{0:000}" -f $x), $f, $ink, [single]($px - 15), [single]6) }
}
for ($y = 0; $y -le $H; $y += $Step) {
  $py = $mrg + $y * $Zoom
  $g.DrawLine($(if ($y % $Label -eq 0) { $fat } else { $thin }), $mrg, $py, $canvas.Width, $py)
  if ($y % $Label -eq 0) { $g.DrawString(("{0:000}" -f $y), $f, $ink, [single]2, [single]($py - 8)) }
}
# the two hinges, so it is obvious what each carabiner is turning about
$dot = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 255, 120))
foreach ($p in @(@($WorkPX, $WorkPY), @($BackPX, $BackPY))) {
  $g.FillEllipse($dot, ($mrg + $p[0] * $W * $Zoom - 4), ($mrg + $p[1] * $H * $Zoom - 4), 9, 9)
}
$g.Dispose()
$canvas.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $lay.Dispose(); $work.Dispose(); $back.Dispose(); $rest.Dispose(); $plate.Dispose(); $barlow.Dispose()
"$Out   carabiners turned $Deg deg; grid step $Step, numbers every $Label, in the mark's own $W x $H pixels"
