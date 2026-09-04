# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Zoom on the brake hand with a grid in climber.png's OWN pixels (560x686), the strand drawn
# exactly as the page draws it, so the cut along the glove's outline can be specified in pixels.
param(
  [double]$Zoom = 6,
  [string]$Out  = "C:\Users\gilmo\Downloads\brake-hand-zoom.png"
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("$REPO\images\climber.png")
$AW = $img.Width; $AH = $img.Height        # 560 x 686

# crop window in ART pixels, around the brake fist
$x0 = 60; $x1 = 200; $y0 = 315; $y1 = 435
$cw = $x1 - $x0; $ch = $y1 - $y0
$PAD = 64
$bmp = New-Object System.Drawing.Bitmap(([int]($cw * $Zoom) + $PAD + 24), ([int]($ch * $Zoom) + $PAD + 24))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# --- draw the artwork + the strand into an art-sized buffer first, then blow it up ----------
$buf = New-Object System.Drawing.Bitmap($AW, $AH)
$bg  = [System.Drawing.Graphics]::FromImage($buf)
$bg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$bg.Clear([System.Drawing.Color]::FromArgb(244,243,236))
$bg.DrawImage($img, 0, 0, $AW, $AH)
# brake strand, in the FRONT layer, same proportions as the page (0.020 of the strip width)
$wOut  = [single]($AW * 0.020); $wCore = [single]($wOut * 0.733)
$pOut  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,97,97,97)), $wOut
$pCore = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,195,195,195)), $wCore
foreach ($p in @($pOut, $pCore)) { $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round; $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round }
# descOut 0.478/0.324 -> brakeIn 0.226/0.528, with the page's brakeTrim at both ends
$ax = 0.478 * $AW; $ay = 0.324 * $AH
$bx = 0.226 * $AW; $by = 0.528 * $AH
$vx = $bx - $ax; $vy = $by - $ay; $len = [math]::Sqrt($vx*$vx + $vy*$vy)
$ex = $bx - $vx * 0.04; $ey = $by - $vy * 0.04                      # brakeTrimBottom
$sx = $ax + ($vx / $len) * 1; $sy = $ay + ($vy / $len) * 1          # brakeTrimTop
$bg.DrawLine($pOut,  [single]$sx, [single]$sy, [single]$ex, [single]$ey)
$bg.DrawLine($pCore, [single]$sx, [single]$sy, [single]$ex, [single]$ey)
$bg.Dispose()

$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($buf, (New-Object System.Drawing.Rectangle($PAD, $PAD, [int]($cw * $Zoom), [int]($ch * $Zoom))),
                   (New-Object System.Drawing.Rectangle($x0, $y0, $cw, $ch)), [System.Drawing.GraphicsUnit]::Pixel)

# --- pixel grid ----------------------------------------------------------------------------
$penFine = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(60,255,0,0)), 1
$penMaj  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200,210,0,0)), 2
$f       = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$brT     = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190,0,0))

for ($x = $x0; $x -le $x1; $x += 5) {
  $sxp = $PAD + (($x - $x0) * $Zoom)
  if ($x % 20 -eq 0) { $pen = $penMaj } else { $pen = $penFine }
  $g.DrawLine($pen, [single]$sxp, [single]$PAD, [single]$sxp, [single]($PAD + $ch * $Zoom))
  if ($x % 20 -eq 0) {
    $t = "$x"; $sz = $g.MeasureString($t, $f)
    $g.DrawString($t, $f, $brT, [single]($sxp - $sz.Width / 2), [single]($PAD - 22))
  }
}
for ($y = $y0; $y -le $y1; $y += 5) {
  $syp = $PAD + (($y - $y0) * $Zoom)
  if ($y % 20 -eq 0) { $pen = $penMaj } else { $pen = $penFine }
  $g.DrawLine($pen, [single]$PAD, [single]$syp, [single]($PAD + $cw * $Zoom), [single]$syp)
  if ($y % 20 -eq 0) {
    $t = "$y"; $sz = $g.MeasureString($t, $f)
    $g.DrawString($t, $f, $brT, [single]($PAD - $sz.Width - 6), [single]($syp - 10))
  }
}
$g.DrawString("climber.png pixels (560 x 686): X across, Y down", $f, $brT, [single]$PAD, [single]($PAD + $ch * $Zoom + 6))
$g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $buf.Dispose(); $img.Dispose()
"saved: $Out"

