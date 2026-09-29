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
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\chest O.png",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [int]$ShipW = 760,          # width the page loads; the frame is the MAN's own box
  # How far apart the two ropes are, as a fraction of the strip. NOT a free number: it is the
  # header mark's two stems, (stemBackX - stemWorkX) * markW = 0.17278 * markW, and markW is
  # 0.7153 of a 116px strip. Widen the strip and the mark has to shrink by the same factor to
  # keep its size on screen, so this comes down with it â€” 0.09557 at a 150px strip.
  [double]$Sep = 0.09557,
  # --- everything below is in part 1's own pixels (the man, 1097 x 1236) -------------------
  # Where the working rope dies inside the RIG. The device's body runs x 498..580, y 398..495;
  # this sits in its left half so the rope and the absorber diverge going up instead of
  # crowding his fist together.
  [double]$DescX = 512, [double]$DescY = 450,
  # WHERE THE ABSORBER'S LOWER CARABINER CLIPS, and it is the owner's own mark: he drew the
  # absorber's axis in green on a bare grid sheet (Desktop\absorber asap carabiners.png) and its
  # lower end read back at shipped (300.1, 297.1) = native (433, 429). That lands inside the chest
  # ring's right-hand bar (the ring's ink is native x 390..443, y 419..442), so the carabiner's eye
  # closes round the bar instead of sitting beside it.
  [double]$RingX = 433, [double]$RingY = 429,
  # WHERE THE ASAP'S HOLE GOES, in the man's own pixels - the owner's red dot on a grid sheet,
  # read back at shipped (421.6, 61.3), which is native (608.6, 88.5). Since the absorber's
  # carabiner clips into that hole, this is the absorber's top end too. The device then runs
  # native x 591.3..656.3, y 68.5..150.5, and the backup rope (native x 616.85) crosses its body
  # 8.25 px to the RIGHT of the hole - the arrangement in the owner's photo.
  [double]$AsapX = 623.8, [double]$AsapY = 88.5,
  # Where the absorber's two ends are in ITS own pixels. The clip point is the centre of the
  # carabiner's ENCLOSED eye, found by flooding the transparency in from the border (scratchpad
  # holes2.ps1); the tip is the ink furthest from it.
  # WHY PART 2 OF THE THREE. Measured against the geometry the owner's marks fix - chest ring to
  # the ASAP's HOLE - each absorber would have to be distorted by:
  #     part 2 (220x369)  len 392.7 at 29.94 deg  ->  scale 0.985, turn  -1.57 deg
  #     part 3 (208x317)  len 342.4 at 32.05 deg  ->  scale 1.130, turn  -3.69 deg
  #     part 4 (243x242)  len 303.9 at 44.68 deg  ->  scale 1.273, turn -16.31 deg
  # Part 2 needs one and a half per cent. Part 3 was the right answer for one round, while the tip
  # was going to the ASAP's bottom corner instead of its hole - clipping into the hole asks for
  # about 55 px more reach, which is exactly what separates the two pieces.
  [double]$SorbClipX = 22,   [double]$SorbClipY = 340.3,
  [double]$SorbTipX = 218,   [double]$SorbTipY = 0,
  # The ASAP's own pixels (65 x 82). The enclosed transparent hole in its UPPER part - 122 px at
  # box x 12..22, y 14..26, centre (17.3, 20) - is WHERE THE ABSORBER'S UPPER CARABINER GOES. The
  # owner was explicit about it: "the absorber's upper carabiner must be placed IN the ASAP's hole,
  # and not below the ASAP". So the connection point IS the hole, and the two coincide.
  # This was wrong for one round: the connection was taken to be (12, 75), the device's bottom-left
  # corner, which hung the absorber off the underside of the ASAP with its top merely touching. The
  # hole was being read as a window for the backup rope to show through instead.
  [double]$HoleX = 17.3, [double]$HoleY = 20,
  [double]$AsapConnX = 17.3, [double]$AsapConnY = 20,
  # HOW FAR THE ABSORBER'S TOP RUNS PAST THE HOLE'S CENTRE, along its own axis. Landing the tip ON
  # the centre leaves the hole's far half empty, so the piece reads as arriving at the hole rather
  # than going through it. The hole is about 11 px across, so half of that carries the tip to its
  # far rim. (Every one of the owner's three absorbers ends in a SWIVEL, not a carabiner - none has
  # an eye - so this is as far as threading can be taken without a carabiner to thread.)
  [double]$IntoHole = 5.5,
  # Where the loose chest ring (part 6) goes back on him. NOT a guess: the ring is still drawn on
  # the man, and part 6 is a copy of it, so sliding the copy over him and scoring gives one exact
  # answer - native (390,419), mean grey difference 0.02. It is laid back on TOP of the absorber so
  # the ring's bar passes through the carabiner's eye, which is the owner's ask: the same way the
  # lockup's carabiner sits in its anchor, where logo-barlow.png rides over its own carabiner.
  [double]$RingPasteX = 390, [double]$RingPasteY = 419,
  # Which labelled blob is which. climber-parts.ps1 sorts them biggest first, so the man is
  # always 1; the rest depend on what else is on the sheet. `take.png` carries THREE absorbers
  # of different lengths (parts 2, 3 and 4) and the ASAP (part 5).
  [int]$ManPart = 1, [int]$SorbPart = 2, [int]$AsapPart = 5, [int]$RingPart = 6,
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
  # The ring is NOT cleaned: it is the man's own ink, lifted off him at his own scale, so it
  # already carries his tones. Snapping it would flatten a 53x23 piece that has nothing to flatten.
  $ring = New-Object System.Drawing.Bitmap((Join-Path $tmp "part-$RingPart.png"))
  "gear snapped to the man's tones: $($Palette -join ', ')"
}

"frame (the man's own box): $FW x $FH"
# THE CLIP AND TIP MUST BE INSIDE THE ABSORBER THAT WAS LOADED. $SorbPart and the two points are
# three separate parameters, and they were once left disagreeing - part 3 loaded with part 2's
# points, whose clip y of 340.3 is off the bottom of a 317-tall piece. Nothing complained; the
# absorber was simply placed by a point that is not on it, so its carabiner came away from the
# harness ring and the owner had to spot it on the finished picture.
if (-not $ManOnly) {
  $bad = @()
  if ($SorbClipX -lt 0 -or $SorbClipX -gt $sorb.Width -or $SorbClipY -lt 0 -or $SorbClipY -gt $sorb.Height) { $bad += "clip ($SorbClipX,$SorbClipY)" }
  if ($SorbTipX -lt 0 -or $SorbTipX -gt $sorb.Width -or $SorbTipY -lt 0 -or $SorbTipY -gt $sorb.Height) { $bad += "tip ($SorbTipX,$SorbTipY)" }
  if ($bad.Count) {
    throw "absorber is part $SorbPart ($($sorb.Width) x $($sorb.Height)) but $($bad -join ' and ') falls outside it - SorbPart and SorbClip/SorbTip are out of step"
  }
  "absorber: part $SorbPart, $($sorb.Width) x $($sorb.Height); clip and tip both on it  OK"
}
if ($ManOnly) { "MAN ONLY - no absorber, no ASAP placed" }
# --- solve the placement --------------------------------------------------------------------
# The mark's two stems are what fixes this ($Sep). Everything else bends.
if (-not $ManOnly) {
# NOT $SEP: PowerShell variable names are case-insensitive, so $SEP IS the parameter $Sep, and
# assigning to it here silently overwrote the fraction with a pixel count â€” which came straight
# back out in the markLeft line printed at the end. The trap CLAUDE.md warns about.
$sepPx = $Sep * $FW
$ropeGX = $DescX + $sepPx                     # the backup rope's x - the one thing that cannot move
<#  THE HOLE IS NOT ON THE ROPE, and that is the correction the owner's photo of a real ASAP made.
    On the device the rope runs down ONE SIDE and the attachment hole is beside it, so the
    absorber's carabiner clips in clear of the rope - in his photo the rope is on the right and the
    carabiner hangs off the left. The hole was being put ON the rope before, which is what a window
    for the rope to show through would need, and it is not what the hole is for.
    So the hole goes where HE marked it - a red dot on the grid at shipped (421.6, 61.3) - and the
    rope then falls where it falls inside the device. $AsapX is that mark in the man's own pixels;
    the check below is that the rope still crosses the device's body.                            #>
$holeGX = $AsapX
$asapLeft = $holeGX - $HoleX
$asapTop  = $AsapY - $AsapConnY
# the absorber has to run from the harness ring to the ASAP's connection point - and a little
# PAST it, so the tip crosses the hole instead of stopping in the middle of it ($IntoHole)
$connGX = $asapLeft + $AsapConnX
$connGY = $asapTop  + $AsapConnY
$aimX = $connGX - $RingX; $aimY = $connGY - $RingY
$aimLen = [Math]::Sqrt($aimX * $aimX + $aimY * $aimY)
$tipGX = $connGX + $IntoHole * $aimX / $aimLen
$tipGY = $connGY + $IntoHole * $aimY / $aimLen
$dx = $tipGX - $RingX; $dy = $tipGY - $RingY
$needLen = [Math]::Sqrt($dx * $dx + $dy * $dy)
$needAng = [Math]::Atan2($dx, -$dy) * 180 / [Math]::PI     # degrees of lean from straight up
$haveDX = $SorbTipX - $SorbClipX; $haveDY = $SorbTipY - $SorbClipY
$haveLen = [Math]::Sqrt($haveDX * $haveDX + $haveDY * $haveDY)
$haveAng = [Math]::Atan2($haveDX, -$haveDY) * 180 / [Math]::PI
$scale = $needLen / $haveLen
$rot   = $needAng - $haveAng

"rope separation needed: {0:N1} px  ->  working rope x {1:N0}, backup rope x {2:N1}" -f $sepPx, $DescX, $ropeGX
$inBody = ($ropeGX -ge $asapLeft -and $ropeGX -le ($asapLeft + $asap.Width))
"ASAP hole x {0:N1} (the owner's mark); the backup rope crosses the device {1:N1} px to its right  {2}" -f `
  $holeGX, ($ropeGX - $holeGX), $(if ($inBody) { "- inside the body, OK" } else { "*** THE ROPE MISSES THE DEVICE ***" })
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
<#  THE ORDER IS THE OWNER'S, AND IT IS NOT THE OBVIOUS ONE.
    man -> ASAP -> absorber -> chest ring.
    He asked for two things and each one fixes a layer:
      "aáƒ‘áƒ¡áƒáƒ áƒ‘áƒ”áƒ áƒ˜áƒ¡ áƒ–áƒ”áƒ“áƒ áƒ™áƒáƒ áƒáƒ‘áƒ˜áƒœáƒ˜ áƒáƒ¡áƒáƒžáƒ˜áƒ¡ áƒ¬áƒ˜áƒœ áƒ£áƒœáƒ“áƒ áƒ©áƒáƒœáƒ“áƒ”áƒ¡" - the absorber's top connector shows IN
      FRONT of the ASAP, so the ASAP goes down FIRST and the absorber closes over it. (It used to
      be the other way round: the ASAP was painted last so it shut over the swivel.)
      "áƒ›áƒ™áƒ”áƒ áƒ“áƒ˜áƒ¡ áƒ áƒ’áƒáƒšáƒ¨áƒ˜ áƒ©áƒáƒ¡áƒ•áƒ˜ áƒáƒ‘áƒ¡áƒáƒ áƒ‘áƒ”áƒ áƒ˜áƒ¡ áƒ¥áƒ•áƒ”áƒ“áƒ áƒ™áƒáƒ áƒáƒ‘áƒ˜áƒœáƒ˜ áƒ˜áƒ› áƒžáƒ áƒ˜áƒœáƒªáƒ˜áƒžáƒ˜áƒ— áƒ áƒáƒ’áƒáƒ áƒª áƒáƒœáƒ™áƒ”áƒ áƒ¨áƒ˜ áƒáƒ áƒ˜áƒ¡ áƒ™áƒáƒ áƒáƒ‘áƒ˜áƒœáƒ˜" -
      the lower carabiner hangs IN the chest ring the way the lockup's carabiner hangs in its
      anchor. That needs the ring's bar over the carabiner and the rest of the carabiner over him,
      which one layer cannot do - so he drew the ring as its own piece (part 6) and it goes on
      LAST, exactly where it already sits on the man.
    So the absorber is now in FRONT of him, not behind. The note that used to be here said it went
    behind so his gripping fist would read as holding it; that fist is on the WORKING rope, and the
    absorber passes to the left of it, so nothing is lost.                                       #>
$g.DrawImageUnscaled($man, 0, 0)
if (-not $ManOnly) {
  # the ASAP on the backup rope, under the absorber's top
  $g.DrawImageUnscaled($asap, [int][Math]::Round($asapLeft), [int][Math]::Round($asapTop))
  # the absorber, stretched and turned to run from the chest ring to the ASAP
  $g.TranslateTransform([single]$RingX, [single]$RingY)
  $g.RotateTransform([single]$rot)
  $g.ScaleTransform([single]$scale, [single]$scale)
  $g.TranslateTransform([single](-$SorbClipX), [single](-$SorbClipY))
  $g.DrawImage($sorb, 0, 0, $sorb.Width, $sorb.Height)
  $g.ResetTransform()
  # and the chest ring back on top, so its bar threads the carabiner's eye
  $g.DrawImageUnscaled($ring, [int]$RingPasteX, [int]$RingPasteY)
}
$g.Dispose()
$man.Dispose()
if (-not $ManOnly) { $sorb.Dispose(); $asap.Dispose(); $ring.Dispose() }

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
# THREE layers, not two, and the middle one is why: the owner drew the brake rope running
# ACROSS the descender's face, with a hook to the left where it leaves. So the strand has to be
# painted OVER the device and still UNDER the glove it runs into, and one front layer cannot do
# both. The page stacks them body -> working rope -> descender -> brake strand -> glove.
# THE DESCENDER, AND NOTHING ELSE. This is the owner's own outline, drawn in yellow on a grid
# sheet and read back row by row - not a box guessed round the device.
# The polygon it replaced reached from y 402 down to 584 and swallowed the carabiner, the waist
# belt and a slab of his thigh. All of that was being lifted into the FRONT layer, so the brake
# strand ran BEHIND his hip instead of across it, and the owner spotted it: he circled the area
# in red and said a sleeve was being treated as part of the device.
# The carabiner belongs in the body layer, which is also right: the rope comes out of the
# descender and passes IN FRONT of the carabiner that hangs it on the harness.
$RIG   = @(526,403, 517,413, 508,423, 501,433, 495,443, 489,453, 483,463, 480,473, 480,483,
           484,492, 515,492, 533,483, 548,473, 559,463, 564,453, 566,443, 566,433, 565,423,
           564,413, 550,403)
# THE BRAKE GLOVE, with the corner the rope crosses cut off the top. The hand has TWO black
# contour lines where the rope arrives - the cuff's and the glove's - and the owner was precise
# about them: the rope crosses the FIRST and not the second. So the strand has to be painted
# over the outer contour and go behind at the inner one, and his yellow line on the grid is
# where that happens: shipped (167.5, 462.0).
# Solved from the rope's own direction (-0.7728, 0.6348), not drawn: the line through his mark
# meets the box's top edge at x 216 and its right edge at y 711.
# (Two rounds were spent either side of this. The whole box hid the rope at the OUTER contour,
# 18px back from A.brakeIn, so it never crossed either line; a cut through his earlier + hid it
# at 3px back, so it crossed both. That one hid it at about 11.)
# THEN HE ASKED FOR A LITTLE MORE. He circled the rope's tip on a grid sheet and said it should
# reach the hand's slightly slanted black band - the tip was ending at shipped (173.5, 460.3) and
# the band runs about 5 shipped px further along. So the whole cut line is slid 5 * 1.44342 = 7.2
# native px down the rope, which is (-5.6, +4.6), and re-extended to the box: it now leaves the top
# edge at x 207 and the right edge at y 722. The line stays PERPENDICULAR to the rope (its own
# direction dotted with the rope's is -0.003), which is what keeps the tip cut square.
$GLOVE = @(166,636, 207,636, 278,722, 278,762, 166,762)
function ScaledPoly($flat, $kk) {
  $pts = New-Object "System.Drawing.Point[]" ($flat.Count / 2)
  for ($ix = 0; $ix -lt $flat.Count; $ix += 2) {
    $pts[$ix / 2] = New-Object System.Drawing.Point ([int][Math]::Round($flat[$ix] * $kk)), ([int][Math]::Round($flat[$ix + 1] * $kk))
  }
  return $pts
}
function MaskOf($flat) {
  $m = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gm = [System.Drawing.Graphics]::FromImage($m)
  $gm.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None    # exact complements
  $gm.Clear([System.Drawing.Color]::Black)
  $gm.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), (ScaledPoly $flat $k))
  $gm.Dispose()
  return $m
}
$mRig = MaskOf $RIG
$mGlv = MaskOf $GLOVE
<#  THE BODY IS NOT CUT. It keeps the WHOLE figure; the upper layers are copies of their own
    regions laid on top. That looks wasteful and it is the point.
    A cut leaves a HOLE, and these layers ship at 760 while the browser draws them at 150 - it
    downscales EACH ONE on its own and only then composites. Along the edge of a hole one layer
    has opaque pixels and the other has nothing, so both sides resample to partial alpha and the
    seam comes out translucent. The owner saw it as transparent rectangles across his wrist,
    which is the glove box's own edges. Complementary pieces simply cannot survive being
    rescaled apart.
    With no hole there is nothing to line up and nothing to lose, at any scale or any DPR.
    Compositing a piece over its own pixels is safe BECAUSE they are its own: where the copy is
    opaque the result is the same pixel, and where the drawing's own antialiasing makes it
    partial it blends a colour with itself, so only the alpha rises. That is not the trap
    CLAUDE.md warns about - painting a hand twice over a ROPE darkens it, because what is
    underneath is a different colour. Here it is identical.                                    #>


$body  = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$rig   = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$glove = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$diff = 0
for ($iy = 0; $iy -lt $SH; $iy++) {
  for ($ix = 0; $ix -lt $ShipW; $ix++) {
    $px = $small.GetPixel($ix, $iy)
    if ($px.A -eq 0) { continue }
    # The body keeps everything; each upper layer takes a copy of its own region. No holes.
    $body.SetPixel($ix, $iy, $px)
    if ($mGlv.GetPixel($ix, $iy).R -gt 127)      { $glove.SetPixel($ix, $iy, $px) }
    elseif ($mRig.GetPixel($ix, $iy).R -gt 127)  { $rig.SetPixel($ix, $iy, $px) }
  }
}
# restack check: body, then rig, then glove must reproduce the composed figure exactly
for ($iy = 0; $iy -lt $SH; $iy++) {
  for ($ix = 0; $ix -lt $ShipW; $ix++) {
    $a = $small.GetPixel($ix, $iy)
    $gl = $glove.GetPixel($ix, $iy); $rg = $rig.GetPixel($ix, $iy); $b = $body.GetPixel($ix, $iy)
    $r = if ($gl.A -ne 0) { $gl } elseif ($rg.A -ne 0) { $rg } else { $b }
    if ($r.A -ne $a.A -or ($a.A -ne 0 -and ($r.R -ne $a.R -or $r.G -ne $a.G -or $r.B -ne $a.B))) { $diff++ }
  }
}
$small.Dispose(); $mRig.Dispose(); $mGlv.Dispose()
$body.Save((Join-Path $OutDir "man-body.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$rig.Save((Join-Path $OutDir "man-rig.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$glove.Save((Join-Path $OutDir "man-glove.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$body.Dispose(); $rig.Dispose(); $glove.Dispose()

"shipped: $ShipW x $SH   (aspect {0:N4})" -f ($SH / $ShipW)
"restack check: $diff pixels differ from the composed figure{0}" -f $(if ($diff -eq 0) { "  OK" } else { "  *** THE CUT IS WRONG, DO NOT SHIP ***" })
"--- for index.html's A table, as fractions of $ShipW x $SH ---"
"  desc     {0:N4} , {1:N4}" -f ($DescX / $FW), ($DescY / $FH)
"  backupX  {0:N4}   (= camX; the backup ROPE, not the hole - they are different points now)" -f ($ropeGX / $FW)
"  markLeft {0:N4}   (= desc.x - stemWorkX*markW - 0.001443, markW = {1:N5})" -f `
  ($DescX / $FW - 0.73935 * ($Sep / 0.17278) - 0.001443), ($Sep / 0.17278)
foreach ($n in @("man-body.png", "man-rig.png", "man-glove.png")) {
  $fi = Get-Item (Join-Path $OutDir $n)
  "  {0,-15} {1,5} KB" -f $n, [math]::Round($fi.Length / 1KB)
}
