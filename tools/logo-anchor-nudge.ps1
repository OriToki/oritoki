# Slides the LOWER (right-hand) anchor of the lockup sideways, so the two anchors stand the same
# distance from their own letters.
#
# WHY. The mark reads "or" over "tok" with a bolt hanger + locking carabiner + knot standing in for
# each dotted i. Measured on the shipped 400px layers, the gap from the letter to its anchor was
# NOT the same on the two lines:
#     'r' ink ends at x 264, the upper carabiner starts at 275   ->  11 px
#     'k' ink ends at x 322, the lower carabiner starts at 344   ->  22 px
# (Both assemblies have identical internal geometry - the carabiner leads the hanger plate by 8 px
# on each - so the answer is the same whichever edge you measure from.) The owner asked for the
# right anchor to come back left until the two gaps match: -11 px.
#
# THIS IS A TRANSLATION, NOT A REDRAW. Every pixel written out is the pixel that was there, moved a
# whole number of columns - no scaling, no resampling, no repainting. That is the one kind of edit
# the mark tolerates; see CLAUDE.md on why it must never be rebuilt.
#
# THE LOWER ANCHOR LIVES IN THREE FILES, so all three move together or it comes apart:
#   logo-back.png    the carabiner, its knot and the cord   (ink x 344..388, y 224..350)
#   logo-barlow.png  the bar under the lower hanger         (ink x 353..365, y 212..244)
#   logo-plate.png   BOTH hanger plates - only the lower blob may move (y 205..244; the upper
#                    one is y 26..65, so any split between them works)
# The lettering (logo-rest.png) is not touched: the letters are not moving, the anchor is.
#
# AFTERWARDS, three things have to follow or the rope leaves the knot at an angle:
#   - A.stemBackX and A.pivotBackX in index.html come down by Shift/400
#   - #caraBack's transform-origin in the CSS matches A.pivotBack
#   - the man moves with the rope (see A.markLeft), because the right stem now carries the WORKING
#     rope and it has to stay plumb into his descender
# The script prints all of them.
#
# It also prints the new seed for tools/logo-bolt.ps1, whose lower logo-plate seed (373,215) is a
# coordinate inside the hexagon and travels with it.
param(
  [string]$Dir = (Resolve-Path (Join-Path $PSScriptRoot "..\images")).Path,
  [int]$Shift = 11,              # pixels LEFT, on the 400px canvas
  [int]$PlateSplitY = 150,       # rows below this in logo-plate.png belong to the lower anchor
  [switch]$WhatIf
)
Add-Type -AssemblyName System.Drawing

# file, and the first row whose ink may move (0 = the whole file)
$jobs = @(
  @{ file = "logo-back.png";   fromY = 0 },
  @{ file = "logo-barlow.png"; fromY = 0 },
  @{ file = "logo-plate.png";  fromY = $PlateSplitY }
)

function InkBox($bm, $y0, $y1) {
  $x0 = $bm.Width; $x1 = -1; $t0 = $bm.Height; $t1 = -1; $n = 0
  for ($y = $y0; $y -le $y1; $y++) {
    for ($x = 0; $x -lt $bm.Width; $x++) {
      if ($bm.GetPixel($x, $y).A -le 0) { continue }
      $n++
      if ($x -lt $x0) { $x0 = $x }; if ($x -gt $x1) { $x1 = $x }
      if ($y -lt $t0) { $t0 = $y }; if ($y -gt $t1) { $t1 = $y }
    }
  }
  return @{ x0 = $x0; x1 = $x1; y0 = $t0; y1 = $t1; n = $n }
}

"nudging the lower anchor $Shift px LEFT on a 400px canvas`n"
$fail = $false
foreach ($job in $jobs) {
  $path = Join-Path $Dir $job.file
  $src = New-Object System.Drawing.Bitmap($path)
  $W = $src.Width; $H = $src.Height
  $splitY = $job.fromY
  $before = InkBox $src $splitY ($H - 1)
  if ($before.x1 -lt 0) { "  $($job.file): no ink below row $splitY - nothing to move"; $src.Dispose(); continue }
  if ($before.x0 - $Shift -lt 0) {
    "  $($job.file): *** $Shift px would run off the left edge (ink starts at $($before.x0)) ***"
    $src.Dispose(); $fail = $true; continue
  }
  # the part that stays, plus the part that moves - copied pixel for pixel
  $out = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
      $p = $src.GetPixel($x, $y)
      if ($p.A -eq 0) { continue }
      if ($y -lt $splitY) { $out.SetPixel($x, $y, $p) }          # stays put
      else { $out.SetPixel($x - $Shift, $y, $p) }                # travels
    }
  }
  $after = InkBox $out $splitY ($H - 1)
  $okCount = ($after.n -eq $before.n)
  $okMove  = ($after.x0 -eq $before.x0 - $Shift -and $after.x1 -eq $before.x1 - $Shift -and
              $after.y0 -eq $before.y0 -and $after.y1 -eq $before.y1)
  "  {0,-17} x {1,3}..{2,3} -> {3,3}..{4,3}   y {5,3}..{6,3}   {7} px   {8}" -f `
    $job.file, $before.x0, $before.x1, $after.x0, $after.x1, $after.y0, $after.y1, $after.n,
    $(if ($okCount -and $okMove) { "OK" } else { "*** MOVED WRONG - NOT WRITTEN ***" })
  if (-not ($okCount -and $okMove)) { $fail = $true; $out.Dispose(); $src.Dispose(); continue }
  $src.Dispose()
  if (-not $WhatIf) { $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png) }
  $out.Dispose()
}
if ($fail) { "`n*** something did not move cleanly - do not ship ***"; return }
if ($WhatIf) { "`n-WhatIf: nothing written" }

# --- what has to follow ---------------------------------------------------------------------
$f = $Shift / 400.0
"`n--- keep these in step (Shift/400 = {0:N5} of the mark) ---" -f $f
"  A.stemBackX   0.91213 -> {0:N5}" -f (0.91213 - $f)
"  A.pivotBackX  0.90780 -> {0:N5}   (and #caraBack transform-origin {1:N2}%)" -f (0.9078 - $f), ((0.9078 - $f) * 100)
$markW = 0.5531
$dStrip = $f * $markW
"  the right rope moves LEFT by {0:N5} of the strip = {1:N3} px at a 150px strip" -f $dStrip, ($dStrip * 150)
"  so, to keep it plumb into the descender and leave the mark where it is:"
"    --climber-left  47.34 -> {0:N2} px   (mobile 18.61 -> {1:N2} px)" -f (47.34 - $dStrip * 150), (18.61 - $dStrip * 111)
"    A.markLeft   -0.03927 -> {0:N5}" -f (-0.03927 + $dStrip)
"    A.backupX / A.camX / A.asapIn.x / A.asapOut.x   0.3711 -> {0:N4}" -f (0.3711 + $dStrip)
$sepOld = (0.91213 - 0.73935) * $markW
$sepNew = (0.91213 - $f - 0.73935) * $markW
"  rope separation {0:N5} -> {1:N5} of the strip  (climber-compose.ps1 -Sep; {2:N1} shipped px)" -f $sepOld, $sepNew, ($sepNew * 760)
"  tools/logo-bolt.ps1: logo-plate.png lower seed (373,215) -> ({0},215)" -f (373 - $Shift)
"  bump the ?v= on logo-plate / logo-back / logo-barlow in index.html"
