# Replaces the technician's backup device with the owner's own ASAP + ASAP'SORBER drawing.
#
# What was there: a rigging plate, a swivel and a short black absorber, hanging beside his head on
# transparent background and joined to his chest by a thin strap. The owner's objection was both
# ways round - it did not read as any particular device, and structurally it was not what an ASAP
# rig is.
#
# The drawing is Desktop\ASAP.png: line art, greyscale, transparent background, already in the
# technician's own style, carabiners included. Nothing here restyles it. Two earlier attempts are
# worth remembering: one built the device out of polygons and came out as a round pulley, the other
# traced the reference PHOTOGRAPH and came out grainy. The owner then drew it, and that is the third
# time on this site that his own drawing was the answer - the same lesson as the header lockup.
#
# It is drawn INTO climber.png rather than added as a layer, and that is the whole trick: the device
# then sits exactly where it has to sit - in front of him, behind the working rope, moving and
# leaning with him - without a single line of layering code. The backup rope is painted behind him,
# so it passes behind the ASAP's body and shows again above and below it, which is what a rope
# through a fall arrester looks like.
#
# PLACED BY TWO POINTS, not posed: the ASAP's rope channel goes on the rope, the lower carabiner
# goes on his sternal ring, and the scale and the angle fall out of that. The rig therefore tilts a
# little off vertical - which is what a fall arrester does when its lanyard is loaded sideways.
#
# Idempotent: it always starts from $Pristine, the copy taken before the first run.
#
# PowerShell note: GDI+ objects are built with ::new(), and never as
# `New-Object System.Drawing.PointF ($x), ($y)` - the comma binds first and the constructor gets one
# array. And a local must not share a name with a [string] parameter: $photo next to [string]$Photo
# silently coerced a bitmap to the text "System.Drawing.Bitmap" and every draw failed.
param(
  [string]$Repo = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki",
  [string]$Pristine = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad\climber-before-asap.png",
  [string]$Rig = "C:\Users\gilmo\OneDrive\Desktop\ASAP 2.png",
  # The band holding the old plate, swivel and absorber. Every opaque pixel in it is device - the
  # script checks the band's left edge for his ink before clearing, and stops if it finds any.
  [int]$ClearX0 = 243, [int]$ClearY0 = 48, [int]$ClearX1 = 332, [int]$ClearY1 = 183,
  # The two anchors in the DRAWING's own pixels (1086 x 1516), read off it on a grid.
  [double]$RigChanX = 825, [double]$RigChanY = 196,    # the ASAP's rope channel - the owner marked
                                                     # where the rope enters and leaves it, on a
                                                     # grid of the live page, and this is that line
  # The lanyard's own lower connector, the screw-lock at the end - its tip is what clips into his
  # sternal ring, so that is the point that has to land there.
  [double]$RigClipX = 170, [double]$RigClipY = 1330,
  # ...and where those two go in climber.png's own 560 x 686 pixels.
  # Where the rope enters and leaves the ASAP, down the drawing's channel line at $RigChanX. The
  # owner marked both on a grid of the live page; these are the drawing rows they land on.
  # Measured on the live page: this is where the device's own silhouette starts and stops across
  # the rope's line, which is what "the rope goes in here and comes out there" means.
  [double]$ChanTopY = 68, [double]$ChanBotY = 345,
  [double]$RopeX = 316, [double]$ChanY = 84,           # keep in step with A.camX / A.camY
  [double]$PunktX = 214, [double]$PunktY = 238,        # the sternal ring
  # Putting the contours back after the shrink. 1.1 / 1.45 is enough to read as line art again
  # without the halo that a heavier unsharp leaves around every edge.
  [double]$Sharpen = 1.1, [double]$Contrast = 1.45,
  [switch]$KeepOld
)
Add-Type -AssemblyName System.Drawing

function Open2($p) {
  $fs = [System.IO.File]::OpenRead($p); $im = [System.Drawing.Image]::FromStream($fs)
  $b = New-Object System.Drawing.Bitmap($im); $im.Dispose(); $fs.Close(); $fs.Dispose(); return $b
}

$dst = Join-Path $Repo "images\climber.png"
if (-not (Test-Path $Pristine)) { throw "no pristine copy at $Pristine - refusing to draw on top of a drawing" }
$base = Open2 $Pristine
$W = $base.Width; $H = $base.Height
"pristine $W x $H"
if (-not $KeepOld) {
  $touch = 0
  for ($y = $ClearY0; $y -le $ClearY1; $y++) { if (($base.GetPixel($ClearX0, $y)).A -gt 20) { $touch++ } }
  if ($touch -gt 0) { throw "the clear band's left edge cuts ink on $touch row(s) - move ClearX0 right" }
  "clear band $ClearX0..$ClearX1 x $ClearY0..$ClearY1 : left edge clean"
}
$out = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($out)
$g.DrawImage($base, 0, 0, $W, $H)
if (-not $KeepOld) {
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
  $g.FillRectangle(([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 0, 0, 0))),
                   $ClearX0, $ClearY0, ($ClearX1 - $ClearX0 + 1), ($ClearY1 - $ClearY0 + 1))
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
}
$base.Dispose()
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

# ---- the rig, painted INTO him ---------------------------------------------------------------
# Rigid, on the owner's instruction, and that is the simple way round: part of climber.png, so it
# is in front of him, behind the working rope, and moves and leans with him, with no layering and
# no per-frame code at all. The backup rope is painted behind him, so it passes behind the ASAP's
# body and shows again above and below it - a rope through a fall arrester.
# It was a hinged pair of layers for a while, so the absorber could swing on his chest and the
# device ride the rope. That worked, and the owner then asked for it rigid; the hinge is gone from
# index.html and the two emitted halves are deleted.
#
# PLACED BY TWO POINTS, not posed: the ASAP's rope channel onto the rope, the lower carabiner onto
# his sternal ring. The scale and the angle fall out of those, so the only way to move it is to
# move an anchor - there is nothing here to nudge by eye.
$rigBmp = Open2 $Rig
"rig $($rigBmp.Width) x $($rigBmp.Height)"
$rdx = $RigClipX - $RigChanX; $rdy = $RigClipY - $RigChanY
$rlen = [Math]::Sqrt($rdx * $rdx + $rdy * $rdy)
$tdx = $PunktX - $RopeX; $tdy = $PunktY - $ChanY
$tlen = [Math]::Sqrt($tdx * $tdx + $tdy * $tdy)
$scale = $tlen / $rlen
$rot = ([Math]::Atan2($tdy, $tdx) - [Math]::Atan2($rdy, $rdx)) * 180 / [Math]::PI
"reach {0:N0} drawing px -> {1:N0} climber px   scale {2:N4}   turn {3:N1} deg" -f $rlen, $tlen, $scale, $rot
# Onto its OWN layer first, so it can be sharpened before it joins him. Shrinking line art by seven
# is what made the device look out of focus: a black line one pixel wide averages with the white
# either side of it and comes out mid-grey, so the drawing loses exactly the contours it is made of.
# Nothing in the placement can fix that - the answer is to put the contrast back afterwards, on the
# rig alone, which is why it cannot be drawn straight onto him.
$lay = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gl = [System.Drawing.Graphics]::FromImage($lay)
$gl.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gl.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gl.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gl.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$gl.TranslateTransform([single]$RopeX, [single]$ChanY)
$gl.RotateTransform([single]$rot)
$gl.ScaleTransform([single]$scale, [single]$scale)
$gl.TranslateTransform([single](-$RigChanX), [single](-$RigChanY))
$gl.DrawImage($rigBmp, 0, 0, $rigBmp.Width, $rigBmp.Height)
$gl.Dispose()
$rigBmp.Dispose()

# Unsharp mask, then a contrast curve about mid-grey. Only the rig's own box is touched, and only
# pixels it actually painted - his artwork is not in this layer at all, so it cannot be affected.
$bx0 = $W; $bx1 = -1; $by0 = $H; $by1 = -1
for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) {
  if (($lay.GetPixel($x, $y)).A -le 8) { continue }
  if ($x -lt $bx0) { $bx0 = $x }; if ($x -gt $bx1) { $bx1 = $x }
  if ($y -lt $by0) { $by0 = $y }; if ($y -gt $by1) { $by1 = $y } } }
$bx0 = [Math]::Max(0, $bx0 - 2); $by0 = [Math]::Max(0, $by0 - 2)
$bx1 = [Math]::Min($W - 1, $bx1 + 2); $by1 = [Math]::Min($H - 1, $by1 + 2)
$bw2 = $bx1 - $bx0 + 1; $bh2 = $by1 - $by0 + 1
"rig box on the canvas: $bx0..$bx1 x $by0..$by1  ($bw2 x $bh2)"
$lum = New-Object 'double[]' ($bw2 * $bh2)
$alp = New-Object 'int[]' ($bw2 * $bh2)
for ($y = 0; $y -lt $bh2; $y++) { for ($x = 0; $x -lt $bw2; $x++) {
  $c = $lay.GetPixel($x + $bx0, $y + $by0)
  $lum[$y * $bw2 + $x] = 0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B
  $alp[$y * $bw2 + $x] = $c.A } }
$blur = New-Object 'double[]' ($bw2 * $bh2)
for ($y = 0; $y -lt $bh2; $y++) { for ($x = 0; $x -lt $bw2; $x++) {
  $s = 0.0; $n = 0
  for ($dy = -1; $dy -le 1; $dy++) { $ny = $y + $dy
    if ($ny -lt 0 -or $ny -ge $bh2) { continue }
    for ($dx = -1; $dx -le 1; $dx++) { $nx = $x + $dx
      if ($nx -lt 0 -or $nx -ge $bw2) { continue }
      $s += $lum[$ny * $bw2 + $nx]; $n++ } }
  $blur[$y * $bw2 + $x] = $s / $n } }
for ($y = 0; $y -lt $bh2; $y++) { for ($x = 0; $x -lt $bw2; $x++) {
  $i = $y * $bw2 + $x
  if ($alp[$i] -le 8) { continue }
  $v = $lum[$i] + $Sharpen * ($lum[$i] - $blur[$i])          # unsharp
  $v = ($v - 128) * $Contrast + 128                           # ...and harder blacks and whites
  if ($v -lt 0) { $v = 0 } elseif ($v -gt 255) { $v = 255 }
  $k = [int][Math]::Round($v)
  $lay.SetPixel(($x + $bx0), ($y + $by0), [System.Drawing.Color]::FromArgb($alp[$i], $k, $k, $k)) } }
$g.DrawImage($lay, 0, 0)
$lay.Dispose()
$g.ResetTransform()
$g.Dispose()

# ---- where the rope enters and leaves the device -------------------------------------------------
# The owner marked these two on a grid of the live page: the rope does not simply bend AT the ASAP,
# it is held by it, so it bends TWICE - once going in at the top and once coming out at the bottom -
# and runs straight along the device's own channel in between. The device sits a few degrees off
# vertical, so that middle stretch is off vertical too, which is the whole point of having two.
# They are the channel line's two ends carried through the same placement as the drawing, so they
# cannot drift away from it: move an anchor and these follow.
$rad = $rot * [Math]::PI / 180; $cs = [Math]::Cos($rad); $sn = [Math]::Sin($rad)
""
"index.html:"
foreach ($e in @(@("asapIn ", $ChanTopY), @("asapOut", $ChanBotY))) {
  $dx = 0.0; $dy = $e[1] - $RigChanY
  $ex = $RopeX + ($dx * $cs - $dy * $sn) * $scale
  $ey = $ChanY + ($dx * $sn + $dy * $cs) * $scale
  "  {0}: {{ x: {1:N4}, y: {2:N4} }},   // = ({3:N1},{4:N1}) of 560x686" -f $e[0], ($ex / $W), ($ey / $H), $ex, $ey
}
$out.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
"wrote $dst"
"  rope channel ({0},{1}) -> A.camX = {2:N4}  A.camY = {3:N4}" -f $RopeX, $ChanY, ($RopeX / $W), ($ChanY / $H)
