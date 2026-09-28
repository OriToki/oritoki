# The HEADER's two rope/knot joins, under a numbered grid, so a fault there can be pointed at by
# its coordinates instead of described.
#
# The numbers are the MARK's own pixels - the 400 x 438 box images/logo-*.png share - so anything
# marked on this grid can be found directly in the artwork and in tools/logo-*.ps1. They are NOT
# the render's device pixels (that is tools/page-grid.ps1) and not CSS pixels: the cord is DRAWN in
# this space, and the SVG rope's anchors (A.stemWork* / A.stemBack*) are already held as fractions
# of this same box, so a correction expressed here needs no conversion to apply.
#
# Drawn over the LIVE page rather than over the layers, because the join is the one place where the
# drawing and the SVG rope meet and only the browser puts them together: the drawn cord is a bitmap
# the browser resamples, the rope is a hard-edged stroke, and the whole question is whether the two
# read as one cord. tools/logo-grid.ps1 cannot show that - it has no ropes in it.
#
# WHITE by default. Both joins are black-outlined and a step in a black outline is all but
# invisible on the dark theme - which is how a couple of faults survived three rounds of "gone".
# Pass -Dark for the other theme. The white is not the light theme alone, either: the hero behind
# the mark is a dark photo in BOTH themes and the strip is position:fixed over it, so the backdrop
# has to be injected under the strip (see below).
param([ValidateSet("work","back","both")][string]$Which = "both",
      [switch]$Dark,
      [int]$DSF = 8,            # device scale of the render; 1 mark px = 0.2074 * DSF device px
      [int]$Zoom = 8,           # output pixels per MARK pixel
      [int]$Step = 5, [int]$Label = 20,
      [string]$Out = "C:\Users\gilmo\Downloads\join-grid.png",
      # The strip's geometry. KEEP IN STEP with :root in index.html and with A.markW / A.markLeft /
      # A.brandTop / A.stem* in its script - this tool is only a ruler if it lands where the page does.
      [double]$WorkerWidth = 116, [double]$ClimberLeft = 52,
      [double]$MarkW = 0.7153, [double]$MarkLeft = -0.0904, [double]$BrandTop = 4,
      [double]$StemWorkX = 0.73935, [double]$StemWorkY = 0.3750,
      [double]$StemBackX = 0.91213, [double]$StemBackY = 0.7968)

$root = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki"
$sc = Join-Path $env:TEMP "oritoki-joingrid"
if (-not (Test-Path $sc)) { New-Item -ItemType Directory $sc | Out-Null }

# --- the lab copy -------------------------------------------------------------------------------
# Beside the real page, so every relative asset still resolves. ReadAllText/WriteAllText and NOT
# Get-Content | Set-Content: the pipeline re-encodes and has silently destroyed this file's
# Georgian text before.
$lab = Join-Path $root "_joingrid.html"
$html = [System.IO.File]::ReadAllText((Join-Path $root "index.html"), [System.Text.Encoding]::UTF8)
if (-not $Dark) {
  # Headless Chrome answers DARK to prefers-color-scheme, and localStorage on a file:// page can
  # throw (the page's own pre-paint script swallows it in a catch), so pin the theme in the
  # variable itself rather than trying to set it from outside.
  $html = $html.Replace('var t = localStorage.getItem("oritoki_theme");', 'var t = "light";')
}
$back = $(if ($Dark) { "#0f1115" } else { "#fff" })
# z-index 0 puts the backdrop under .lock-piece (z-1) and both rope layers, so it replaces the hero
# photo without covering anything being measured.
$css = "#ropeClimber::before{content:`"`";position:absolute;left:-400px;right:-400px;top:-400px;bottom:-400px;background:$back;z-index:0}"
$html = $html.Replace('</head>', "<style>$css</style></head>")
[System.IO.File]::WriteAllText($lab, $html, (New-Object System.Text.UTF8Encoding $false))

$shot = Join-Path $sc "join$DSF.png"
if (Test-Path $shot) { [System.IO.File]::Delete($shot) }
# A fresh profile every run - Chrome caches the file:// page between runs and will happily render
# the previous version of it - and wait for the file, which is written AFTER the process exits.
$udd = Join-Path $sc ("cp" + (Get-Random))
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-sandbox `
  --user-data-dir="$udd" --hide-scrollbars --force-device-scale-factor=$DSF --virtual-time-budget=6000 `
  --window-size=1200,400 --screenshot="$shot" "file:///$($lab.Replace('\','/'))" | Out-Null
for ($i = 0; $i -lt 60; $i++) { if ((Test-Path $shot) -and (Get-Item $shot).Length -gt 10000) { break }; Start-Sleep -Milliseconds 400 }
[System.IO.File]::Delete($lab)
if (-not (Test-Path $shot)) { throw "no render" }

# --- mark pixels <-> the render ------------------------------------------------------------------
# The mark is CSS-sized from the strip, so one number places and scales it: 400 artwork px are
# shown across MarkW of a WorkerWidth strip. Vertical scale is the same - the img has height:auto.
$markCssW = $WorkerWidth * $MarkW
$scale = $markCssW / 400.0                        # CSS px per mark px
$markCssL = $ClimberLeft + $WorkerWidth * $MarkLeft
function DevX([double]$mx) { ($markCssL + $mx * $scale) * $DSF }
function DevY([double]$my) { ($BrandTop + $my * $scale) * $DSF }

Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap $shot

# One panel per join, cropped in MARK pixels around its stem. The cord's last drawn row is 171
# (working) and 350 (backup); the crops start well above each knot and run well past the join so
# the rope can be followed out of it.
$panels = @()
if ($Which -ne "back") { $panels += ,@("WORKING", 262, 120, 72, 110, $StemWorkX, $StemWorkY) }
if ($Which -ne "work") { $panels += ,@("BACKUP",  330, 300, 72, 110, $StemBackX, $StemBackY) }

$mrg = 48
# wide enough for the SECOND panel's row numbers, which are drawn to the left of their own panel
# and would otherwise land on top of the first panel's picture
$gap = 56
$panelW = 0; $panelH = 0
foreach ($p in $panels) { $panelW += $p[3] * $Zoom + $gap; $panelH = [math]::Max($panelH, $p[4] * $Zoom) }
$canvas = New-Object System.Drawing.Bitmap ([int]($panelW + $mrg)), ([int]($panelH + $mrg + 20)), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(255,24,24,28))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

$thin = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(60,255,0,255)),1
$fat  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150,255,0,255)),1
$f    = New-Object System.Drawing.Font("Consolas",11,[System.Drawing.FontStyle]::Bold)
$fh   = New-Object System.Drawing.Font("Consolas",12,[System.Drawing.FontStyle]::Bold)
$ink  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,80,255))
$dot  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,0,255,120))
$dotP = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230,0,255,120)),1

$ox = $mrg
foreach ($p in $panels) {
  $name = $p[0]; $cx = [double]$p[1]; $cy = [double]$p[2]; $cw = [double]$p[3]; $ch = [double]$p[4]
  $stemX = [double]$p[5] * 400.0; $stemY = [double]$p[6] * 438.0
  $dstR = New-Object System.Drawing.Rectangle ([int]$ox), ([int]$mrg), ([int]($cw*$Zoom)), ([int]($ch*$Zoom))
  # the source rectangle in the render's device pixels, straight off the mark-pixel crop
  $sx = DevX $cx; $sy = DevY $cy
  $srcR = New-Object System.Drawing.Rectangle ([int][math]::Round($sx)), ([int][math]::Round($sy)),
                                              ([int][math]::Round($cw*$scale*$DSF)), ([int][math]::Round($ch*$scale*$DSF))
  $g.DrawImage($src, $dstR, $srcR, [System.Drawing.GraphicsUnit]::Pixel)
  $g.DrawString($name, $fh, $ink, [single]$ox, [single]6)

  for ($x = [int]$cx; $x -le $cx + $cw; $x++) {
    if ($x % $Step -ne 0) { continue }
    $px = $ox + ($x - $cx) * $Zoom
    $g.DrawLine($(if ($x % $Label -eq 0) { $fat } else { $thin }), [int]$px, [int]$mrg, [int]$px, [int]($mrg + $ch*$Zoom))
    if ($x % $Label -eq 0) { $g.DrawString(("{0:000}" -f $x), $f, $ink, [single]($px - 15), [single]($mrg + $ch*$Zoom + 2)) }
  }
  for ($y = [int]$cy; $y -le $cy + $ch; $y++) {
    if ($y % $Step -ne 0) { continue }
    $py = $mrg + ($y - $cy) * $Zoom
    $g.DrawLine($(if ($y % $Label -eq 0) { $fat } else { $thin }), [int]$ox, [int]$py, [int]($ox + $cw*$Zoom), [int]$py)
    if ($y % $Label -eq 0) { $g.DrawString(("{0:000}" -f $y), $f, $ink, [single]($ox - 44), [single]($py - 8)) }
  }
  # Where the SVG rope is anchored - A.stemWork / A.stemBack. The rope actually starts a whole
  # rope-width UP the cord from here (sizeRopes pulls it back so the round cap stays inside the
  # drawing), so this dot is the JOIN, not the rope's first pixel.
  $ringX = $ox + ($stemX - $cx) * $Zoom; $ringY = $mrg + ($stemY - $cy) * $Zoom
  if ($ringX -ge $ox -and $ringX -le $ox + $cw*$Zoom -and $ringY -ge $mrg -and $ringY -le $mrg + $ch*$Zoom) {
    $g.FillEllipse($dot, [single]($ringX-3), [single]($ringY-3), 7, 7)
    $g.DrawEllipse($dotP, [single]($ringX-11), [single]($ringY-11), 23, 23)
  }
  $ox += $cw * $Zoom + $gap
}
$g.Dispose()
$canvas.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $src.Dispose()

"$Out"
"  numbers are the MARK's own 400 x 438 pixels; grid step $Step, labelled every $Label"
"  1 mark px = {0:N4} CSS px = {1:N3} device px at {2}x; the panel is {3} output px per mark px" -f $scale, ($scale*$DSF), $DSF, $Zoom
"  green dot = the SVG rope's anchor (A.stemWork / A.stemBack); the rope starts a rope-width above it"
"  theme: $(if ($Dark) { 'dark' } else { 'white - where a black outline can actually be judged' })"
