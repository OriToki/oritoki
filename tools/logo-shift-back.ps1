# Slides the LOWER (backup) anchor of the lockup sideways, lettering untouched.
#
# The owner asked (2026-09-30) for both anchors to stand the same distance off the lettering.
# Measured on the 400 x 438 layers: the upper carabiner starts 11 px right of the "r"
# (r ends at x 264, carabiner at 275), the lower one 22 px right of the "k" (322 -> 344).
# So the lower anchor goes 11 px left. It is four pieces on the shared canvas and all of them move:
#   logo-plate.png   only its LOWER half (the lower hanger plate; the upper plate sits above y 150)
#   logo-back.png    the lower carabiner + knot
#   logo-barlow.png  the lower hanger's diagonal bar
# Every pixel is still the owner's; they are only moved, as whole pieces.
# Moving it changes the ROPE GAP (A.stemBackX / A.pivotBackX / #caraBack's transform-origin),
# and the gap is what tools/climber-assemble.ps1 places the ASAP from - re-run it with the new -Sep.
param([int]$Dx = -11, [int]$SplitY = 150,
      [string]$Dir = (Resolve-Path (Join-Path $PSScriptRoot "..\images")).Path)
Add-Type -AssemblyName System.Drawing
function Shift($name, [int]$fromY) {
  $p = Join-Path $Dir $name
  $src = New-Object System.Drawing.Bitmap $p
  $out = New-Object System.Drawing.Bitmap $src.Width, $src.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $src.Height; $y++) { for ($x = 0; $x -lt $src.Width; $x++) {
    $c = $src.GetPixel($x, $y); if ($c.A -eq 0) { continue }
    $nx = if ($y -ge $fromY) { $x + $Dx } else { $x }
    if ($nx -ge 0 -and $nx -lt $src.Width) { $out.SetPixel($nx, $y, $c) }
  } }
  $src.Dispose(); $out.Save($p, [System.Drawing.Imaging.ImageFormat]::Png); $out.Dispose()
  "$name shifted $Dx px (rows >= $fromY)"
}
Shift "logo-plate.png" $SplitY
Shift "logo-back.png" 0
Shift "logo-barlow.png" 0
