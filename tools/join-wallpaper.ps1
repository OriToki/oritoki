# Repo root, resolved from this script's location so the tool works from any checkout.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Builds the join.html wallpaper tile FROM SCRATCH out of the owner's Desktop\icons folder.
# Nothing from the previous tile is kept.
#
# The folder holds two kinds of art: outline icons (black line drawings) and solid grey
# silhouettes. Mixing them reads badly at wallpaper size, so the silhouettes are converted to
# OUTLINES first - the ring around the shape plus its interior gaps - and everything ends up in
# one line style. Shapes are then scattered on a jittered grid, each at its own random angle,
# and anything crossing an edge is drawn again on the opposite side so the tile repeats seamlessly.
param(
  [int]$Seed = 21,
  [int]$Cols = 5, [int]$Rows = 5,     # jittered grid of doodles
  [int]$Target = 66,                  # every doodle gets this visual size (geometric mean)
  [int]$MaxDim = 96,                  # ...unless a long one would overrun its cell
  [int]$Tile = 768, [double]$Gap = 14,                   # tile side in px
  [int]$Work = 130,                   # working size for the outline conversion
  [int]$Ring = 2,                     # outline thickness at working size
  [int]$CloseR = 5,                   # brush that seals interior detail gaps
  [switch]$Upright,                   # draw every doodle the right way up instead of spun
  [double]$Tilt = -1,                 # >=0: tilt each doodle by at most this many degrees
  [string]$Ver = "v5"                 # output suffix
)
Add-Type -AssemblyName System.Drawing
$rand = New-Object System.Random($Seed)
$IMG = "$REPO\images"
$SRC = "C:\Users\gilmo\OneDrive\Desktop\icons"
$T = $Tile

# ---------- helpers ---------------------------------------------------------
function Grow([bool[]]$m, [int]$S, [int]$r, [bool]$dilate) {
  $N = $S*$S; $tmp = New-Object bool[] $N; $res = New-Object bool[] $N
  for ($y = 0; $y -lt $S; $y++) { $row = $y*$S
    for ($x = 0; $x -lt $S; $x++) { $v = -not $dilate
      for ($k = -$r; $k -le $r; $k++) { $xx = $x + $k
        if ($xx -lt 0 -or $xx -ge $S) { $smp = -not $dilate } else { $smp = $m[$row + $xx] }
        if ($dilate) { if ($smp) { $v = $true; break } } else { if (-not $smp) { $v = $false; break } } }
      $tmp[$row + $x] = $v } }
  for ($x = 0; $x -lt $S; $x++) {
    for ($y = 0; $y -lt $S; $y++) { $v = -not $dilate
      for ($k = -$r; $k -le $r; $k++) { $yy = $y + $k
        if ($yy -lt 0 -or $yy -ge $S) { $smp = -not $dilate } else { $smp = $tmp[$yy*$S + $x] }
        if ($dilate) { if ($smp) { $v = $true; break } } else { if (-not $smp) { $v = $false; break } } }
      $res[$y*$S + $x] = $v } }
  return $res
}

# ---------- how big each thing is IN REAL LIFE ------------------------------
# A carabiner really is smaller than a harness and an ice axe really is longer than a pulley,
# so the doodles are scaled by these factors instead of all being drawn the same size. The
# spread is deliberately compressed (0.72 - 1.40, not the true 1:300 of a carabiner to a pylon)
# - at wallpaper size the point is the *pecking order*, not the literal scale.
$RealSize = @{
  "picto_lampes_sport_2022.jpg"    = 0.72   # headlamp
  "Carabiner.jpg"                  = 0.80
  "pro-famille-connecteurs.jpg"    = 0.80   # carabiners
  "sport-famille-mousquetons.jpg"  = 0.80
  "sport-famille-assureurs.jpg"    = 0.82   # belay device
  "pro-famille-poulies.jpg"        = 0.86   # pulley
  "sport-famille-poulies.jpg"      = 0.86
  "back up device back ground.png" = 0.90   # backup device
  "descender device.png"           = 0.95
  "pro-famille-descendeurs.jpg"    = 0.95
  "pro-famille-bloqueurs.jpg"      = 0.98   # ascender
  "pro-famille-amarrages.jpg"      = 1.00   # anchor
  "sport-famille-amarrages.jpg"    = 1.00
  "o.jpg"                          = 1.08   # helmet
  "sport-famille-casques.jpg"      = 1.08
  "sport-famille-piolets.jpg"      = 1.18   # ice axe
  "r.jpg"                          = 1.20   # Y lanyard
  "sport-famille-longes.jpg"       = 1.20
  "pro-famille-cordes.jpg"         = 1.15   # rope coil
  "sport-famille-cordes.jpg"       = 1.15
  "IMG_4015.jpg"                   = 1.22   # harness
  "sport-famille-harnais.jpg"      = 1.22
  # tools and symbols
  "picto_lampes.jpg"               = 0.72
  "Screenshot 2026-09-04 043225.png" = 0.90 # lightning
  "agkj.png"                       = 0.95   # cog + spanner
  "Screenshot 2026-09-04 3253.png"   = 0.95 # gear + spanner
  "Screenshot 2026-09-04 040909.png" = 1.00 # hand tools
  "Screenshot 2026-09-04 040941.png" = 1.00 # handshake
  "Screenshot 2026-09-04 042905.png" = 1.00 # spanner + screwdriver
  "Screenshot 2026-09-04 043100.png" = 1.00 # drill
  "Screenshot 2026-09-04 042250.png" = 1.05 # paint roller
  "Screenshot 2026-09-04 042655.png" = 1.05 # squeegee
  # things that are big in the world
  "Screenshot 2026-09-04 041402.png" = 1.15 # AC unit
  "Screenshot 2026-09-04 043513.png" = 1.20 # satellite dish
  "Screenshot 2026-09-04 042543.png" = 1.25 # inspector
  "Screenshot 2026-09-04 040453.png" = 1.32 # technician on a facade
  "Screenshot 2026-09-04 041128.png" = 1.40 # buildings
  "Screenshot 2026-09-04 041636.png" = 1.40 # pylon
  "Screenshot 2026-09-04 041714.png" = 1.40 # antenna mast
  "Screenshot 2026-09-04 042037.png" = 1.40 # factory
  "Screenshot 2026-09-04 043341.png" = 1.40 # wind turbines
}

# ---------- load + normalise every icon to black-on-transparent line art ----
$skip = @("sport-famille-longes (1).jpg", "back up device.jpg")   # duplicates of another file
$files = Get-ChildItem $SRC -File | Where-Object { $_.Extension -match 'png|jpg' -and $skip -notcontains $_.Name } | Sort-Object Name
$doodles = @(); $report = @()
foreach ($f in $files) {
  $b = New-Object System.Drawing.Bitmap($f.FullName)
  # square working copy, letterboxed
  $s = [math]::Min($Work / $b.Width, $Work / $b.Height)
  $w = [int]($b.Width * $s); $h = [int]($b.Height * $s)
  $sq = New-Object System.Drawing.Bitmap($Work, $Work, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($sq)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($b, [int](($Work-$w)/2), [int](($Work-$h)/2), $w, $h)
  $g.Dispose(); $b.Dispose()

  $N = $Work*$Work
  $ink = New-Object bool[] $N; $dark = 0; $any = 0
  for ($y = 0; $y -lt $Work; $y++) { for ($x = 0; $x -lt $Work; $x++) {
    $c = $sq.GetPixel($x, $y); $lum = ($c.R + $c.G + $c.B) / 3
    if ($c.A -gt 60 -and $lum -lt 205) { $ink[$y*$Work + $x] = $true; $any++
      if ($lum -lt 95) { $dark++ } } } }
  if ($any -lt 40) { $sq.Dispose(); $report += "skipped (empty): $($f.Name)"; continue }
  $isLine = ($dark / [double]$any) -gt 0.55

  $mask = New-Object bool[] $N
  if ($isLine) {
    # already a line drawing: keep the dark strokes only
    for ($y = 0; $y -lt $Work; $y++) { for ($x = 0; $x -lt $Work; $x++) {
      $c = $sq.GetPixel($x, $y); $lum = ($c.R + $c.G + $c.B) / 3
      if ($c.A -gt 60 -and $lum -lt 130) { $mask[$y*$Work + $x] = $true } } }
    $report += "line art : $($f.Name)"
  } else {
    # solid silhouette: trace it - ring around the shape + its interior detail gaps
    $closed = Grow (Grow $ink $Work $CloseR $true) $Work $CloseR $false
    $outer  = Grow $closed $Work $Ring $true
    $inner  = Grow $closed $Work $Ring $false
    for ($i = 0; $i -lt $N; $i++) {
      if (($outer[$i] -and -not $inner[$i]) -or ($closed[$i] -and -not $ink[$i])) { $mask[$i] = $true } }
    $report += "traced   : $($f.Name)"
  }
  # trim to ink and store
  $minx = $Work; $miny = $Work; $maxx = -1; $maxy = -1
  for ($y = 0; $y -lt $Work; $y++) { for ($x = 0; $x -lt $Work; $x++) { if ($mask[$y*$Work + $x]) {
    if ($x -lt $minx) { $minx = $x }; if ($x -gt $maxx) { $maxx = $x }
    if ($y -lt $miny) { $miny = $y }; if ($y -gt $maxy) { $maxy = $y } } } }
  if ($maxx -lt 0) { $sq.Dispose(); $report += "skipped (no mask): $($f.Name)"; continue }
  $dw = $maxx - $minx + 1; $dh = $maxy - $miny + 1
  $d = New-Object System.Drawing.Bitmap($dw, $dh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $blk = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
  for ($y = 0; $y -lt $dh; $y++) { for ($x = 0; $x -lt $dw; $x++) {
    if ($mask[($miny+$y)*$Work + ($minx+$x)]) { $d.SetPixel($x, $y, $blk) } } }
  $rf = 1.0
  if ($RealSize.ContainsKey($f.Name)) { $rf = $RealSize[$f.Name] } else { $report += "   (no real-size entry, using 1.0): $($f.Name)" }
  $doodles += ,@{ bmp = $d; real = $rf }
  $sq.Dispose()
}
$report | ForEach-Object { $_ }
"usable doodles: $($doodles.Count)"

# ---------- scatter ---------------------------------------------------------
$layer = New-Object System.Drawing.Bitmap($T, $T, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($layer)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
# One doodle per grid cell, jittered inside it: the spacing stays even but nothing lines up.
# Cells are filled from a shuffled bag that is reshuffled when it runs out, so an icon can turn
# up more than once per tile - each time at its own angle and in its own cell, which is what
# stops any one icon from always appearing in the same pose.
$bag = @(); $recent = @(); $pts = @()
$want = $Cols * $Rows
$guard = 0
while ($pts.Count -lt $want -and $guard -lt 20000) {
  $guard++
  if ($bag.Count -eq 0) { $bag = 0..($doodles.Count-1) | Sort-Object { $rand.Next() } }
  # avoid putting the same icon next to itself
  $pick = 0
  # NB: not $t - PowerShell is case-insensitive and $T is the tile size
  for ($ti = 0; $ti -lt $bag.Count; $ti++) { if ($recent -notcontains $bag[$ti]) { $pick = $ti; break } }
  $idx = $bag[$pick]
  $d = $doodles[$idx].bmp
  $real = $doodles[$idx].real
  # Size is (a) the same visual measure for everything - the geometric mean of width and height,
  # so a flat icon is not left looking tiny next to a tall one - times (b) how big the thing
  # actually is in real life. A carabiner ends up smaller than the harness next to it.
  $size = $Target * $real * (0.94 + $rand.NextDouble() * 0.12)
  $sc = $size / [math]::Sqrt($d.Width * $d.Height)
  $cap = $MaxDim * $real
  if ([math]::Max($d.Width, $d.Height) * $sc -gt $cap) { $sc = $cap / [math]::Max($d.Width, $d.Height) }
  $w = $d.Width * $sc; $h = $d.Height * $sc
  # FREE scatter, not a grid: throw a dart anywhere on the tile and keep it only if it is at
  # least $Dmin from every doodle already down (measured with wrap-around, since the tile
  # repeats). Even spacing without the regularity a grid leaves behind - which is what made the
  # same icon show up in the same spot in every repeat.
  $cx = $rand.NextDouble() * $T
  $cy = $rand.NextDouble() * $T
  # Doodles are no longer all one size, so the spacing test uses each one's own reach (half its
  # rotated bounding box) plus a fixed gap, rather than a single distance for everything.
  $rad = [math]::Sqrt($w*$w + $h*$h) / 2
  $ok = $true
  foreach ($p in $pts) {
    $dx = [math]::Abs($cx - $p[0]); if ($dx -gt $T/2) { $dx = $T - $dx }
    $dy = [math]::Abs($cy - $p[1]); if ($dy -gt $T/2) { $dy = $T - $dy }
    $need = ($rad + $p[2]) * 0.74 + $Gap
    if (($dx*$dx + $dy*$dy) -lt ($need*$need)) { $ok = $false; break } }
  if (-not $ok) { continue }
  $pts += ,@($cx, $cy, $rad)
  $bag = @($bag | Where-Object { $_ -ne $idx })
  $recent = @($recent + $idx | Select-Object -Last 4)
  $spin = $rand.Next(0, 360)      # drawn even when unused, so positions stay identical
  $ang = $spin
  if ($Upright) { $ang = 0 }
  # A small tilt is what a hand-made wallpaper actually looks like: upright enough to read,
  # loose enough not to look printed by a machine.
  if ($Tilt -ge 0) { $ang = ($spin / 360.0) * 2 * $Tilt - $Tilt }
  foreach ($ox in -$T, 0, $T) { foreach ($oy in -$T, 0, $T) {
    $st = $g.Save()
    $g.TranslateTransform([single]($cx + $ox), [single]($cy + $oy))
    $g.RotateTransform([single]$ang)
    $g.DrawImage($d, [single](-$w/2), [single](-$h/2), [single]$w, [single]$h)
    $g.Restore($st) } }
}
$g.Dispose()
"placed: $($pts.Count) doodles"

# ---------- bake both themes ------------------------------------------------
foreach ($theme in @(@{n="dark"; r=255; g=255; b=255; a=16}, @{n="light"; r=20; g=20; b=24; a=26})) {
  $res = New-Object System.Drawing.Bitmap($T, $T, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $T; $y++) { for ($x = 0; $x -lt $T; $x++) {
    $a = [int]($layer.GetPixel($x, $y).A / 255 * $theme.a)
    if ($a -gt 0) { $res.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, $theme.r, $theme.g, $theme.b)) } } }
  $res.Save("$IMG\join-doodles-$($theme.n)-$Ver.png", [System.Drawing.Imaging.ImageFormat]::Png)
  "wrote join-doodles-$($theme.n)-$Ver.png"
  $res.Dispose()
}
$layer.Dispose(); foreach ($d in $doodles) { $d.bmp.Dispose() }








