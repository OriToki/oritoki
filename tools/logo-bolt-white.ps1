# SUPERSEDED - use tools/logo-bolt-restore.ps1. This lightened the thin black circle inside each
# bolt along with the grey middle, and the owner saw the bolt as damaged. Kept only as a record.
#
# Takes the hex bolt heads in the header's two assembled anchors (logo-plate.png) back to WHITE.
#
# tools/logo-bolt.ps1 once filled them grey (111,111,112) at the owner's request; he later found it
# was not a good idea and asked for white again. There is no unfilled copy to go back to - both
# files were first committed already filled - so this undoes the fill in place.
#
# logo-bolt.ps1 scaled every pixel of the hexagon by 111/Base, so the antialiased rim kept its ramp
# down to the black outline. This scales the same pixels back up, by 255 over the region's own 90th
# percentile, so the flat middle lands on white and the rim ramps from white again.
#
# Which pixels? The darkened fill (~108) and the untouched inner edge of the black outline now have
# about the same lightness, so a plain threshold cannot tell them apart. What separates them is the
# DIRECTION: from the middle outward the darkened fill only gets darker, while the outline's own
# edge, which was never touched, is lighter than the darkened rim next to it. So the flood only
# steps to a neighbour that is no lighter than where it stands (+ $Tol). It stops at that jump.
#
# The lower bolt in logo-plate.png sits 11px left of where logo-bolt.ps1 looked for it
# (tools/logo-shift-back.ps1 moved it), so its seed here is (363,215), not (373,215).
param([double]$Tol = 3, [switch]$WhatIf)
Add-Type -AssemblyName System.Drawing
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
# ONLY the header's assembled anchors (logo-plate.png). The owner wants the white there and nowhere
# else: logo-full.png - the flat original mark in the footer and on join.html - keeps its grey
# bolts as drawn. Do not add it back to this list.
$bolts = @(
  @{ file = "logo-plate.png"; seeds = @(@(305, 36), @(363, 215)) }
)
$MAXREGION = 1500
foreach ($job in $bolts) {
  $path = Join-Path "$REPO\images" $job.file
  $bmp = New-Object System.Drawing.Bitmap($path)
  $W = $bmp.Width; $H = $bmp.Height
  "=== $($job.file)  $W x $H ==="
  $bad = $false; $edits = @()
  foreach ($seed in $job.seeds) {
    $seen = New-Object 'bool[]' ($W * $H)
    $stack = New-Object System.Collections.Stack
    $si = $seed[1] * $W + $seed[0]; $stack.Push($si); $seen[$si] = $true
    $px = New-Object System.Collections.ArrayList; $vals = New-Object System.Collections.ArrayList
    $c0 = $bmp.GetPixel($seed[0], $seed[1])
    if (($c0.R + $c0.G + $c0.B) / 3 -lt 80) { "  seed $($seed[0]),$($seed[1]) : not inside a filled bolt (lightness $([Math]::Round(($c0.R+$c0.G+$c0.B)/3)))"; $bad = $true; continue }
    while ($stack.Count -gt 0) {
      $p = $stack.Pop(); $cx = $p % $W; $cy = [Math]::Floor($p / $W)
      $c = $bmp.GetPixel($cx, $cy); $l = ($c.R + $c.G + $c.B) / 3
      [void]$px.Add(@($cx, $cy, $c)); [void]$vals.Add($l)
      if ($px.Count -gt $MAXREGION) { break }
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $cx + $d[0]; $ny = $cy + $d[1]
        if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $W -or $ny -ge $H) { continue }
        $q = $ny * $W + $nx; if ($seen[$q]) { continue }
        $nc = $bmp.GetPixel($nx, $ny); if ($nc.A -lt 100) { continue }
        $nl = ($nc.R + $nc.G + $nc.B) / 3
        if ($nl -lt 40) { continue }                 # the black outline itself
        if ($nl -gt $l + $Tol) { continue }          # lighter than here: the outline's untouched edge
        $seen[$q] = $true; $stack.Push($q)
      }
    }
    if ($px.Count -gt $MAXREGION) { "  seed $($seed[0]),$($seed[1]) : FLOOD ESCAPED"; $bad = $true; continue }
    $sorted = $vals | Sort-Object; $base = $sorted[[Math]::Floor($sorted.Count * 0.9)]
    "  seed $($seed[0]),$($seed[1]) : $($px.Count) px, base lightness $([Math]::Round($base))"
    $edits += ,@($px, $base)
  }
  if ($bad) { "  refusing to write $($job.file)"; $bmp.Dispose(); continue }
  foreach ($e in $edits) {
    $f = 255.0 / $e[1]
    foreach ($q in $e[0]) { $c = $q[2]
      $bmp.SetPixel($q[0], $q[1], [System.Drawing.Color]::FromArgb($c.A,
        [int][Math]::Min(255, [Math]::Round($c.R * $f)), [int][Math]::Min(255, [Math]::Round($c.G * $f)), [int][Math]::Min(255, [Math]::Round($c.B * $f)))) } }
  if ($WhatIf) { "  (WhatIf) not written"; $bmp.Dispose(); continue }
  $tmp = "$path.tmp"; $bmp.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
  Move-Item $tmp $path -Force; "  written: bolts back to white"
}
