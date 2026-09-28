# Turns the four cut pieces from climber-layers.ps1 into the THREE layers the page ships,
# and paints the three devices onto the middle one.
#
#   climber-body.png    (from climber-layers.ps1, unchanged)  under the ropes
#   climber-gear.png    RIG + ASAP'SORBER + ASAP LOCK         over the ropes
#   climber-front.png   head + both fists                     over the devices
#
# All three are the SAME 800x800 canvas as the body, so the page stacks them at one position
# with one transform and there is nothing to line up. That is the whole reason the devices are
# painted into a layer instead of being separate positioned elements: a device that is just
# another 800x800 image needs no placement maths in the page at all.
#
# It also replaces the clip-path machinery the ropes used to need. The old climber was one flat
# PNG, so "the device's outline passes in front of the rope" had to be faked by CUTTING the rope
# along that outline (applyCut, CUT_ALONG, CUT_DEEP, cutWork, cutBrake, cutDescOut, descTuck).
# With the devices in a layer ABOVE the ropes they simply cover them, and all of that goes.
#
# SIZES ARE MILLIMETRES, not taste. 0.62 px/mm on this canvas, confirmed three independent ways:
# helmeted head 175px/280mm, boot 185px/300mm, and the drawn harness rings measuring 76mm and
# 55mm, which are the real ASTRO ventral and sternal sizes. The owner has twice said a device
# looked too big for the man; this is the answer to that.
#
# PowerShell traps this file is written around, all of which bit during the build:
#  - $x and $X are ONE variable, so loop counters are $ix / $iy.
#  - a Bitmap assigned to a variable declared [string] in param() is silently coerced to the
#    text "System.Drawing.Bitmap", so the source bitmap is $img and never $Src.
#  - [string]$job[1] parses as ([string]$job)[1]; casts of an element need their own parens.
#  - Windows PowerShell 5.1 reads a .ps1 as ANSI unless it has a BOM, so no non-ASCII path may
#    appear here - hence the ASCII *-src.png copies of the owner's files.
param(
  # NOT $Gear: $gear would be the same variable and the gear Bitmap assigned to it would be
  # silently turned back into the text "System.Drawing.Bitmap". Yes, this is the trap the
  # header warns about, walked into while writing the file that warns about it.
  [string]$SrcDir = "C:\Users\gilmo\OneDrive\Desktop\new man",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [double]$PXMM = 0.62,
  # device, file, millimetres, rotation, anchor-x, anchor-y (fractions of its own ink box),
  # target x, target y (in the 800px figure's own pixels)
  [double]$RigMM = 180,  [double]$RigRot = 40,   [double]$RigAX = 0.62,  [double]$RigAY = 0.96,
  [int]$RigX = 314,      [int]$RigY = 373,
  [double]$SorbMM = 420, [double]$SorbRot = -4.7, [double]$SorbAX = 0.12, [double]$SorbAY = 0.93,
  [int]$SorbX = 273,     [int]$SorbY = 300,
  [double]$AsapMM = 160, [double]$AsapRot = 0,   [double]$AsapAX = 0.95, [double]$AsapAY = 0.75,
  [int]$AsapX = 451,     [int]$AsapY = 85
)
Add-Type -AssemblyName System.Drawing

function InkBox($bmp) {
  $x0 = $bmp.Width; $x1 = -1; $y0 = $bmp.Height; $y1 = -1
  for ($iy = 0; $iy -lt $bmp.Height; $iy++) {
    for ($ix = 0; $ix -lt $bmp.Width; $ix++) {
      if ($bmp.GetPixel($ix, $iy).A -lt 24) { continue }
      if ($ix -lt $x0) { $x0 = $ix }; if ($ix -gt $x1) { $x1 = $ix }
      if ($iy -lt $y0) { $y0 = $iy }; if ($iy -gt $y1) { $y1 = $iy }
    }
  }
  return @($x0, $y0, $x1, $y1)
}

# --- climber-front.png: head and both fists, merged ----------------------------------------
# They all sit at the same depth - above the ropes and above the devices - so there is no
# reason to ship three files and three <img> tags for them.
$W = 800
$front = New-Object System.Drawing.Bitmap $W, $W, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gf = [System.Drawing.Graphics]::FromImage($front)
foreach ($n in @("hand-l", "hand-u", "head")) {
  $p = Join-Path $OutDir "climber-$n.png"
  if (-not (Test-Path $p)) { throw "missing $p - run tools/climber-layers.ps1 first" }
  $b = New-Object System.Drawing.Bitmap($p)
  $gf.DrawImageUnscaled($b, 0, 0); $b.Dispose()
}
$gf.Dispose()
$front.Save((Join-Path $OutDir "climber-front.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$front.Dispose()

# --- climber-gear.png: the three devices ---------------------------------------------------
$gear = New-Object System.Drawing.Bitmap $W, $W, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($gear)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# The RIG is NOT flipped. Its drawing already has the body above the carabiner, which is the
# ventral layout: ring -> carabiner -> the RIG's lower hole -> body pointing up at the rope.
# Rotating it 180 to "put the carabiner on top" turns the whole device upside down and stands
# the handle on end - that went unnoticed for a while because at 112px it is just a grey blob.
# The 40 degrees is a forward SWING about the ventral ring: the owner asked for the silhouette
# to come clear of the thigh and the harness, and a loaded descender really is pulled forward.
$jobs = @(
  @("rig-src.png",    $RigMM,  $RigRot,  $RigAX,  $RigAY,  $RigX,  $RigY),
  @("sorber-src.png", $SorbMM, $SorbRot, $SorbAX, $SorbAY, $SorbX, $SorbY),
  @("asap-src.png",   $AsapMM, $AsapRot, $AsapAX, $AsapAY, $AsapX, $AsapY)
)
$rows = @()
foreach ($job in $jobs) {
  $p = Join-Path $SrcDir ([string]($job[0]))
  if (-not (Test-Path $p)) { throw "missing $p" }
  $b = New-Object System.Drawing.Bitmap($p)
  $bx = InkBox $b
  $iw = $bx[2] - $bx[0]; $ih = $bx[3] - $bx[1]
  $long = [Math]::Max($iw, $ih)
  $k = ([double]($job[1]) * $PXMM) / $long
  $sx = $bx[0] + $iw * [double]($job[3])
  $sy = $bx[1] + $ih * [double]($job[4])
  $g.ResetTransform()
  $g.TranslateTransform([single]([double]($job[5])), [single]([double]($job[6])))
  $g.RotateTransform([single]([double]($job[2])))
  $g.ScaleTransform([single]$k, [single]$k)
  $g.TranslateTransform([single](-$sx), [single](-$sy))
  $g.DrawImage($b, 0, 0, $b.Width, $b.Height)
  $g.ResetTransform()
  $rows += "  {0,-15} {1,4}mm -> {2,3}px   rot {3,5}   anchor ({4:N0},{5:N0}) -> ({6},{7})" -f `
    $job[0], $job[1], [int]($long * $k), $job[2], $sx, $sy, $job[5], $job[6]
  $b.Dispose()
}
$g.Dispose()
$gear.Save((Join-Path $OutDir "climber-gear.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$gear.Dispose()

$rows
"wrote climber-front.png and climber-gear.png (800x800) to $OutDir"
foreach ($n in @("body", "gear", "front")) {
  $f = Get-Item (Join-Path $OutDir "climber-$n.png")
  "  climber-{0,-6} {1,5} KB" -f $n, [math]::Round($f.Length / 1KB)
}
