# Builds the technician the page ships from the owner's three separate drawings.
#
# `Desktop\try.png` holds three pieces on one transparent canvas, apart on purpose:
#   part 1  the man, with his RIG descender and its carabiner drawn in
#   part 2  the absorber, with its carabiner at one end and its swivel at the other
#   part 3  the ASAP - and it has a real HOLE in it, which is the whole point
# tools/climber-parts.ps1 labels and measures them; this script places them.
#
# WHY IT IS DONE THIS WAY. Two finished drawings were cut up to get the ropes between the
# man and his hardware, and both were rejected. This sheet is the answer: because the gear
# is drawn SEPARATELY, the absorber can be lengthened and leaned until the ASAP sits exactly
# on the backup rope, instead of the rope being bent to reach a device that was drawn where
# it was drawn.
#
# THE ONE HARD CONSTRAINT. The two ropes hang from the two stems of the header mark, which
# are 0.12359 of the strip apart - nothing here can change that. So in this frame the ASAP's
# hole must sit exactly 0.12359 * (frame width) to the right of where the working rope dies
# in the RIG. $AsapX below is SOLVED from that, not typed; the absorber is then stretched and
# turned to reach wherever the ASAP had to go.
#
# THE ROPE SHOWS THROUGH THE HOLE FOR FREE. The backup rope is painted in the page's BACK
# layer, behind the whole figure, and the ASAP is part of the body layer - so the device
# covers the rope everywhere except the hole, where the transparent pixels let it through.
# Nothing is cut and nothing is clipped.
#
# Output: images/man-body.png (under the ropes) and images/man-front.png (over them). The
# front layer is ONLY the RIG with its carabiner and the brake glove - the two places a
# front rope ends. The owner asked for the working rope to run in front of all the rest of
# him, his gripping fist included, and lifting anything else into the front layer breaks it.
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\try.png",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [int]$ShipW = 760,          # width the page loads; the frame is the MAN's own box
  # How far apart the two ropes are, as a fraction of the strip. NOT a free number: it is the
  # header mark's two stems, (stemBackX - stemWorkX) * markW = 0.17278 * markW, and markW is
  # 0.7153 of a 116px strip. Widen the strip and the mark has to shrink by the same factor to
  # keep its size on screen, so this comes down with it — 0.09557 at a 150px strip.
  [double]$Sep = 0.09557,
  # --- everything below is in part 1's own pixels (the man, 1097 x 1236) -------------------
  # Where the working rope dies inside the RIG. The device's body runs x 498..580, y 398..495;
  # this sits in its left half so the rope and the absorber diverge going up instead of
  # crowding his fist together.
  [double]$DescX = 512, [double]$DescY = 450,
  # Where the absorber's own carabiner clips to his harness, at the ventral ring under the RIG.
  [double]$RingX = 505, [double]$RingY = 550,
  # How high up the ASAP's attachment sits. Lower it and the absorber shortens; the lean is
  # solved from it, so the piece always reaches.
  [double]$AsapY = 172,
  # Where the absorber's two ends are in ITS own pixels (180 x 321): the carabiner that clips
  # to the harness, and the swivel tip the ASAP hangs on.
  [double]$SorbClipX = 45,  [double]$SorbClipY = 295,
  [double]$SorbTipX = 172,  [double]$SorbTipY = 3,
  # The ASAP's own pixels (65 x 82): the middle of the hole, and the point on its frame that
  # the absorber's swivel meets.
  [double]$HoleX = 17.5, [double]$HoleY = 20,
  [double]$AsapConnX = 12, [double]$AsapConnY = 75,
  # Which labelled blob is which. climber-parts.ps1 sorts them biggest first, so the man is
  # always 1; the rest depend on what else is on the sheet. `take.png` carries THREE absorbers
  # of different lengths (parts 2, 3 and 4) and the ASAP (part 5).
  [int]$ManPart = 1, [int]$SorbPart = 2, [int]$AsapPart = 3,
  # CLEANING THE GEAR, IN THE MAN'S OWN COLOURS. The man is drawn 1097 px wide and ships at 760,
  # so his own speckle averages away in the downscale. The gear is drawn at about a fifth of that
  # and placed at roughly 1:1, so its speckle is shown raw - the owner called the absorber rough
  # and dotted, and he was right. Blurring only smears it and supersampling changed nothing: the
  # noise is in the DRAWING, not in the edge.
  # A plain levels stretch (110/190) did clean it, and was WRONG: it drove the strap to pure
  # black. Measured, the two palettes already agree - his harness webbing is mean L 63.1, the
  # absorber's strap L 58.0, five levels apart. The fault was never the colour.
  # So each pixel is snapped to the NEAREST of his four measured tones instead. That flattens
  # the dither into flat shapes without moving the tone: black outline, webbing, highlight,
  # white. Set $Palette to an empty array to place a piece exactly as drawn.
  # THE REAL FIX IS UPSTREAM: gear drawn at the man's own scale (an absorber about 1000 px long
  # rather than 369) would need none of this.
  [int[]]$Palette = @(0, 63, 182, 255),
  # Ship the man ALONE, with no gear placed on him. For getting the figure onto the page and
  # onto a marking sheet before deciding where the ASAP and the absorber go.
  [switch]$ManOnly,
  [switch]$Preview
)
Add-Type -AssemblyName System.Drawing

# --- pull the three parts off the sheet -----------------------------------------------------
$tmp = Join-Path $env:TEMP "oritoki-parts"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null
$report = & (Join-Path $PSScriptRoot "climber-parts.ps1") -Src $Src -OutDir $tmp
$report
# Snap every pixel to the nearest of the man's own tones, keeping its alpha. See $Palette above.
# Alpha is untouched on purpose: the edge keeps whatever softness it had, and only the fill is
# flattened. Snapping the edge as well would turn every antialiased pixel into a hard one.
function CleanGear($src, $pal) {
  if ($null -eq $pal -or $pal.Count -lt 2) { return $src }
  $o = New-Object System.Drawing.Bitmap $src.Width, $src.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($iy = 0; $iy -lt $src.Height; $iy++) {
    for ($ix = 0; $ix -lt $src.Width; $ix++) {
      $p = $src.GetPixel($ix, $iy)
      if ($p.A -eq 0) { continue }
      $l = 0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B
      $best = $pal[0]; $bd = [Math]::Abs($l - $pal[0])
      foreach ($t in $pal) { $d = [Math]::Abs($l - $t); if ($d -lt $bd) { $bd = $d; $best = $t } }
      $b = [byte]$best
      $o.SetPixel($ix, $iy, [System.Drawing.Color]::FromArgb($p.A, $b, $b, $b))
    }
  }
  $src.Dispose()
  return $o
}
$man = New-Object System.Drawing.Bitmap((Join-Path $tmp "part-$ManPart.png"))
$FW = $man.Width; $FH = $man.Height          # the frame IS the man's box
if (-not $ManOnly) {
  $sorb = CleanGear (New-Object System.Drawing.Bitmap((Join-Path $tmp "part-$SorbPart.png"))) $Palette
  $asap = CleanGear (New-Object System.Drawing.Bitmap((Join-Path $tmp "part-$AsapPart.png"))) $Palette
  "gear snapped to the man's tones: $($Palette -join ', ')"
}

"frame (the man's own box): $FW x $FH"
if ($ManOnly) { "MAN ONLY - no absorber, no ASAP placed" }
# --- solve the placement --------------------------------------------------------------------
# The mark's two stems are what fixes this ($Sep). Everything else bends.
if (-not $ManOnly) {
# NOT $SEP: PowerShell variable names are case-insensitive, so $SEP IS the parameter $Sep, and
# assigning to it here silently overwrote the fraction with a pixel count — which came straight
# back out in the markLeft line printed at the end. The trap CLAUDE.md warns about.
$sepPx = $Sep * $FW
$holeGX = $DescX + $sepPx                     # where the ASAP's hole has to land
$asapLeft = $holeGX - $HoleX
$asapTop  = $AsapY - $AsapConnY
# the absorber has to run from the harness ring to the ASAP's connection point
$tipGX = $asapLeft + $AsapConnX
$tipGY = $asapTop  + $AsapConnY
$dx = $tipGX - $RingX; $dy = $tipGY - $RingY
$needLen = [Math]::Sqrt($dx * $dx + $dy * $dy)
$needAng = [Math]::Atan2($dx, -$dy) * 180 / [Math]::PI     # degrees of lean from straight up
$haveDX = $SorbTipX - $SorbClipX; $haveDY = $SorbTipY - $SorbClipY
$haveLen = [Math]::Sqrt($haveDX * $haveDX + $haveDY * $haveDY)
$haveAng = [Math]::Atan2($haveDX, -$haveDY) * 180 / [Math]::PI
$scale = $needLen / $haveLen
$rot   = $needAng - $haveAng

"rope separation needed: {0:N1} px  ->  working rope x {1:N0}, ASAP hole x {2:N1}" -f $sepPx, $DescX, $holeGX
"absorber: {0:N1} px at {1:N2} deg  ->  {2:N1} px at {3:N2} deg   (scale {4:N3}, turn {5:N2} deg)" -f `
  $haveLen, $haveAng, $needLen, $needAng, $scale, $rot
"ASAP box: x {0:N0}..{1:N0}  y {2:N0}..{3:N0}" -f $asapLeft, ($asapLeft + $asap.Width), $asapTop, ($asapTop + $asap.Height)
}

# --- compose at the drawing's own scale, THEN scale, THEN cut --------------------------------
# That order matters: cutting layers after a downscale antialiases both sides of every cut
# edge, and the two soft edges add up into a hairline seam.
$comp = New-Object System.Drawing.Bitmap $FW, $FH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($comp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
if (-not $ManOnly) {
  # absorber first, so his gripping fist paints over it and reads as holding it
  $g.TranslateTransform([single]$RingX, [single]$RingY)
  $g.RotateTransform([single]$rot)
  $g.ScaleTransform([single]$scale, [single]$scale)
  $g.TranslateTransform([single](-$SorbClipX), [single](-$SorbClipY))
  $g.DrawImage($sorb, 0, 0, $sorb.Width, $sorb.Height)
  $g.ResetTransform()
}
$g.DrawImageUnscaled($man, 0, 0)
# the ASAP last, so it closes over the absorber's swivel
if (-not $ManOnly) {
  $g.DrawImageUnscaled($asap, [int][Math]::Round($asapLeft), [int][Math]::Round($asapTop))
}
$g.Dispose()
$man.Dispose()
if (-not $ManOnly) { $sorb.Dispose(); $asap.Dispose() }

if ($Preview) {
  $p = "C:\Users\gilmo\Downloads\climber-composed.png"
  $w = New-Object System.Drawing.Bitmap $FW, $FH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gw = [System.Drawing.Graphics]::FromImage($w)
  $gw.Clear([System.Drawing.Color]::White); $gw.DrawImageUnscaled($comp, 0, 0); $gw.Dispose()
  $w.Save($p, [System.Drawing.Imaging.ImageFormat]::Png); $w.Dispose(); $comp.Dispose()
  "$p   (composed, full size, nothing written to images/)"
  return
}

# --- down to the shipped size ------------------------------------------------------------
$k = $ShipW / [double]$FW
$SH = [int][Math]::Round($FH * $k)
$small = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gs = [System.Drawing.Graphics]::FromImage($small)
$gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gs.DrawImage($comp, (New-Object System.Drawing.Rectangle 0, 0, $ShipW, $SH), (New-Object System.Drawing.Rectangle 0, 0, $FW, $FH), [System.Drawing.GraphicsUnit]::Pixel)
$gs.Dispose(); $comp.Dispose()

# --- the cut, in the man's own pixels then scaled ------------------------------------------
# The RIG with its carabiner, and the brake glove. Nothing else: see the header.
$RIG   = @(476,402, 596,402, 604,468, 566,578, 498,584, 468,486)
$GLOVE = @(166,636, 278,636, 278,762, 166,762)
function ScaledPoly($flat, $kk) {
  $pts = New-Object "System.Drawing.Point[]" ($flat.Count / 2)
  for ($ix = 0; $ix -lt $flat.Count; $ix += 2) {
    $pts[$ix / 2] = New-Object System.Drawing.Point ([int][Math]::Round($flat[$ix] * $kk)), ([int][Math]::Round($flat[$ix + 1] * $kk))
  }
  return $pts
}
$mask = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gm = [System.Drawing.Graphics]::FromImage($mask)
$gm.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None    # exact complements
$gm.Clear([System.Drawing.Color]::Black)
foreach ($f in @($RIG, $GLOVE)) {
  $gm.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), (ScaledPoly $f $k))
}
$gm.Dispose()

$body  = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$front = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$diff = 0
for ($iy = 0; $iy -lt $SH; $iy++) {
  for ($ix = 0; $ix -lt $ShipW; $ix++) {
    $px = $small.GetPixel($ix, $iy)
    if ($px.A -eq 0) { continue }
    if ($mask.GetPixel($ix, $iy).R -gt 127) { $front.SetPixel($ix, $iy, $px) } else { $body.SetPixel($ix, $iy, $px) }
  }
}
# restack check: body then front must reproduce the composed figure exactly
for ($iy = 0; $iy -lt $SH; $iy++) {
  for ($ix = 0; $ix -lt $ShipW; $ix++) {
    $a = $small.GetPixel($ix, $iy)
    $f = $front.GetPixel($ix, $iy)
    $b = $body.GetPixel($ix, $iy)
    $r = if ($f.A -ne 0) { $f } else { $b }
    if ($r.A -ne $a.A -or ($a.A -ne 0 -and ($r.R -ne $a.R -or $r.G -ne $a.G -or $r.B -ne $a.B))) { $diff++ }
  }
}
$small.Dispose(); $mask.Dispose()
$body.Save((Join-Path $OutDir "man-body.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$front.Save((Join-Path $OutDir "man-front.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$body.Dispose(); $front.Dispose()

"shipped: $ShipW x $SH   (aspect {0:N4})" -f ($SH / $ShipW)
"restack check: $diff pixels differ from the composed figure{0}" -f $(if ($diff -eq 0) { "  OK" } else { "  *** THE CUT IS WRONG, DO NOT SHIP ***" })
"--- for index.html's A table, as fractions of $ShipW x $SH ---"
"  desc     {0:N4} , {1:N4}" -f ($DescX / $FW), ($DescY / $FH)
"  backupX  {0:N4}   (= camX; the ASAP's hole)" -f ($holeGX / $FW)
"  markLeft {0:N4}   (= desc.x - stemWorkX*markW - 0.001443, markW = {1:N5})" -f `
  ($DescX / $FW - 0.73935 * ($Sep / 0.17278) - 0.001443), ($Sep / 0.17278)
foreach ($n in @("man-body.png", "man-front.png")) {
  $fi = Get-Item (Join-Path $OutDir $n)
  "  {0,-15} {1,5} KB" -f $n, [math]::Round($fi.Length / 1KB)
}
