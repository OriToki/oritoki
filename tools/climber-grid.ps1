# A measuring grid over the technician AS THE PAGE PAINTS HIM - back ropes, man-body, front
# ropes, man-front - on WHITE, so the owner can mark exactly where a rope should enter or leave
# him. White because that is the light theme, and a black fault is invisible on the dark one.
#
# The grid is in the SHIPPED layers' own pixels (760 x 856, tools/climber-compose.ps1's output),
# which is the unit every A.* point in index.html is written in. Quote marks in these numbers
# and they go straight into the table; quote fractions and it is anyone's guess which black line
# was meant.
#
# The current attachment points are drawn on as rings, so there is something to correct rather
# than something to invent.
#
# ONE THING TO KNOW BEFORE MOVING A ROPE SIDEWAYS: the two ropes are LOCKED together. They hang
# from the two stems of the header mark, 0.17278 * markW of the strip apart - 72.6 px on this
# frame - so moving one across moves the other by the same amount. Only their HEIGHTS are free.
# What CAN move independently is the ASAP: it is a separate drawing, placed on the rope by
# climber-compose.ps1, so say where the rope should be and the device follows.
param(
  [string]$Out = "C:\Users\gilmo\Downloads\climber-grid.png",
  [int]$Zoom = 2,
  [int]$Fine = 10, [int]$Mid = 50, [int]$Bold = 100,
  # The points as index.html has them, in shipped pixels. Keep in step with A.* there.
  [double]$WorkX = 354.7, [double]$DescY = 305,
  # The brake strand is a traced line, not a straight one - see A.brakePath in index.html.
  [double[]]$BrakePath = @(366.7,277.8, 367.0,297.0, 351.5,309.7, 159.4,467.5),
  [double]$InX  = 159.4,  [double]$InY  = 467.5,
  [double]$BrkX = 125.5,  [double]$BrkY = 492.5,
  # The ASAP is where the owner's red dot put it - its top hole at shipped (421.6, 61.3). The
  # device runs shipped y 47.8..104.6; these two are a few px inside it. Keep in step with
  # A.asapIn / A.asapOut in index.html.
  [double]$BackX = 427.3, [double]$AsapInY = 51, [double]$AsapOutY = 101,
  [double]$RopeW = 8.26,  # = A.ropeW (0.01087 of the strip) x 760
  # Just the figure under the grid: no rings, no labels, no caption. For marking on a clean
  # sheet, or for looking at the drawing itself without six magenta circles over it.
  [switch]$Bare
)
Add-Type -AssemblyName System.Drawing
$R = (Resolve-Path (Join-Path $PSScriptRoot "..\images")).Path
$W = 760; $H = 856
$TOP = -140; $BOT = 990          # a little rope above and below him
$PAD = 56                        # room for the numbers
$CAP = if ($Bare) { 10 } else { 74 }   # ...and for the caption, when there is one

# --- the figure, painted in the page's own order --------------------------------------------
$fig = New-Object System.Drawing.Bitmap $W, ($BOT - $TOP), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($fig)
$g.Clear([System.Drawing.Color]::White)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TranslateTransform(0, [single](-$TOP))
$pOut = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), ([single]$RopeW)
$pIn  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 213, 214, 216)), ([single]($RopeW * 0.63))
foreach ($pen in @($pOut, $pIn)) {
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
}
function Rope($pts) {
  $a = @(); foreach ($q in $pts) { $a += New-Object System.Drawing.PointF ([single]$q[0]), ([single]$q[1]) }
  $g.DrawLines($pOut, [System.Drawing.PointF[]]$a)
  $g.DrawLines($pIn,  [System.Drawing.PointF[]]$a)
}
# The brake strand: M p0 Q p1 p2 L p3, the same four points index.html holds in A.brakePath.
# GDI+ has no quadratic, so it is raised to the equivalent cubic - C1 = p0 + 2/3 (q - p0),
# C2 = p2 + 2/3 (q - p2).
function RopeCurve($f) {
  $p0 = New-Object System.Drawing.PointF ([single]$f[0]), ([single]$f[1])
  $qx = [double]$f[2]; $qy = [double]$f[3]
  $p2 = New-Object System.Drawing.PointF ([single]$f[4]), ([single]$f[5])
  $p3 = New-Object System.Drawing.PointF ([single]$f[6]), ([single]$f[7])
  $c1 = New-Object System.Drawing.PointF ([single]($f[0] + 2.0 / 3 * ($qx - $f[0]))), ([single]($f[1] + 2.0 / 3 * ($qy - $f[1])))
  $c2 = New-Object System.Drawing.PointF ([single]($f[4] + 2.0 / 3 * ($qx - $f[4]))), ([single]($f[5] + 2.0 / 3 * ($qy - $f[5])))
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddBezier($p0, $c1, $c2, $p2)
  $path.AddLine($p2, $p3)
  $g.DrawPath($pOut, $path); $g.DrawPath($pIn, $path)
  $path.Dispose()
}
function Layer($n) {
  $p = Join-Path $R $n
  if (-not (Test-Path $p)) { throw "missing $p - run tools/climber-compose.ps1 first" }
  $b = New-Object System.Drawing.Bitmap($p); $g.DrawImageUnscaled($b, 0, 0); $b.Dispose()
}
# BACK: the backup rope for its whole length - the ASAP is drawn with a hole, so the device
# hides the rope and the hole shows it through - and the brake tail below the glove.
Rope @(@($BackX, $TOP), @($BackX, $AsapInY), @($BackX, $AsapOutY), @($BackX, $BOT))
Rope @(@($BrkX, $BrkY), @($BrkX, $BOT))
Layer "man-body.png"
# The working rope: in front of everything of his it meets, under the descender only.
Rope @(@($WorkX, $TOP), @($WorkX, $DescY))
Layer "man-rig.png"
# The brake strand: OVER the descender's face, hooking left, then straight to the hand...
RopeCurve $BrakePath
# ...and the glove over it.
Layer "man-glove.png"
$g.Dispose()

# --- the sheet: figure, grid, numbers ---------------------------------------------------------
$SW = $W * $Zoom + $PAD * 2
$SH = ($BOT - $TOP) * $Zoom + $PAD * 2 + $CAP
$o = New-Object System.Drawing.Bitmap $SW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$go = [System.Drawing.Graphics]::FromImage($o)
$go.Clear([System.Drawing.Color]::White)
$go.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$go.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$go.DrawImage($fig, $PAD, $PAD, ($W * $Zoom), (($BOT - $TOP) * $Zoom))
$fig.Dispose()

function SX($ax) { return $PAD + $ax * $Zoom }
function SY($ay) { return $PAD + ($ay - $TOP) * $Zoom }

$pFine = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(38, 0, 130, 255)), 1
$pMid  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(85, 0, 110, 230)), 1
$pBold = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150, 220, 0, 0)), 1
$f  = New-Object System.Drawing.Font "Consolas", ([single]12), ([System.Drawing.FontStyle]::Bold)
$fs = New-Object System.Drawing.Font "Consolas", ([single]13), ([System.Drawing.FontStyle]::Bold)
$brRed = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 190, 0, 0))
$brBlk = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 20, 20, 20))

$y0 = SY $TOP; $y1 = SY $BOT
for ($x = 0; $x -le $W; $x += $Fine) {
  $sx = SX $x
  $pen = if ($x % $Bold -eq 0) { $pBold } elseif ($x % $Mid -eq 0) { $pMid } else { $pFine }
  $go.DrawLine($pen, [single]$sx, [single]$y0, [single]$sx, [single]$y1)
  if ($x % $Bold -eq 0) {
    $go.DrawString("$x", $f, $brRed, [single]($sx - 13), [single]($PAD - 20))
    $go.DrawString("$x", $f, $brRed, [single]($sx - 13), [single]($y1 + 4))
  }
}
$x0 = SX 0; $x1 = SX $W
for ($y = $TOP; $y -le $BOT; $y += $Fine) {
  $sy = SY $y
  $pen = if ($y % $Bold -eq 0) { $pBold } elseif ($y % $Mid -eq 0) { $pMid } else { $pFine }
  $go.DrawLine($pen, [single]$x0, [single]$sy, [single]$x1, [single]$sy)
  if ($y % $Bold -eq 0) {
    $go.DrawString("$y", $f, $brRed, [single]2, [single]($sy - 9))
    $go.DrawString("$y", $f, $brRed, [single]($x1 + 6), [single]($sy - 9))
  }
}
# the figure's own box - everything outside it is off the artwork
$pEdge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 0, 160, 0)), 2
$go.DrawRectangle($pEdge, [single](SX 0), [single](SY 0), [single]($W * $Zoom), [single]($H * $Zoom))

# --- the points as they stand -----------------------------------------------------------------
if (-not $Bare) {
$pRing = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 255, 0, 190)), 3
$brLbl = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(230, 255, 255, 255))
# last number: which side the label hangs on, so none of them runs off the sheet
$marks = @(
  @("A.desc     working rope ends here",  $WorkX, $DescY,    1),
  @("A.brakeIn  strand into the glove",   $InX,   $InY,      1),
  @("A.brake    tail leaves the glove",   $BrkX,  $BrkY,     1),
  @("A.asapIn   rope into the ASAP",      $BackX, $AsapInY,  1),
  @("A.asapOut  rope out of the ASAP",    $BackX, $AsapOutY, 1)
)
foreach ($m in $marks) {
  $cx = SX ([double]$m[1]); $cy = SY ([double]$m[2]); $r = 13
  $go.DrawEllipse($pRing, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r))
  $go.DrawLine($pRing, [single]($cx - 4), [single]$cy, [single]($cx + 4), [single]$cy)
  $go.DrawLine($pRing, [single]$cx, [single]($cy - 4), [single]$cx, [single]($cy + 4))
  $txt = "{0}   ({1:N0},{2:N0})" -f $m[0], $m[1], $m[2]
  $sz = $go.MeasureString($txt, $fs)
  $lx = if ([int]$m[3] -gt 0) { $cx + $r + 8 } else { $cx - $r - 8 - $sz.Width }
  $go.FillRectangle($brLbl, [single]($lx - 3), [single]($cy - $sz.Height / 2), [single]($sz.Width + 6), [single]$sz.Height)
  $go.DrawString($txt, $fs, $brBlk, [single]$lx, [single]($cy - $sz.Height / 2))
}
}

# --- caption ------------------------------------------------------------------------------------
if (-not $Bare) {
$cy0 = $SH - $CAP + 6
$lines = @(
  "Numbers are pixels of images/man-body.png / man-rig.png / man-glove.png (760 x 856). Green box = the artwork; rope above and below it runs off the page.",
  "THE TWO ROPES ARE LOCKED 72.6 px APART SIDEWAYS (the header mark's two stems). Move one across and the other moves the same way; heights are free.",
  "The ASAP is a separate drawing and is PLACED on the backup rope, so say where the rope should be and the device follows.",
  "A point should sit INSIDE the ink that covers it - the rope end is meant to be hidden under the device or the glove, not to touch an outline."
)
$fc = New-Object System.Drawing.Font "Consolas", ([single]12)
for ($i = 0; $i -lt $lines.Count; $i++) {
  $go.DrawString($lines[$i], $fc, $brBlk, [single]$PAD, [single]($cy0 + $i * 17))
}
}
$go.Dispose()
$o.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $o.Dispose()
"$Out   ({0} x {1}, zoom {2}, grid {3}/{4}/{5} artwork px)" -f $SW, $SH, $Zoom, $Fine, $Mid, $Bold
