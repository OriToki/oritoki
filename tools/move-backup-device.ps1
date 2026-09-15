# Swings the backup device across his chest, so that the backup rope can hang STRAIGHT DOWN from
# its anchor instead of leaning in to reach the device.
#
# Why it has to move at all: the logo fixes how far apart the two anchors are (the big O sits
# centred over the small o, which fixes the words, which fixes their anchors), and the anchors are
# the tops of the ropes. The working rope cannot give ground - it drops vertically into his fist -
# so the backup rope's top sits 6px from it, and the device it feeds was drawn 12.9px away. One of
# them had to move, and a rope that leans is the thing that reads as wrong.
#
# The device, its carabiner and the energy absorber all sit on TRANSPARENT background in
# climber.png - nothing of him is behind them - so they can be lifted out and put back somewhere
# else without repainting any of him. Below the absorber the sling crosses his sleeve, and that is
# left alone: the whole assembly is rotated about the point where the absorber meets the sling, so
# that end does not move and the sling still meets it.
param(
  [string]$Src = "c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images\climber.png",
  # The band holding device + carabiner + absorber. Checked edge by edge: nothing of him is in it.
  [int]$X0 = 244, [int]$Y0 = 50, [int]$X1 = 364, [int]$Y1 = 186,
  [double]$PivotX = 256, [double]$PivotY = 186,   # where the absorber meets the sling
  [double]$DevX = 321, [double]$DevY = 103,       # the rope's channel through the device (A.camX/camY)
  [double]$TargetX = 281                          # where the vertical rope will pass: 0.5018 x 560
)
Add-Type -AssemblyName System.Drawing
$img = New-Object System.Drawing.Bitmap($Src)
$W = $img.Width; $H = $img.Height

# how far to swing it: the angle that carries the device's channel to the rope's line
$vx = $DevX - $PivotX; $vy = $DevY - $PivotY
$len = [math]::Sqrt($vx*$vx + $vy*$vy)
$dx = $TargetX - $PivotX
if ([math]::Abs($dx) -gt $len) { throw "the device cannot reach x=$TargetX about that pivot" }
$dy = -[math]::Sqrt($len*$len - $dx*$dx)
$a0 = [math]::Atan2($vy, $vx); $a1 = [math]::Atan2($dy, $dx)
$deg = ($a1 - $a0) * 180 / [math]::PI
"swing {0:N2} deg about ({1},{2}); the channel goes ({3},{4}) -> ({5:N1},{6:N1})" -f $deg, $PivotX, $PivotY, $DevX, $DevY, ($PivotX+$dx), ($PivotY+$dy)

# lift the band out
$bw = $X1 - $X0; $bh = $Y1 - $Y0
$band = New-Object System.Drawing.Bitmap($bw, $bh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$bg = [System.Drawing.Graphics]::FromImage($band)
$bg.DrawImage($img, (New-Object System.Drawing.Rectangle 0,0,$bw,$bh), (New-Object System.Drawing.Rectangle $X0,$Y0,$bw,$bh), [System.Drawing.GraphicsUnit]::Pixel)
$bg.Dispose()

# clear where it was, then draw it back swung about the pivot
$out = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.DrawImage($img, 0, 0, $W, $H)
$clear = New-Object System.Drawing.Rectangle $X0,$Y0,$bw,$bh
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0,0,0,0))), $clear)
$g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TranslateTransform([single]$PivotX, [single]$PivotY)
$g.RotateTransform([single]$deg)
$g.TranslateTransform([single](-$PivotX), [single](-$PivotY))
$g.DrawImage($band, [single]$X0, [single]$Y0, [single]$bw, [single]$bh)
$g.ResetTransform(); $g.Dispose()
$img.Dispose(); $band.Dispose()
$out.Save($Src, [System.Drawing.Imaging.ImageFormat]::Png)
"  saved $Src   ({0}x{1})" -f $W, $H
"  index.html: A.camX = {0:N4}   A.camY = {1:N4}" -f (($PivotX+$dx)/$W), (($PivotY+$dy)/$H)
$out.Dispose()
