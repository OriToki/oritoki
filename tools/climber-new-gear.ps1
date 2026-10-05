# Puts the owner's NEW back-up gear (absorber + ASAP) on the shipped figure, and touches nothing
# else of the man (his ask: "do not touch the man at all, fit only the absorber and the ASAP").
#
# Sources, all on the Desktop and all in the MAN's own pixels (Perfect 1.png, 1254 x 1254; the two
# gear files are on a 1492-wide canvas that starts at the same origin - measured, offset 0,0):
#   Perfect 1.png                    the man with no back-up gear (the base the site was built from)
#   perfect worker. no absorber.png  despite the name: the ABSORBER alone, where it hangs on him
#   asap.png                         the ASAP alone
#
# How the shipped body relates to the man was FITTED, not assumed: frame 1052 man-px wide, left
# 120.2, top 31.8 (rms 4.3 lightness levels on the legs - resampling only). Rendering Perfect 1
# through that frame reproduces man-body.png everywhere except the old gear, so the edit is local:
# inside the old gear's footprint and the new gear's, the body becomes the new render; every other
# pixel of man-body.png is kept as it is. man-rig.png and man-glove.png are not touched - his
# descender fist is in the glove layer, so the absorber's tail runs in UNDER the hand by itself.
#
# Placement (the owner's calls): the absorber's tip goes into the ASAP's lower-left NOTCH, as in
# "perfect worker. asapnairit.png"; the back-up rope runs BEHIND the plate, on the plate's centre
# line (the line through its top and bottom holes). The absorber turns about its tail - the point
# where it disappears under the fist - until the plate's centre line is on the plumb back-up rope.
# The ASAP itself is not turned: it stays upright on its rope.
# REVISED (the owner): the absorber's lower end is CLIPPED TO HIS CHEST RING, not left under the fist.
# So its tail is moved onto the ring's centre and the ring is drawn back over it, which reads as the
# absorber coming up out of the ring; it is then turned about that point until its tip meets the
# ASAP's notch. And the ASAP sits a little RIGHT of the rope ($AsapRight): the rope line is fixed by
# the header mark, so this puts the rope behind the left part of the plate rather than its middle.
param(
  [double]$RingX = 550, [double]$RingY = 447, [double]$RingR = 23,   # his chest (sternal) ring, man px
  [double]$AsapRight = 2,                           # plate centre this far right of the rope, man px -
                                                    # read off the owner's green marks for where the
                                                    # rope goes in and out (12 before that)
  [double]$TailX = 667, [double]$TailY = 436,       # absorber: the lower end of its drawn part
  [double]$TipX = 832,  [double]$TipY = 166,        # absorber: the end of its top pin
  [double]$NotchX = 780, [double]$NotchY = 166,     # ASAP: where the pin goes in (the closed hole in the
                                                    # owner's refined asap.png; the open notch was at 782)
  [string]$BaseBody = "",                           # the body to edit; default: man-body.png as in commit
                                                    # 4cebf7d (the old gear), so a re-run starts clean and the
                                                    # live file never shows the old gear in between
  [double]$PlateX = 796,                            # ASAP: centre line of its holes = the rope line
  [double]$RopeX = 697.3,                           # the plumb back-up rope, man px (A.asapIn.x 0.5486)
  [double]$FW = 1052.0, [double]$Left = 120.2, [double]$Top = 31.8,
  [switch]$Ship,                                    # write images\man-body.png (else a preview only)
  [string]$Out = ""
)
Add-Type -AssemblyName System.Drawing
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$D = "C:\Users\gilmo\OneDrive\Desktop"
function Load($p) { $b = New-Object System.Drawing.Bitmap $p; $c = New-Object System.Drawing.Bitmap $b.Width, $b.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($c); $g.DrawImage($b, 0, 0, $b.Width, $b.Height); $g.Dispose(); $b.Dispose(); $c }

# ---- solve the turn: keep the tail-to-tip length, put the notch where the plate line meets the rope
$vx = $TipX - $TailX; $vy = $TipY - $TailY; $len = [Math]::Sqrt($vx * $vx + $vy * $vy)
$tx = $RopeX + $AsapRight - ($PlateX - $NotchX)          # where the tip has to end up, in x
$ty = $RingY - [Math]::Sqrt($len * $len - ($tx - $RingX) * ($tx - $RingX))
$rot = ([Math]::Atan2($ty - $RingY, $tx - $RingX) - [Math]::Atan2($vy, $vx)) * 180 / [Math]::PI
$ax = $tx - $NotchX; $ay = $ty - $NotchY                  # how far the ASAP moves
"absorber: tail on the chest ring ({0},{1}), turned {2:N1} deg; tip now ({3:N1},{4:N1}); ASAP moved ({5:N1},{6:N1}), plate {7} px right of the rope" -f $RingX, $RingY, $rot, $tx, $ty, $ax, $ay, $AsapRight

# ---- the new gear alone, in man px, on a canvas wide enough for the gear files
$abs = Load "$D\perfect worker. no absorber.png"; $asp = Load "$D\asap.png"; $man = Load "$D\Perfect 1.png"
$CW = [Math]::Max($abs.Width, $man.Width); $CH = $man.Height
$gear = New-Object System.Drawing.Bitmap $CW, $CH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($gear)
$g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.SmoothingMode = 'AntiAlias'
# The ASAP first and the absorber OVER it - the owner: the absorber shows in front of the ASAP, its pin
# going into the notch from the front.
$g.DrawImage($asp, [single]$ax, [single]$ay, [single]$asp.Width, [single]$asp.Height)
# tail onto the ring's centre, turned about it
$g.TranslateTransform([single]$RingX, [single]$RingY); $g.RotateTransform([single]$rot); $g.TranslateTransform([single](-$TailX), [single](-$TailY))
$g.DrawImage($abs, 0, 0, $abs.Width, $abs.Height); $g.ResetTransform()
$g.Dispose()
# man + gear, then his chest ring back OVER the absorber's end, so it comes up out of the ring
$ring = New-Object System.Drawing.Drawing2D.GraphicsPath
$ring.AddEllipse([single]($RingX - $RingR), [single]($RingY - $RingR), [single](2 * $RingR), [single](2 * $RingR))
$comp = New-Object System.Drawing.Bitmap $CW, $CH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($comp); $g.DrawImage($man, 0, 0, $man.Width, $man.Height); $g.DrawImage($gear, 0, 0, $CW, $CH)
$g.SetClip($ring); $g.DrawImage($man, 0, 0, $man.Width, $man.Height); $g.ResetClip(); $g.Dispose()
$abs.Dispose(); $asp.Dispose()

# ---- into the shipped frame, the way climber-assemble.ps1 shrinks
if (-not $BaseBody) {
  $git = Get-ChildItem "$env:LOCALAPPDATA\GitHubDesktop\app-*\resources\app\git\cmd\git.exe" | Select-Object -Last 1 -ExpandProperty FullName
  $BaseBody = Join-Path $env:TEMP "man-body-base.png"
  Push-Location $REPO; cmd /c "`"$git`" show 4cebf7d:images/man-body.png > `"$BaseBody`""; Pop-Location
}
$body = Load $BaseBody; $SW = $body.Width; $SH = $body.Height; $FH = $FW * $SH / $SW
function Shrink($src) { $o = New-Object System.Drawing.Bitmap $SW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gs = [System.Drawing.Graphics]::FromImage($o); $gs.InterpolationMode = 'HighQualityBicubic'; $gs.PixelOffsetMode = 'HighQuality'
  $gs.DrawImage($src, (New-Object System.Drawing.RectangleF 0, 0, $SW, $SH), (New-Object System.Drawing.RectangleF ([single]$Left), ([single]$Top), ([single]$FW), ([single]$FH)), [System.Drawing.GraphicsUnit]::Pixel)
  $gs.Dispose(); $o }
$newS = Shrink $comp; $gearS = Shrink $gear; $bareS = Shrink $man
$man.Dispose(); $comp.Dispose(); $gear.Dispose()

# ---- the region to replace: the old gear (body differs from the bare man, inside the gear's corner
# of the frame - outside it the only differences are 1-px resampling specks on the outline) and the
# new gear, each grown by 2 px
$mask = New-Object 'bool[,]' $SW, $SH
$GX0 = 290; $GX1 = 480; $GY0 = 20; $GY1 = 320
for ($y = 0; $y -lt $SH; $y++) { for ($x = 0; $x -lt $SW; $x++) {
  $hit = $false
  if ($gearS.GetPixel($x, $y).A -gt 8) { $hit = $true }
  elseif ($x -ge $GX0 -and $x -le $GX1 -and $y -ge $GY0 -and $y -le $GY1) {
    $a = $body.GetPixel($x, $y); $q = $bareS.GetPixel($x, $y)
    $la = $a.A * ($a.R + $a.G + $a.B) / 765.0; $lq = $q.A * ($q.R + $q.G + $q.B) / 765.0
    if (([Math]::Abs($la - $lq) + [Math]::Abs($a.A - $q.A) * 0.5) -gt 30) { $hit = $true } }
  if ($hit) { for ($j = -2; $j -le 2; $j++) { for ($i = -2; $i -le 2; $i++) {
    $xx = $x + $i; $yy = $y + $j; if ($xx -ge 0 -and $yy -ge 0 -and $xx -lt $SW -and $yy -lt $SH) { $mask[$xx, $yy] = $true } } } } } }
$res = New-Object System.Drawing.Bitmap $body
$n = 0
for ($y = 0; $y -lt $SH; $y++) { for ($x = 0; $x -lt $SW; $x++) { if ($mask[$x, $y]) { $res.SetPixel($x, $y, $newS.GetPixel($x, $y)); $n++ } } }
"replaced $n of $($SW * $SH) body pixels (old gear out, new gear in)"

# ---- figures for index.html's A table: where the rope meets the plate, as fractions of the frame
$rx = ($RopeX - $Left) / $FW                        # the rope's x - unchanged; only the plate moved
$asTop = $ay + 99; $asBot = $ay + 193                  # asap.png's ink runs y 99..193
"A.asapIn  = {{ x: {0:N4}, y: {1:N4} }}   (top of the plate)" -f $rx, (($asTop - $Top) / $FH)
"A.asapOut = {{ x: {0:N4}, y: {1:N4} }}   (bottom of the plate)  = A.camY" -f $rx, (($asBot - $Top) / $FH)

if (-not $Out) { $Out = Join-Path $env:TEMP "climber-new-gear-preview.png" }
if ($Ship) { $res.Save("$REPO\images\man-body.png", [System.Drawing.Imaging.ImageFormat]::Png); "written images\man-body.png" }
else { $res.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); "preview: $Out" }
$res.Dispose(); $body.Dispose(); $newS.Dispose(); $gearS.Dispose(); $bareS.Dispose()
