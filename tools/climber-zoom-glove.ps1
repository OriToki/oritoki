# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Very close zoom on where the brake strand meets the fist, with the strand's own edges drawn
# as guide lines, so the glove's outline can be read off in climber.png pixels.
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("$REPO\images\climber.png")
$AW = 560.0; $AH = 686.0
$x0 = 105; $y0 = 330; $cw = 65; $ch = 55; $Z = 12; $PAD = 60
$bmp = New-Object System.Drawing.Bitmap(($cw*$Z + $PAD + 24), ($ch*$Z + $PAD + 30))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($img, (New-Object System.Drawing.Rectangle($PAD, $PAD, ($cw*$Z), ($ch*$Z))),
                   (New-Object System.Drawing.Rectangle($x0, $y0, $cw, $ch)), [System.Drawing.GraphicsUnit]::Pixel)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
function SX($x) { return [single]($PAD + ($x - $x0) * $Z) }
function SY($y) { return [single]($PAD + ($y - $y0) * $Z) }

# grid
$fine = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(55,255,0,0)), 1
$maj  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(190,210,0,0)), 2
$f    = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$brT  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190,0,0))
for ($x = $x0; $x -le $x0+$cw; $x++) { if ($x % 5 -ne 0) { continue }
  if ($x % 10 -eq 0) { $p = $maj } else { $p = $fine }
  $g.DrawLine($p, (SX $x), (SY $y0), (SX $x), (SY ($y0+$ch)))
  if ($x % 10 -eq 0) { $t="$x"; $sz=$g.MeasureString($t,$f); $g.DrawString($t,$f,$brT,[single]((SX $x)-$sz.Width/2),[single]($PAD-24)) } }
for ($y = $y0; $y -le $y0+$ch; $y++) { if ($y % 5 -ne 0) { continue }
  if ($y % 10 -eq 0) { $p = $maj } else { $p = $fine }
  $g.DrawLine($p, (SX $x0), (SY $y), (SX ($x0+$cw)), (SY $y))
  if ($y % 10 -eq 0) { $t="$y"; $sz=$g.MeasureString($t,$f); $g.DrawString($t,$f,$brT,[single]($PAD-$sz.Width-6),[single]((SY $y)-10)) } }

# the strand: axis + both edges
$ax = 0.478*$AW; $ay = 0.324*$AH; $bx = 0.226*$AW; $by = 0.528*$AH
$vx = $bx-$ax; $vy = $by-$ay; $L = [math]::Sqrt($vx*$vx+$vy*$vy); $ux = $vx/$L; $uy = $vy/$L
$px = -$uy; $py = $ux; $half = 0.010*$AW
$penAxis = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200,0,110,255)), 2
$penEdge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200,0,170,90)), 2
foreach ($off in -1, 0, 1) {
  $sx1 = $ax + $ux*140 + $px*$half*$off; $sy1 = $ay + $uy*140 + $py*$half*$off
  $sx2 = $ax + $ux*230 + $px*$half*$off; $sy2 = $ay + $uy*230 + $py*$half*$off
  if ($off -eq 0) { $pen = $penAxis } else { $pen = $penEdge }
  $g.DrawLine($pen, (SX $sx1), (SY $sy1), (SX $sx2), (SY $sy2))
}
$g.DrawString("blue = strand centre, green = its two edges; numbers are climber.png pixels", $f, $brT, [single]$PAD, [single]($PAD + $ch*$Z + 6))
$g.Dispose()
$bmp.Save("C:\Users\gilmo\Downloads\glove-zoom.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $img.Dispose()
"saved"

