# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Builds a measuring grid over climber.png so the owner can mark exact rope positions.
# Grid units are the SAME fractions the rope code uses (fraction of the figure box).
Add-Type -AssemblyName System.Drawing

$src   = "$REPO\images\climber.png"
$out   = "C:\Users\gilmo\Downloads\climber-grid.png"

$img   = [System.Drawing.Image]::FromFile($src)
$scale = 2
$W = $img.Width  * $scale     # 1120
$H = $img.Height * $scale     # 1372
$ML = 76; $MT = 76; $MR = 30; $MB = 46

$bmp = New-Object System.Drawing.Bitmap(($ML + $W + $MR), ($MT + $H + $MB))
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

# figure box outline + artwork
$g.DrawImage($img, $ML, $MT, $W, $H)

$penFine = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70,120,120,120)), 1
$penMid  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150,90,90,90)), 1
$penMaj  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220,20,20,20)), 2
$fSmall  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fBig    = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$brDark  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(20,20,20))
$brGrey  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110,110,110))

# ---- vertical lines (X = fraction of WIDTH) -------------------------------
for ($i = 0; $i -le 100; $i++) {
  $x = $ML + ($i / 100.0) * $W
  if ($i % 10 -eq 0)    { $pen = $penMaj }
  elseif ($i % 5 -eq 0) { $pen = $penMid }
  else                  { $pen = $penFine }
  $g.DrawLine($pen, [single]$x, [single]$MT, [single]$x, [single]($MT + $H))
  if ($i % 10 -eq 0) {
    $t = ($i / 100.0).ToString("0.00")
    $sz = $g.MeasureString($t, $fBig)
    $g.DrawString($t, $fBig, $brDark, [single]($x - $sz.Width / 2), [single]($MT - 30))
  } elseif ($i % 5 -eq 0) {
    $t = ($i / 100.0).ToString("0.00")
    $sz = $g.MeasureString($t, $fSmall)
    $g.DrawString($t, $fSmall, $brGrey, [single]($x - $sz.Width / 2), [single]($MT - 52))
  }
}

# ---- horizontal lines (Y = fraction of HEIGHT) ---------------------------
for ($i = 0; $i -le 100; $i++) {
  $y = $MT + ($i / 100.0) * $H
  if ($i % 10 -eq 0)    { $pen = $penMaj }
  elseif ($i % 5 -eq 0) { $pen = $penMid }
  else                  { $pen = $penFine }
  $g.DrawLine($pen, [single]$ML, [single]$y, [single]($ML + $W), [single]$y)
  if ($i % 10 -eq 0) {
    $t = ($i / 100.0).ToString("0.00")
    $sz = $g.MeasureString($t, $fBig)
    $g.DrawString($t, $fBig, $brDark, [single]($ML - $sz.Width - 6), [single]($y - $sz.Height / 2))
  } elseif ($i % 5 -eq 0) {
    $t = ($i / 100.0).ToString("0.00")
    $sz = $g.MeasureString($t, $fSmall)
    $g.DrawString($t, $fSmall, $brGrey, [single]($ML - $sz.Width - 8), [single]($y - $sz.Height / 2))
  }
}

# ---- the ropes as the site draws them RIGHT NOW --------------------------
function PX([double]$fx) { return [single]($ML + $fx * $W) }
function PY([double]$fy) { return [single]($MT + $fy * $H) }

$penBackup = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230,220,38,38)), 4    # red
$penWork   = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230,37,99,235)), 4    # blue
$penBrake  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230,16,150,90)), 4    # green

# backup rope: straight vertical at 0.573
$g.DrawLine($penBackup, (PX 0.573), (PY 0), (PX 0.573), (PY 1))
# working rope: vertical at 0.44 -> lands on the descender at 0.44 / 0.33
$g.DrawLine($penWork, (PX 0.44), (PY 0), (PX 0.44), (PY 0.33))
# brake strand: gripping hand 0.478/0.324 -> brake fist 0.226/0.528
$g.DrawLine($penBrake, (PX 0.478), (PY 0.324), (PX 0.226), (PY 0.528))
# tail: brake fist 0.165/0.585 -> ground
$g.DrawLine($penBrake, (PX 0.165), (PY 0.585), (PX 0.165), (PY 1))

# anchor dots
$dots = @(
  @{ x = 0.44;  y = 0.33;  c = "desc 0.44/0.33" },
  @{ x = 0.478; y = 0.324; c = "descOut 0.478/0.324" },
  @{ x = 0.226; y = 0.528; c = "brakeIn 0.226/0.528" },
  @{ x = 0.165; y = 0.585; c = "brake 0.165/0.585" }
)
$brDot = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,140,0))
foreach ($d in $dots) {
  $g.FillEllipse($brDot, [single]((PX $d.x) - 6), [single]((PY $d.y) - 6), [single]12, [single]12)
}

# ---- legend ---------------------------------------------------------------
$fLeg = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$ly = $MT + $H + 8
$g.DrawLine($penWork,   [single]$ML, [single]($ly + 10), [single]($ML + 40), [single]($ly + 10))
$g.DrawString("working rope  X = 0.44 (vertical)", $fLeg, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(37,99,235))), [single]($ML + 48), [single]$ly)
$g.DrawLine($penBackup, [single]($ML + 330), [single]($ly + 10), [single]($ML + 370), [single]($ly + 10))
$g.DrawString("backup rope  X = 0.573", $fLeg, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220,38,38))), [single]($ML + 378), [single]$ly)
$g.DrawString("grid = 0.01", $fLeg, $brGrey, [single]($ML + 660), [single]$ly)

$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$img.Dispose()
"saved: $out"

