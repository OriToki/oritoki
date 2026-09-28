# Fills the hex bolt head inside each anchor hanger with the rope's grey, a shade darker.
#
# Why this exists: the owner's drawing (images/logo-full.png) has both bolts filled with a solid
# grey - 151,150,150, which is the SAME grey the rope is drawn in (154,153,153). The layer split
# that produced images/logo-plate.png lost that fill and left the hexagons empty, so on the site
# the bolts read as hollow white dots. This puts the fill back, darker, as asked.
#
# The fill is NOT painted as a flat colour. Each bolt is flood-filled from a seed, the region's own
# base lightness is measured (255 where the hexagon came out white, ~151 where it is still the
# owner's grey), and every pixel is scaled by Target/Base. That way the antialiased rim of the
# hexagon keeps its exact ramp - it just ramps down to grey instead of down to white - and the same
# script is correct on both files without knowing which is which.
#
# PowerShell notes that cost time before: variable names are case-insensitive, so a param and a
# local must never share a name; [int] ROUNDS, so pixel maths uses [Math]::Floor.
param(
  # 111,111,112 - the rope grey (154) taken down about a quarter, still clear of the black outline.
  [int]$R = 111, [int]$G = 111, [int]$B = 112,
  [switch]$WhatIf
)
Add-Type -AssemblyName System.Drawing
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# One entry per bolt: file, and a seed KNOWN to sit inside the hexagon. The seeds were found by
# listing every enclosed light region in each file, not by eye - the hexagons are 8 px across in
# logo-plate.png and guessing at that size is how earlier passes went wrong.
$bolts = @(
  @{ file = "logo-plate.png"; seeds = @(@(305, 36), @(373, 215)) },
  @{ file = "logo-full.png";  seeds = @(@(430, 39), @(515, 286)) }
)
$MAXREGION = 1500   # a bolt is at most ~500 px; anything larger means the flood escaped the outline

foreach ($job in $bolts) {
  $path = Join-Path "$REPO\images" $job.file
  $bmp = New-Object System.Drawing.Bitmap($path)
  $W = $bmp.Width; $H = $bmp.Height
  "=== $($job.file)  $W x $H ==="
  $leak = $false
  $edits = @()

  foreach ($seed in $job.seeds) {
    # flood over "not the black ink", bounded by the hexagon's own outline
    $seen = New-Object 'bool[]' ($W * $H)
    $stack = New-Object System.Collections.Stack
    $si = $seed[1] * $W + $seed[0]
    $stack.Push($si); $seen[$si] = $true
    $px = New-Object System.Collections.ArrayList
    $vals = New-Object System.Collections.ArrayList
    while ($stack.Count -gt 0) {
      $p = $stack.Pop()
      $cx = $p % $W; $cy = [Math]::Floor($p / $W)
      $c = $bmp.GetPixel($cx, $cy)
      [void]$px.Add(@($cx, $cy, $c))
      [void]$vals.Add((($c.R + $c.G + $c.B) / 3))
      if ($px.Count -gt $MAXREGION) { break }
      foreach ($d in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
        $nx = $cx + $d[0]; $ny = $cy + $d[1]
        if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $W -or $ny -ge $H) { continue }
        $q = $ny * $W + $nx
        if ($seen[$q]) { continue }
        $nc = $bmp.GetPixel($nx, $ny)
        if ($nc.A -lt 100) { continue }
        if ((($nc.R + $nc.G + $nc.B) / 3) -lt 110) { continue }
        $seen[$q] = $true; $stack.Push($q)
      }
    }
    if ($px.Count -gt $MAXREGION) {
      "  seed $($seed[0]),$($seed[1]) : FLOOD ESCAPED ($($px.Count) px) - outline is not closed here"
      $leak = $true; continue
    }
    # The base is the 90th percentile, not the max: the max is one stray antialias pixel and using
    # it would land each file's fill on a different grey.
    $sorted = $vals | Sort-Object
    $base = $sorted[[Math]::Floor($sorted.Count * 0.9)]
    "  seed $($seed[0]),$($seed[1]) : $($px.Count) px, base lightness $([Math]::Round($base))"
    $edits += ,@($px, $base)
  }

  if ($leak) { "  refusing to write $($job.file)"; $bmp.Dispose(); continue }

  foreach ($e in $edits) {
    $base = $e[1]
    foreach ($q in $e[0]) {
      $c = $q[2]
      $k = (($c.R + $c.G + $c.B) / 3) / $base          # 1.0 at the flat middle, less on the rim
      if ($k -gt 1) { $k = 1 }
      $bmp.SetPixel($q[0], $q[1], [System.Drawing.Color]::FromArgb($c.A,
        [int][Math]::Round($R * $k), [int][Math]::Round($G * $k), [int][Math]::Round($B * $k)))
    }
  }
  if ($WhatIf) { "  (WhatIf) not written" }
  else {
    $tmp = "$path.tmp"
    $bmp.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Move-Item $tmp $path -Force
    "  written, bolts filled with $R,$G,$B"
    continue
  }
  $bmp.Dispose()
}
