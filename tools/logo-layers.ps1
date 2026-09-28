# Builds the header's five layers out of the owner's three drawings.
#
#   logo-plate.png    both bolt hangers, WHOLE (Desktop\parts\take it 2.png). Bottom of the stack:
#                     a hanger is bolted flat to the wall and its carabiner hangs in front of it.
#   logo-back.png     the backup rope's carabiner and knot, WHOLE (Desktop\parts\take it 1.png).
#   logo-barlow.png   the LOWER hanger's diagonal bar, on its own.
#   logo-work.png     the main working rope's carabiner and knot, the same piece placed again.
#   logo-rest.png     the lettering, and the UPPER hanger's bar.
#
# Painted in that order it reads as the hardware goes together: plate, carabiner, bar. And the main
# working rope is in front of the lower anchor, because it runs down past it to the technician.
#
# EVERY piece is drawn from the owner's own whole file, never cut out of the finished logo. That is
# the point of this version. A cut can only hold what is VISIBLE, so a cut hanger is missing the
# sliver its own bar covers and a cut carabiner is missing the part the hanger covers - and the
# moment either turns, the hole shows. Earlier versions cut, and the owner kept finding the holes.
#
# Nothing here is fitted by search either. Each placement comes from a LANDMARK: the white disc
# inside a hex nut for the hangers, and for the carabiners a slide-and-score against an exact cut
# of the same assembly, checked by eye (tools/logo-place.ps1, scratchpad hexfit.ps1). The two
# hangers came out at 0.2288 and 0.2296 independently, and their offset matched the distance
# between the two hinges the owner marked to within three pixels. Agreement like that is the check.
#
# The lettering is what is LEFT: the logo with everything the placed pieces cover taken out of it.
#
# PowerShell note, five times over: $P and $p are one variable, so are $Out and $out, and so are
# $K and $k. Check every new name against the parameters and the loop counters.
param(
  [string]$Logo = "C:\Users\gilmo\OneDrive\Desktop\parts\final logo.png",
  [string]$Cara = "C:\Users\gilmo\OneDrive\Desktop\parts\take it 1.png",
  [string]$Hang = "C:\Users\gilmo\OneDrive\Desktop\parts\take it 2.png",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [int]$OutW = 400,
  # all on the mark's own ink box, which is the box index.html places the layers by
  [int]$WorkX = 555, [int]$WorkY = 72, [int]$BackX = 712, [int]$BackY = 547,
  [double]$CaraScale = 0.440,
  [int]$HangUpX = 656, [int]$HangUpY = -59, [int]$HangLoX = 810, [int]$HangLoY = 416,
  [double]$HangScale = 0.2292,
  # The LOWER anchor - hanger, bar, carabiner and knot - slid sideways as one piece, in the logo's
  # own pixels, AFTER everything else is worked out. Its hinge goes with it, so the assembly still
  # hangs off its own bolt and only its place on the page changes; the rope follows because the rope
  # starts at the cord's end, which is part of the piece.
  # Why: the backup rope has to clear the fist gripping the descender. At 0 it passed 0.75px from
  # the glove's edge - the owner asked for daylight there.
  # The MASK is built from the unshifted placements on purpose. It says which of the LOGO's own ink
  # is hardware and must come out of the lettering, and the logo was drawn with the anchor where it
  # was; build the mask from the shifted copy and the drawing's own carabiner stays behind.
  # Room to move: logo-back's ink reached x 377 of the 400-wide layer, so about 20 layer pixels,
  # which is 54 here. 29 is a 1.9px step on a 97px strip.
  [int]$LowShiftX = 29,
  # How big the HARDWARE is against the lettering. 1.0 is the logo as drawn; below that the
  # carabiners, knots and hangers shrink and the lettering stays exactly as it is.
  # Why: measured against the technician the drawn hardware is about twice life size and the rope
  # three times (scratchpad scale.ps1 - carabiner 216mm against a real 110, knot 162 against 80,
  # rope 34 against 11). The owner wants it close to real without the wordmark changing.
  # Everything shrinks ABOUT ITS OWN HINGE - the point the carabiner turns on, which the owner
  # marked himself - so each assembly stays hanging where it hangs and only gets smaller.
  [double]$HardScale = 0.55,
  [string]$Word = "C:\Users\gilmo\OneDrive\Desktop\parts\only or tok.png",
  [int]$WordX = -204, [int]$WordY = -69, [double]$WordScale = 1.0406,
  [switch]$DryRun
)
Add-Type -AssemblyName System.Drawing
function Open($path) {
  $fs = [System.IO.File]::OpenRead($path)
  $im = [System.Drawing.Image]::FromStream($fs)
  $bm = New-Object System.Drawing.Bitmap($im)
  $im.Dispose(); $fs.Close(); $fs.Dispose(); return $bm
}
$logoBmp = Open $Logo
$LW = $logoBmp.Width; $LH = $logoBmp.Height
$rc = New-Object System.Drawing.Rectangle 0, 0, $LW, $LH
$ld = $logoBmp.LockBits($rc, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$LS = $ld.Stride; $LB = New-Object 'byte[]' ($LS * $LH)
[System.Runtime.InteropServices.Marshal]::Copy($ld.Scan0, $LB, 0, $LB.Length)
$logoBmp.UnlockBits($ld)
$lx = $LW; $hx = -1; $ly = $LH; $hy = -1
for ($y = 0; $y -lt $LH; $y++) { for ($x = 0; $x -lt $LW; $x++) {
  if ($LB[$y * $LS + $x * 4 + 3] -le 40) { continue }
  if ($x -lt $lx) { $lx = $x }; if ($x -gt $hx) { $hx = $x }
  if ($y -lt $ly) { $ly = $y }; if ($y -gt $hy) { $hy = $y } } }
$bw = $hx - $lx + 1; $bh = $hy - $ly + 1
"logo $LW x $LH    ink box $lx..$hx x $ly..$hy   ($bw x $bh)"

function Blank { return New-Object System.Drawing.Bitmap($bw, $bh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb) }
function Place($srcBmp, $px, $py, $sc) {
  $lay = Blank
  $gl = [System.Drawing.Graphics]::FromImage($lay)
  $gl.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $gl.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $gl.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $gl.DrawImage($srcBmp, (New-Object System.Drawing.Rectangle ([int]$px), ([int]$py),
                          ([int]($srcBmp.Width * $sc)), ([int]($srcBmp.Height * $sc))))
  $gl.Dispose(); return $lay
}

# ---- the carabiners, and the hangers ------------------------------------------------------------
# the two hinges, in the mark's own pixels - keep in step with A.pivotWork / A.pivotBack
# Parenthesise each one. Inside @( ) the comma binds tighter than the arithmetic, so
# @(0.7375 * $bw, 0.1266 * $bh) does not mean what it looks like - it multiplies by a two-element
# list and the hinges came out near zero, which put every piece of hardware in the top-left corner.
$pivWork = @((0.7375 * $bw), (0.1266 * $bh))
$pivBack = @((0.8804 * $bw), (0.5356 * $bh))
# Worked out inline, not in a helper. A function here returned nothing at all and every layer that
# depended on it came out null - not worth the time to find out why when two lines do it.
$wpX = $pivWork[0] + ($WorkX - $pivWork[0]) * $HardScale
$wpY = $pivWork[1] + ($WorkY - $pivWork[1]) * $HardScale
$bpX = $pivBack[0] + ($BackX - $pivBack[0]) * $HardScale + $LowShiftX
$bpY = $pivBack[1] + ($BackY - $pivBack[1]) * $HardScale
$caraBmp = Open $Cara
# OPEN THE CORD'S TAIL. The owner's file closes its cord with a rounded black cap, and the SVG rope
# that carries on from there is painted BEHIND this layer - so the cap lies across the rope as a
# black line, which is what the owner circled at the backup knot. The working rope never showed it
# because that one is painted in front and buries its own cap under the rope's light core; fixing it
# here fixes both, and at the source, where the shape actually is.
# Everything below the last row that still has light cord in it goes. That is the cap and nothing
# else: the cord is the lowest light thing in the file, the knot's short tail ending well above it.
# The MASK keeps the untouched file - it has to cover what the LOGO drew, cap and all.
$capFrom = -1
for ($y = $caraBmp.Height - 1; $y -ge 0 -and $capFrom -lt 0; $y--) {
  for ($x = 0; $x -lt $caraBmp.Width; $x++) {
    $cc = $caraBmp.GetPixel($x, $y)
    if ($cc.A -le 200) { continue }
    $gc = ([int]$cc.R + [int]$cc.G + [int]$cc.B) / 3
    if ($gc -ge 150 -and $gc -le 235) { $capFrom = $y + 1; break }
  }
}
$nothing = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$capPx = 0
for ($y = $capFrom; $y -lt $caraBmp.Height; $y++) {
  for ($x = 0; $x -lt $caraBmp.Width; $x++) {
    if (($caraBmp.GetPixel($x, $y)).A -eq 0) { continue }
    $caraBmp.SetPixel($x, $y, $nothing); $capPx++
  }
}
"cord tail opened: $capPx px of black cap cleared below row $capFrom"
$work = Place $caraBmp $wpX $wpY ($CaraScale * $HardScale)
$back = Place $caraBmp $bpX $bpY ($CaraScale * $HardScale)
$caraBmp.Dispose()
"carabiner layers built: work=$($work -ne $null) back=$($back -ne $null)"
$hangBmp = Open $Hang

# The hanger's BAR, on its own: in the owner's file it is the leftmost of the white shapes, a long
# diagonal stroke. Found by flooding the light ink and taking the blob whose centre sits furthest
# left; its black outline comes with it by spreading the blob a little and keeping whatever ink
# falls inside.
$HW = $hangBmp.Width; $HH = $hangBmp.Height
$hr = New-Object System.Drawing.Rectangle 0, 0, $HW, $HH
$hd = $hangBmp.LockBits($hr, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$HS = $hd.Stride; $HB = New-Object 'byte[]' ($HS * $HH)
[System.Runtime.InteropServices.Marshal]::Copy($hd.Scan0, $HB, 0, $HB.Length)
$hangBmp.UnlockBits($hd)
$LIGHT = 120
$seenH = New-Object 'bool[]' ($HW * $HH)
$barCells = $null; $barCx = [double]::MaxValue
for ($y = 0; $y -lt $HH; $y++) {
  for ($x = 0; $x -lt $HW; $x++) {
    $i = $y * $HW + $x
    if ($seenH[$i]) { continue }
    $seenH[$i] = $true
    $pp = $y * $HS + $x * 4
    if ($HB[$pp + 3] -le 200) { continue }
    $gv = ([int]$HB[$pp] + [int]$HB[$pp + 1] + [int]$HB[$pp + 2]) / 3
    if ($gv -le $LIGHT) { continue }
    $stk = New-Object System.Collections.Generic.Stack[int]
    $stk.Push($i)
    $cells = New-Object System.Collections.Generic.List[int]
    $sx = 0.0
    while ($stk.Count -gt 0) {
      $j = $stk.Pop(); $jy = [Math]::Floor($j / $HW); $jx = $j - $jy * $HW
      $cells.Add($j); $sx += $jx
      foreach ($dd in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $jx + $dd[0]; $ny = $jy + $dd[1]
        if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $HW -or $ny -ge $HH) { continue }
        $m = $ny * $HW + $nx
        if ($seenH[$m]) { continue }
        $seenH[$m] = $true
        $qq = $ny * $HS + $nx * 4
        if ($HB[$qq + 3] -le 200) { continue }
        $g2 = ([int]$HB[$qq] + [int]$HB[$qq + 1] + [int]$HB[$qq + 2]) / 3
        if ($g2 -le $LIGHT) { continue }
        $stk.Push($m)
      }
    }
    if ($cells.Count -lt 2000) { continue }
    $cx = $sx / $cells.Count
    if ($cx -lt $barCx) { $barCx = $cx; $barCells = $cells }
  }
}
"hanger bar: $($barCells.Count) px of light, centre x $([Math]::Round($barCx))"
$isBar = New-Object 'bool[]' ($HW * $HH)
foreach ($c in $barCells) { $isBar[$c] = $true }
$barMask = New-Object 'bool[]' ($HW * $HH)
$GROW = 16
foreach ($c in $barCells) {
  $cy = [Math]::Floor($c / $HW); $cx2 = $c - $cy * $HW
  for ($dy = -$GROW; $dy -le $GROW; $dy++) {
    $ny = $cy + $dy
    if ($ny -lt 0 -or $ny -ge $HH) { continue }
    for ($dx = -$GROW; $dx -le $GROW; $dx++) {
      $nx = $cx2 + $dx
      if ($nx -lt 0 -or $nx -ge $HW) { continue }
      $barMask[$ny * $HW + $nx] = $true
    }
  }
}
# A BOX AROUND THE BAR IS NOT ENOUGH TO SAY WHICH BLACK IS THE BAR'S. At the bar's top end the box
# reaches into the plate's own pointed corner and took it along - and because this layer is painted
# on top of everything, that corner came back down over the carabiner's ring, which is the broken
# upper anchor the owner circled. The nearest light ink decides instead, the same rule the lettering
# uses further down: one chamfer map to the bar's light ink, one to every other light shape in the
# file, and black that two shapes share splits down the middle between them.
$BIGH = 999999
$dBar = New-Object 'int[]' ($HW * $HH)
$dOth = New-Object 'int[]' ($HW * $HH)
for ($y = 0; $y -lt $HH; $y++) {
  for ($x = 0; $x -lt $HW; $x++) {
    $i = $y * $HW + $x
    $pp = $y * $HS + $x * 4
    $isLit = $false
    if ($HB[$pp + 3] -gt 200) {
      $gv = ([int]$HB[$pp] + [int]$HB[$pp + 1] + [int]$HB[$pp + 2]) / 3
      if ($gv -gt $LIGHT) { $isLit = $true }
    }
    $dBar[$i] = $(if ($isLit -and $isBar[$i]) { 0 } else { $BIGH })
    $dOth[$i] = $(if ($isLit -and -not $isBar[$i]) { 0 } else { $BIGH })
  }
}
foreach ($map in @($dBar, $dOth)) {
  for ($y = 0; $y -lt $HH; $y++) {
    for ($x = 0; $x -lt $HW; $x++) {
      $i = $y * $HW + $x
      $v = $map[$i]
      if ($x -gt 0 -and ($map[$i - 1] + 3) -lt $v) { $v = $map[$i - 1] + 3 }
      if ($y -gt 0) {
        if (($map[$i - $HW] + 3) -lt $v) { $v = $map[$i - $HW] + 3 }
        if ($x -gt 0 -and ($map[$i - $HW - 1] + 4) -lt $v) { $v = $map[$i - $HW - 1] + 4 }
        if ($x -lt $HW - 1 -and ($map[$i - $HW + 1] + 4) -lt $v) { $v = $map[$i - $HW + 1] + 4 }
      }
      $map[$i] = $v
    }
  }
  for ($y = $HH - 1; $y -ge 0; $y--) {
    for ($x = $HW - 1; $x -ge 0; $x--) {
      $i = $y * $HW + $x
      $v = $map[$i]
      if ($x -lt $HW - 1 -and ($map[$i + 1] + 3) -lt $v) { $v = $map[$i + 1] + 3 }
      if ($y -lt $HH - 1) {
        if (($map[$i + $HW] + 3) -lt $v) { $v = $map[$i + $HW] + 3 }
        if ($x -lt $HW - 1 -and ($map[$i + $HW + 1] + 4) -lt $v) { $v = $map[$i + $HW + 1] + 4 }
        if ($x -gt 0 -and ($map[$i + $HW - 1] + 4) -lt $v) { $v = $map[$i + $HW - 1] + 4 }
      }
      $map[$i] = $v
    }
  }
}
$barOnly = New-Object System.Drawing.Bitmap($HW, $HH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$barPx = 0
for ($y = 0; $y -lt $HH; $y++) {
  for ($x = 0; $x -lt $HW; $x++) {
    $i = $y * $HW + $x
    if (-not $barMask[$i]) { continue }
    $pp = $y * $HS + $x * 4
    if ($HB[$pp + 3] -eq 0) { continue }
    if (-not $isBar[$i] -and $dOth[$i] -lt $dBar[$i]) { continue }
    $barOnly.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($HB[$pp + 3], $HB[$pp + 2], $HB[$pp + 1], $HB[$pp]))
    $barPx++
  }
}
"hanger bar layer: $barPx px kept"
$plate = Blank
$gp = [System.Drawing.Graphics]::FromImage($plate)
$hupX = $pivWork[0] + ($HangUpX - $pivWork[0]) * $HardScale
$hupY = $pivWork[1] + ($HangUpY - $pivWork[1]) * $HardScale
$hlpX = $pivBack[0] + ($HangLoX - $pivBack[0]) * $HardScale + $LowShiftX
$hlpY = $pivBack[1] + ($HangLoY - $pivBack[1]) * $HardScale
$hu = Place $hangBmp $hupX $hupY ($HangScale * $HardScale)
$hl = Place $hangBmp $hlpX $hlpY ($HangScale * $HardScale)
$gp.DrawImage($hu, 0, 0); $gp.DrawImage($hl, 0, 0); $gp.Dispose()
$barlow = Place $barOnly $hlpX $hlpY ($HangScale * $HardScale)
$barup = Place $barOnly $hupX $hupY ($HangScale * $HardScale)
$barOnly.Dispose(); $hangBmp.Dispose()
"hardware at {0:P0} of the drawn size, about each hinge" -f $HardScale
"  carabiners at ({0:N0},{1:N0}) and ({2:N0},{3:N0}) x{4:N4}" -f $wpX, $wpY, $bpX, $bpY, ($CaraScale * $HardScale)
"  hangers    at ({0:N0},{1:N0}) and ({2:N0},{3:N0}) x{4:N4}" -f $hupX, $hupY, $hlpX, $hlpY, ($HangScale * $HardScale)
# The HINGES, for index.html and for #caraWork / #caraBack's transform-origin in the CSS. The lower
# one travels with $LowShiftX, because the assembly still turns about its own bolt wherever it is
# put. The STEMS - where each cord ends and the SVG rope takes over - are not guessed here: they are
# measured off the layers this run writes, by scratchpad/stems.ps1. Run it after this.
""
"index.html:"
"  A.pivotWorkX = {0:N4}   A.pivotWorkY = {1:N4}" -f ($pivWork[0] / $bw), ($pivWork[1] / $bh)
"  A.pivotBackX = {0:N4}   A.pivotBackY = {1:N4}   (shifted by $LowShiftX)" -f (($pivBack[0] + $LowShiftX) / $bw), ($pivBack[1] / $bh)
"  then: scratchpad/stems.ps1 for A.stemWork* / A.stemBack*,"
"        A.markLeft = A.desc.x - stemWorkX * markW   (keeps the main rope plumb)"
"        A.backupX  = A.markLeft + stemBackX * markW, and A.camX = A.backupX (keeps the backup plumb)"

# ---- what the placed pieces cover ---------------------------------------------------------------
# Spread by nine: the owner's exports are a hair heavier than the same shapes inside the logo, and
# the drawing carries a soft glow well outside every edge. At three, a faint ghost of each shape
# stayed behind on the lettering layer.
$SPREAD = 9
# What the mask is built from is the hardware AT ITS DRAWN SIZE, not at $HardScale. The mask says
# which of the LOGO's own ink is hardware and has to come out of the lettering layer, and the logo
# was drawn with the hardware full size. Building it from the shrunken copies left the logo's own
# carabiners standing on the lettering layer with the small ones drawn over them - two sets.
$fullCara = Open $Cara
$fullWork = Place $fullCara $WorkX $WorkY $CaraScale
$fullBack = Place $fullCara $BackX $BackY $CaraScale
$fullCara.Dispose()
$fullHang = Open $Hang
$fullHu = Place $fullHang $HangUpX $HangUpY $HangScale
$fullHl = Place $fullHang $HangLoX $HangLoY $HangScale
$fullHang.Dispose()
$covered = New-Object 'bool[]' ($bw * $bh)
foreach ($lay in @($fullWork, $fullBack, $fullHu, $fullHl)) {
  for ($y = 0; $y -lt $bh; $y++) { for ($x = 0; $x -lt $bw; $x++) {
    if (($lay.GetPixel($x, $y)).A -gt 128) { $covered[$y * $bw + $x] = $true } } }
}
$wide = New-Object 'bool[]' ($bw * $bh)
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    if (-not $covered[$y * $bw + $x]) { continue }
    for ($dy = -$SPREAD; $dy -le $SPREAD; $dy++) {
      $ny = $y + $dy
      if ($ny -lt 0 -or $ny -ge $bh) { continue }
      for ($dx = -$SPREAD; $dx -le $SPREAD; $dx++) {
        $nx = $x + $dx
        if ($nx -lt 0 -or $nx -ge $bw) { continue }
        $wide[$ny * $bw + $nx] = $true
      }
    }
  }
}
$hu.Dispose(); $hl.Dispose()
$fullWork.Dispose(); $fullBack.Dispose(); $fullHu.Dispose(); $fullHl.Dispose()

# ---- the lettering: what is left of the logo, with its outline intact ----------------------------
# The owner's separate wordmark file cannot be used as-is: it is drawn with a much heavier outline
# than the same letters carry inside the finished logo, so placed at the right size it reads as a
# different, fatter logotype. So the lettering still comes out of the logo - but nothing of it is
# cut any more.
#
# Whose outline is a black pixel? The nearest light ink decides, and "nearest" means nearest, with
# no radius. Every earlier version asked "is there light ink that stayed within N pixels", and for
# any N it was wrong somewhere: these outlines are ten pixels thick, so at a small N the outer half
# of a letter's own outline found nothing and was given away - which is exactly the thinning the
# owner saw on the "k" and the "r" - and at a large N a hanger claimed arcs of ring that were not
# its own.
# Two distance maps settle it: how far to the nearest ink that LEFT, how far to the nearest ink
# that STAYED. Built by the usual two-pass chamfer, so it costs one sweep down and one back up.
$LIGHTL = 90
# A light blob is only LETTERING if it is big enough to be part of a letter. Inside the hardware the
# placed piece's alpha misses the odd pixel, and those one- and two-pixel islands of light were
# being read as lettering that stayed - after which the "a letter keeps its own outline" rule below
# defended a ten-pixel disc of black around each of them. Three stray pixels inside the upper hanger
# are the whole reason a black hook stood on the lettering layer and came back down over the
# carabiner's ring: the broken anchor the owner circled. The smallest real piece of the wordmark is
# a counter, thousands of pixels across; 400 is nowhere near anything that must survive.
$MINSTAY = 400
$goneBlob = New-Object 'bool[]' ($bw * $bh)
$seenL = New-Object 'bool[]' ($bw * $bh)
$leftPx = 0; $stayPx = 0; $tiny = 0
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    $i = $y * $bw + $x
    if ($seenL[$i]) { continue }
    $seenL[$i] = $true
    $q = ($y + $ly) * $LS + ($x + $lx) * 4
    if ($LB[$q + 3] -le 40) { continue }
    $gv = ([int]$LB[$q] + [int]$LB[$q + 1] + [int]$LB[$q + 2]) / 3
    if ($gv -le $LIGHTL) { continue }
    $stk = New-Object System.Collections.Generic.Stack[int]
    $stk.Push($i)
    $cells = New-Object System.Collections.Generic.List[int]
    $on = 0
    while ($stk.Count -gt 0) {
      $j = $stk.Pop(); $jy = [Math]::Floor($j / $bw); $jx = $j - $jy * $bw
      $cells.Add($j)
      if ($covered[$j]) { $on++ }
      foreach ($dd in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $jx + $dd[0]; $ny = $jy + $dd[1]
        if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $bw -or $ny -ge $bh) { continue }
        $m = $ny * $bw + $nx
        if ($seenL[$m]) { continue }
        $seenL[$m] = $true
        $qq = ($ny + $ly) * $LS + ($nx + $lx) * 4
        if ($LB[$qq + 3] -le 40) { continue }
        $g2 = ([int]$LB[$qq] + [int]$LB[$qq + 1] + [int]$LB[$qq + 2]) / 3
        if ($g2 -le $LIGHTL) { continue }
        $stk.Push($m)
      }
    }
    if (($on / [double]$cells.Count) -ge 0.5 -or $cells.Count -lt $MINSTAY) {
      foreach ($c in $cells) { $goneBlob[$c] = $true }
      $leftPx += $cells.Count
      if ($cells.Count -lt $MINSTAY) { $tiny++ }
    } else { $stayPx += $cells.Count }
  }
}
"light ink: $leftPx px go with the placed pieces, $stayPx px stay (the lettering); $tiny too small to be lettering"

$BIG = 999999
$dGone = New-Object 'int[]' ($bw * $bh)
$dStay = New-Object 'int[]' ($bw * $bh)
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    $i = $y * $bw + $x
    $q = ($y + $ly) * $LS + ($x + $lx) * 4
    $isLight = $false
    if ($LB[$q + 3] -gt 40) {
      $gv = ([int]$LB[$q] + [int]$LB[$q + 1] + [int]$LB[$q + 2]) / 3
      if ($gv -gt $LIGHTL) { $isLight = $true }
    }
    $dGone[$i] = $(if ($isLight -and $goneBlob[$i]) { 0 } else { $BIG })
    $dStay[$i] = $(if ($isLight -and -not $goneBlob[$i]) { 0 } else { $BIG })
  }
}
foreach ($map in @($dGone, $dStay)) {
  for ($y = 0; $y -lt $bh; $y++) {
    for ($x = 0; $x -lt $bw; $x++) {
      $i = $y * $bw + $x
      $v = $map[$i]
      if ($x -gt 0 -and ($map[$i - 1] + 3) -lt $v) { $v = $map[$i - 1] + 3 }
      if ($y -gt 0) {
        if (($map[$i - $bw] + 3) -lt $v) { $v = $map[$i - $bw] + 3 }
        if ($x -gt 0 -and ($map[$i - $bw - 1] + 4) -lt $v) { $v = $map[$i - $bw - 1] + 4 }
        if ($x -lt $bw - 1 -and ($map[$i - $bw + 1] + 4) -lt $v) { $v = $map[$i - $bw + 1] + 4 }
      }
      $map[$i] = $v
    }
  }
  for ($y = $bh - 1; $y -ge 0; $y--) {
    for ($x = $bw - 1; $x -ge 0; $x--) {
      $i = $y * $bw + $x
      $v = $map[$i]
      if ($x -lt $bw - 1 -and ($map[$i + 1] + 3) -lt $v) { $v = $map[$i + 1] + 3 }
      if ($y -lt $bh - 1) {
        if (($map[$i + $bw] + 3) -lt $v) { $v = $map[$i + $bw] + 3 }
        if ($x -lt $bw - 1 -and ($map[$i + $bw + 1] + 4) -lt $v) { $v = $map[$i + $bw + 1] + 4 }
        if ($x -gt 0 -and ($map[$i + $bw - 1] + 4) -lt $v) { $v = $map[$i + $bw - 1] + 4 }
      }
      $map[$i] = $v
    }
  }
}
# A LETTER KEEPS ITS OWN OUTLINE, always. Nearest-ink alone was still not enough: where a ring
# passes close behind the tip of the "r" or the "k", the ring's light ink is genuinely nearer to
# the OUTER half of the letter's outline than the letter's own light ink is, so nearest-ink handed
# those pixels to the carabiner - and the carabiner's drawing has no letter outline to put back.
# That is why the tips kept coming out flattened however the rule was tuned.
# So black within a letter's own outline thickness of the letter stays with the letter, whatever
# else is nearer. Beyond that thickness it is somebody else's and the comparison decides. The
# letters are painted over everything anyway, so keeping a little extra costs nothing; losing any
# of it is what showed.
# 31 is a shade over ten pixels in chamfer units (3 per step), and the lettering''s outline measures
# ten. Twelve was too generous: it also kept two crumbs of ring outline that happened to lie within
# reach of the "r", and because they touched the letter''s outline they were one component with it
# and the speck sweep could not see them either.
$OWNOUTLINE = 31
# The lettering's outline is 13px thick - measured, by walking out from the letters' edges where no
# hardware is near: 13 is the mode of 215 samples (scratchpad bandwidth.ps1). $BAND is that in
# chamfer units.
# Black that sits ON a carabiner and is FURTHER from the lettering than the lettering's own outline
# reaches is the carabiner's, whatever else is nearer. This is the rule that finally takes the two
# nubs beside the "r": they are ring outline welded onto the letter's edge, so they are nearer to
# the letter than to the ring and nearest-ink could never take them - but they stand 21px out from
# the letter's white, and the letter's outline only reaches 13.
# The two nubs, in the 400-wide grid the owner marks on. Inside a box only ink that lies FURTHER
# from the lettering than its own outline reaches is taken - the box says where to look, the
# distance still says what to take. Taking everything in the box was the mistake: the boxes are six
# pixels wide and they straddle the "r"'s outline at its widest.
$nubs = @(@(257, 83, 264, 92), @(257, 119, 264, 128))
$Kx = $bw / 400.0
$rest = Blank
$kept = 0
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    $i = $y * $bw + $x
    $q = ($y + $ly) * $LS + ($x + $lx) * 4
    if ($LB[$q + 3] -eq 0) { continue }
    $gv = ([int]$LB[$q] + [int]$LB[$q + 1] + [int]$LB[$q + 2]) / 3
    if ($gv -gt $LIGHTL) { if ($goneBlob[$i]) { continue } }
    else {
      # Two nubs of ring outline are welded onto the "r"'s edge in the drawing itself, close enough
      # to the letter that no distance rule can tell them apart from its own outline - both were
      # tried, and the one that reached them ate the letters as well. They are four pixels across,
      # they are in one place, and they are listed here. Measured off the layer, not guessed:
      # scratchpad dumped the pixels and they are exactly these columns and rows.
      # If the mark is ever rebuilt from different art, delete this list and look again.
      $nub = $false
      foreach ($nb in $nubs) {
        if ($x -ge $nb[0] * $Kx -and $x -le $nb[2] * $Kx -and $y -ge $nb[1] * $Kx -and $y -le $nb[3] * $Kx) { $nub = $true; break }
      }
      # $wide, not $covered: what was left after taking the solid part was the nub's own
      # antialiasing, a grey hairline in the same place.
      # BUT THE LETTER KEEPS ITS OUTLINE INSIDE THE BOXES TOO. Emptying them outright is what put
      # the two steps in the "r"'s right-hand edge that the owner circled: the distance map says
      # (scratchpad nubcheck.ps1) that nearly every black pixel inside these two boxes is within
      # the letter's own outline thickness of the letter's white - it IS the letter's outline, and
      # deleting it let the carabiner's grey ring show through in its place, which is the "different
      # colour" he saw. The nub proper stands further out than the outline reaches and still goes.
      if ($nub -and $dStay[$i] -gt $OWNOUTLINE -and ($wide[$i] -or $LB[$q + 3] -lt 250)) { continue }
      if ($dGone[$i] -lt $dStay[$i] -and $dStay[$i] -gt $OWNOUTLINE) { continue }
    }
    $rest.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($LB[$q + 3], $LB[$q + 2], $LB[$q + 1], $LB[$q]))
    $kept++
  }
}
"lettering: $kept px"
# ---- sweep up specks -----------------------------------------------------------------------------
# Islands of ink too small to be a letter, sitting where a piece is: crumbs of that piece.
# Big enough to catch a crumb, small enough to leave a hanger's bar. Measured, not guessed: the
# leftovers the owner kept circling come out at 300-400px on this canvas, and the smallest thing
# that must survive - the upper hanger's diagonal bar - is 3180.
$SPECK = [int](1200 * ($bw / 1059.0) * ($bw / 1059.0))
# Only the LETTERING is swept, and the upper bar is laid on afterwards. The hangers and the bar are
# drawn straight from the owner's files - there are no crumbs in them to find - and at 55% the bar
# is about 960px, under the threshold, so anything that sweeps it sweeps it away. It used to survive
# only because a stray black hook was welded to it and the pair together cleared 1200; the moment
# the hook went, so did the bar. Drawing it after the sweep is what actually keeps it, rather than
# an accident keeping it.
# The leading comma keeps this a list OF ONE PAIR. Without it PowerShell flattens the single
# element and the loop runs twice, once over the name and once over the bitmap.
foreach ($swj in @(, @("lettering", $rest))) {
$layS = $swj[1]
$seen2 = New-Object 'bool[]' ($bw * $bh)
$wiped = 0; $islands = 0
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    $i2 = $y * $bw + $x
    if ($seen2[$i2]) { continue }
    $seen2[$i2] = $true
    if (($layS.GetPixel($x, $y)).A -le 20) { continue }
    $stk2 = New-Object System.Collections.Generic.Stack[int]
    $stk2.Push($i2)
    $cells2 = New-Object System.Collections.Generic.List[int]
    $inPiece = 0
    while ($stk2.Count -gt 0) {
      $j2 = $stk2.Pop(); $jy2 = [Math]::Floor($j2 / $bw); $jx2 = $j2 - $jy2 * $bw
      $cells2.Add($j2)
      if ($wide[$j2]) { $inPiece++ }
      for ($dy3 = -1; $dy3 -le 1; $dy3++) {
        for ($dx3 = -1; $dx3 -le 1; $dx3++) {
          $nx2 = $jx2 + $dx3; $ny2 = $jy2 + $dy3
          if ($nx2 -lt 0 -or $ny2 -lt 0 -or $nx2 -ge $bw -or $ny2 -ge $bh) { continue }
          $m2 = $ny2 * $bw + $nx2
          if ($seen2[$m2]) { continue }
          $seen2[$m2] = $true
          if (($layS.GetPixel($nx2, $ny2)).A -gt 20) { $stk2.Push($m2) }
        }
      }
    }
    $n2 = $cells2.Count
    if ($n2 -ge $SPECK) { continue }
    foreach ($c2 in $cells2) {
      $cy2 = [Math]::Floor($c2 / $bw)
      $layS.SetPixel(($c2 - $cy2 * $bw), $cy2, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    }
    $wiped += $n2; $islands++
  }
}
"swept $($swj[0]): $islands island(s), $wiped px"
}
# The UPPER hanger's bar goes on last, after the sweep, because it is smaller than a speck.
$gr = [System.Drawing.Graphics]::FromImage($rest)
$gr.DrawImage($barup, 0, 0)
$gr.Dispose(); $barup.Dispose()

# ---- check ---------------------------------------------------------------------------------------
$flat = Blank
$gf = [System.Drawing.Graphics]::FromImage($flat)
$gf.DrawImage($plate, 0, 0); $gf.DrawImage($back, 0, 0); $gf.DrawImage($barlow, 0, 0)
$gf.DrawImage($work, 0, 0); $gf.DrawImage($rest, 0, 0)
$gf.Dispose()
$miss = 0; $extra = 0
for ($y = 0; $y -lt $bh; $y++) {
  for ($x = 0; $x -lt $bw; $x++) {
    $q = ($y + $ly) * $LS + ($x + $lx) * 4
    $a = $LB[$q + 3] -gt 128
    $b = ($flat.GetPixel($x, $y)).A -gt 128
    if ($a -and -not $b) { $miss++ } elseif ($b -and -not $a) { $extra++ }
  }
}
"stacked vs drawing: $miss px of the drawing missing, $extra px added, of $($bw * $bh)"
$flat.Dispose()

if (-not $DryRun) {
  $outH = [int][Math]::Round($OutW * $bh / $bw)
  foreach ($job in @(@("plate", $plate), @("back", $back), @("barlow", $barlow), @("work", $work), @("rest", $rest))) {
    $small = New-Object System.Drawing.Bitmap($OutW, $outH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g3 = [System.Drawing.Graphics]::FromImage($small)
    $g3.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g3.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g3.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g3.DrawImage($job[1], (New-Object System.Drawing.Rectangle 0, 0, $OutW, $outH), 0, 0, $bw, $bh, [System.Drawing.GraphicsUnit]::Pixel)
    $g3.Dispose()
    $fp = Join-Path $OutDir ("logo-" + $job[0] + ".png")
    $small.Save($fp, [System.Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose()
    "wrote $fp   ($OutW x $outH)"
  }
}
$plate.Dispose(); $rest.Dispose(); $work.Dispose(); $back.Dispose(); $barlow.Dispose(); $logoBmp.Dispose()
