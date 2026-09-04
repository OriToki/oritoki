# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Layered preview in ART pixel space (560x686), mirroring what the page paints:
# back ropes -> climber.png -> front ropes, each front rope clipped along its device outline.
param(
  [double[]]$CutBrake = @(141, 340, 146, 351),   # x1,y1,x2,y2 in artwork pixels
  [double[]]$CutWork  = @(240.8, 229, 252, 219),
  [string]$Out = "C:\Users\gilmo\Downloads\rope-preview.png",
  [int]$CropX = 60, [int]$CropY = 300, [int]$CropW = 150, [int]$CropH = 130, [int]$Zoom = 6
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("$REPO\images\climber.png")
$AW = 560.0; $AH = 686.0
$buf = New-Object System.Drawing.Bitmap([int]$AW, [int]$AH)
$g = [System.Drawing.Graphics]::FromImage($buf)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(244,243,236))

$wOut = [single]($AW * 0.020); $wCore = [single]($wOut * 0.733)
function NewPen($col, $w) { $p = New-Object System.Drawing.Pen ($col), $w
  $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round; $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round; return $p }
$pOut  = NewPen ([System.Drawing.Color]::FromArgb(255,97,97,97))    $wOut
$pCore = NewPen ([System.Drawing.Color]::FromArgb(255,195,195,195)) $wCore
function Rope($x1,$y1,$x2,$y2) {
  $g.DrawLine($pOut,  [single]$x1, [single]$y1, [single]$x2, [single]$y2)
  $g.DrawLine($pCore, [single]$x1, [single]$y1, [single]$x2, [single]$y2)
}
# half-plane clip on the side of the line containing (kx,ky)
function SetCut($c, $kx, $ky) {
  $dx = $c[2] - $c[0]; $dy = $c[3] - $c[1]; $L = [math]::Sqrt($dx*$dx + $dy*$dy)
  $ux = $dx/$L; $uy = $dy/$L; $nx = -$uy; $ny = $ux
  if ((($kx - $c[0]) * $nx + ($ky - $c[1]) * $ny) -lt 0) { $nx = -$nx; $ny = -$ny }
  $E = 3000
  $a1x = $c[0] - $ux*$E; $a1y = $c[1] - $uy*$E; $a2x = $c[2] + $ux*$E; $a2y = $c[3] + $uy*$E
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddPolygon(@(
    (New-Object System.Drawing.PointF([single]$a1x, [single]$a1y)),
    (New-Object System.Drawing.PointF([single]$a2x, [single]$a2y)),
    (New-Object System.Drawing.PointF([single]($a2x + $nx*$E), [single]($a2y + $ny*$E))),
    (New-Object System.Drawing.PointF([single]($a1x + $nx*$E), [single]($a1y + $ny*$E)))))
  $g.SetClip($path); $path.Dispose()
}

# ---- BACK layer -----------------------------------------------------------
Rope (0.573*$AW) -40 (0.573*$AW) ($AH+40)                     # backup rope
Rope (0.165*$AW) (0.585*$AH) (0.165*$AW) ($AH+40)             # tail to the ground
Rope (0.44*$AW) ($CutWork[3]-8) (0.44*$AW) (0.40*$AH)         # hidden working-rope tip

# ---- the technician -------------------------------------------------------
$g.DrawImage($img, 0, 0, [int]$AW, [int]$AH)

# ---- FRONT layer, each rope cut along its device outline -------------------
SetCut $CutWork (0.44*$AW) -400
Rope (0.44*$AW) -40 (0.44*$AW) (0.36*$AH)                     # working rope
$g.ResetClip()

$ax = 0.47*$AW; $ay = 0.33*$AH; $bx = 0.226*$AW; $by = 0.528*$AH
$vx = $bx-$ax; $vy = $by-$ay; $len = [math]::Sqrt($vx*$vx+$vy*$vy)
SetCut $CutBrake $ax $ay
Rope ($ax + $vx/$len) ($ay + $vy/$len) $bx $by                # brake strand, into the fist
$g.ResetClip()
$g.Dispose()

# ---- crop + zoom ----------------------------------------------------------
$dst = New-Object System.Drawing.Bitmap(($CropW*$Zoom), ($CropH*$Zoom))
$go = [System.Drawing.Graphics]::FromImage($dst)
$go.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$go.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$go.DrawImage($buf, (New-Object System.Drawing.Rectangle(0, 0, ($CropW*$Zoom), ($CropH*$Zoom))),
                    (New-Object System.Drawing.Rectangle($CropX, $CropY, $CropW, $CropH)), [System.Drawing.GraphicsUnit]::Pixel)
$go.Dispose()
$dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose(); $buf.Dispose(); $img.Dispose()
"saved: $Out"

