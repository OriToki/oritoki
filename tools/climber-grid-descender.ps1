# A measuring grid over the DESCENDER, for marking a point on and handing back.
#
# climber-zoom-descender.ps1 rules the horizontal axis only, because it was made to pick one y -
# where the device's outline crosses the rope column. This one rules BOTH axes and labels them,
# so any point on the device can be read off and quoted straight back as a fraction.
#
# Units are the SAME fractions the rope code uses: a share of the figure box, never of this crop.
# That is the whole point of the grid - a number read here can be pasted into A.desc, A.descOut
# and so on without converting anything.
#
# PowerShell variable names are case-insensitive: param names and locals must not collide.
param(
  [double]$X0 = 0.30, [double]$X1 = 0.60,   # the crop, in figure fractions
  [double]$Y0 = 0.24, [double]$Y1 = 0.46,
  [double]$Step = 0.005,                    # fine line every this much
  [int]$Zoom = 9,
  [string]$OutPath = "C:\Users\gilmo\Downloads\descender-grid.png"
)
Add-Type -AssemblyName System.Drawing
# Repo root, resolved from this script's location so the tool works from any checkout.
# (param() has to be the first statement in the file, so this cannot go above it.)
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$art = [System.Drawing.Image]::FromFile("$REPO\images\climber.png")
$sx = [int]($X0 * $art.Width);  $sw = [int](($X1 - $X0) * $art.Width)
$sy = [int]($Y0 * $art.Height); $sh = [int](($Y1 - $Y0) * $art.Height)
$padL = 86; $padT = 56; $padR = 28; $padB = 30
$plotW = $sw * $Zoom; $plotH = $sh * $Zoom

$bmp = New-Object System.Drawing.Bitmap(($padL + $plotW + $padR), ($padT + $plotH + $padB))
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.Clear([System.Drawing.Color]::White)
# NearestNeighbor on purpose: the point of the grid is to see which PIXEL an outline sits on,
# and a smoothing filter invents edges between them.
$gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$gfx.DrawImage($art, (New-Object System.Drawing.Rectangle($padL, $padT, $plotW, $plotH)),
                     (New-Object System.Drawing.Rectangle($sx, $sy, $sw, $sh)), [System.Drawing.GraphicsUnit]::Pixel)
$gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$penFine = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 210, 40, 40)), 1
$penMaj  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(205, 190, 0, 0)), 2
$fontS = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fontB = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$brRed = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(170, 0, 0))

function FxToPx([double]$fx) { return $padL + (($fx * $art.Width) - $sx) * $Zoom }
function FyToPy([double]$fy) { return $padT + (($fy * $art.Height) - $sy) * $Zoom }

# vertical lines - X as a fraction of the figure's WIDTH
for ($v = $X0; $v -le ($X1 + 1e-9); $v += $Step) {
  $px = FxToPx $v
  $major = ([int][Math]::Round($v * 1000)) % 20 -eq 0
  $gfx.DrawLine($(if ($major) { $penMaj } else { $penFine }), [single]$px, [single]$padT, [single]$px, [single]($padT + $plotH))
  if ($major) {
    $lbl = $v.ToString("0.000")
    $sz = $gfx.MeasureString($lbl, $fontB)
    $gfx.DrawString($lbl, $fontB, $brRed, [single]($px - $sz.Width / 2), [single]($padT - 22))
  }
}
# horizontal lines - Y as a fraction of the figure's HEIGHT
for ($v = $Y0; $v -le ($Y1 + 1e-9); $v += $Step) {
  $py = FyToPy $v
  $major = ([int][Math]::Round($v * 1000)) % 20 -eq 0
  $gfx.DrawLine($(if ($major) { $penMaj } else { $penFine }), [single]$padL, [single]$py, [single]($padL + $plotW), [single]$py)
  if ($major) { $gfx.DrawString($v.ToString("0.000"), $fontB, $brRed, [single]4, [single]($py - 10)) }
}

# Where the rope code currently attaches, so a mark can be given as "move this one to here"
# rather than as a bare coordinate.
$marks = @(
  @(0.44,  0.3265, "desc",     0,   0, 200),
  @(0.47,  0.33,   "descOut",  0, 150, 90),
  @(0.5018, 0.1218, "cam",   150,  80, 0)
)
foreach ($m in $marks) {
  $px = FxToPx $m[0]; $py = FyToPy $m[1]
  if ($px -lt $padL -or $px -gt ($padL + $plotW) -or $py -lt $padT -or $py -gt ($padT + $plotH)) { continue }
  $col = [System.Drawing.Color]::FromArgb(235, $m[3], $m[4], $m[5])
  $pen = New-Object System.Drawing.Pen $col, 2
  $br = New-Object System.Drawing.SolidBrush $col
  $gfx.DrawEllipse($pen, [single]($px - 9), [single]($py - 9), [single]18, [single]18)
  $gfx.DrawLine($pen, [single]($px - 15), [single]$py, [single]($px + 15), [single]$py)
  $gfx.DrawLine($pen, [single]$px, [single]($py - 15), [single]$px, [single]($py + 15))
  $gfx.DrawString(("{0}  {1:N3}, {2:N3}" -f $m[2], $m[0], $m[1]), $fontS, $br, [single]($px + 18), [single]($py - 8))
  $pen.Dispose(); $br.Dispose()
}

$gfx.DrawString("climber.png  -  grid is a fraction of the FIGURE box, fine line every $Step",
                $fontS, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 90, 90))),
                [single]$padL, [single]($padT + $plotH + 6))
$gfx.Dispose()
$bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
"saved $OutPath   ($($bmp.Width) x $($bmp.Height))   crop x $X0..$X1  y $Y0..$Y1  at ${Zoom}x"
$bmp.Dispose(); $art.Dispose()
