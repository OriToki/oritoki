# Builds the join.html wallpaper tile FROM SCRATCH out of the owner's Desktop\icons folder.
# Nothing from the previous tile is kept.
#
# The folder holds two kinds of art: outline icons (black line drawings) and solid grey
# silhouettes. Mixing them reads badly at wallpaper size, so the silhouettes are converted to
# OUTLINES first - the ring around the shape plus its interior gaps - and everything ends up in
# one line style. Shapes are then scattered on a jittered grid, each at its own random angle,
# and anything crossing an edge is drawn again on the opposite side so the tile repeats seamlessly.
#
# TILE SIZE IS THE WHOLE TRICK. What reads as "the same icon over and over" is almost never the
# scatter - it is the tile coming round again. At 768px shown at 384 CSS px the wallpaper repeated
# every 384px across AND down, so every icon was back on screen three times in a phone's height.
# The tile is 1536 now, shown at 768, which is the same icons at the same size on screen with four
# times the area before anything comes back.
param(
  [int]$Seed = 21,
  [int]$Count = 100,                  # doodles per tile — keep it in step with $Tile, see above
  [int]$Target = 66,                  # every doodle gets this visual size (geometric mean)
  [int]$MaxDim = 96,                  # ...unless a long one would overrun its cell
  [int]$Tile = 1536, [double]$Gap = 14,                  # tile side in px
  [double]$SameSpread = 0.35,         # two copies of ONE icon stay this far apart, as a fraction
                                      # of the tile — 0 to turn the rule off
  [int]$Work = 130,                   # working size for the outline conversion
  [int]$Ring = 2,                     # outline thickness at working size
  [int]$CloseR = 5,                   # brush that seals interior detail gaps
  [switch]$Upright,                   # draw every doodle the right way up instead of spun
  [double]$Tilt = -1,                 # >=0: tilt each doodle by at most this many degrees
  [string]$Ver = "v9"                 # output suffix
)
Add-Type -AssemblyName System.Drawing
# After param(), which has to be the first statement in the file — it was below this line before,
# which made the whole parameter block a syntax error and the script unrunnable.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
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
  "oritoki-logo.png"               = 1.45   # the wordmark — the one thing here that is not a tool
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

# A spanner reads the same whichever way up it is. Words do not, and neither does a logo: spun
# with the rest of them the wordmark would spend most of its appearances upside down. These are
# drawn the right way up however the tilt settings are left.
$NoSpin = @("oritoki-logo.png")

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
  $doodles += ,@{ bmp = $d; real = $rf; noSpin = ($NoSpin -contains $f.Name) }
  $sq.Dispose()
}
$report | ForEach-Object { $_ }
"usable doodles: $($doodles.Count)"

# ---------- scatter ---------------------------------------------------------
$layer = New-Object System.Drawing.Bitmap($T, $T, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($layer)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
# FREE scatter, not a grid: throw a dart anywhere on the tile and keep it only if it clears
# everything already down. Even spacing without the regularity a grid leaves behind.
#
# Distance here is distance on a TORUS. The tile repeats, so something near the left edge is also
# near the right one - that is where its next copy lands - and a rule that ignored the wrap would
# happily put two of an icon at x=30 and x=1500 and call them far apart.
function TorusD2([double]$ax, [double]$ay, [double]$bx, [double]$by, [double]$side) {
  $dx = [math]::Abs($ax - $bx); if ($dx -gt $side/2) { $dx = $side - $dx }
  $dy = [math]::Abs($ay - $by); if ($dy -gt $side/2) { $dy = $side - $dy }
  return $dx*$dx + $dy*$dy
}

$placed = @()
$perIcon = New-Object int[] $doodles.Count
$sameMin = $T * $SameSpread
$guard = 0
while ($placed.Count -lt $Count -and $guard -lt 60000) {
  $guard++
  $cx = $rand.NextDouble() * $T
  $cy = $rand.NextDouble() * $T
  # Least-used icons first, ties broken at random. The old version drew from a bag and only
  # checked that the last four picks were different, which is an ordering rule, not a spacing
  # one: two copies of an icon could be five picks apart and still land side by side.
  $order = 0..($doodles.Count-1) | Sort-Object @{ e = { $perIcon[$_] } }, @{ e = { $rand.Next() } }
  foreach ($idx in $order) {
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
    # Doodles are not all one size, so the spacing test uses each one's own reach - half its
    # rotated bounding box - plus a fixed gap, rather than a single distance for everything.
    $rad = [math]::Sqrt($w*$w + $h*$h) / 2
    $ok = $true
    foreach ($p in $placed) {
      $need = ($rad + $p.rad) * 0.74 + $Gap
      if ((TorusD2 $cx $cy $p.cx $p.cy $T) -lt ($need*$need)) { $ok = $false; break }
    }
    # ...and this one is why the wallpaper stopped reading as the same picture over and over:
    # two copies of the SAME icon have to be a third of the tile apart, whatever else is between.
    if ($ok -and $sameMin -gt 0) {
      foreach ($p in $placed) {
        if ($p.idx -eq $idx -and (TorusD2 $cx $cy $p.cx $p.cy $T) -lt ($sameMin*$sameMin)) { $ok = $false; break }
      }
    }
    if (-not $ok) { continue }

    $placed += ,@{ idx = $idx; cx = $cx; cy = $cy; rad = $rad }
    $perIcon[$idx]++
    $spin = $rand.Next(0, 360)
    $ang = $spin
    if ($Upright) { $ang = 0 }
    # A small tilt is what a hand-made wallpaper actually looks like: upright enough to read,
    # loose enough not to look printed by a machine.
    if ($Tilt -ge 0) { $ang = ($spin / 360.0) * 2 * $Tilt - $Tilt }
    if ($doodles[$idx].noSpin) { $ang = 0 }
    # Drawn nine times, so anything crossing an edge appears on the opposite one and the tile
    # meets itself cleanly.
    foreach ($ox in -$T, 0, $T) { foreach ($oy in -$T, 0, $T) {
      $st = $g.Save()
      $g.TranslateTransform([single]($cx + $ox), [single]($cy + $oy))
      $g.RotateTransform([single]$ang)
      $g.DrawImage($d, [single](-$w/2), [single](-$h/2), [single]$w, [single]$h)
      $g.Restore($st) } }
    break
  }
}
$g.Dispose()
"placed: $($placed.Count) doodles from $($doodles.Count) icons  (darts thrown: $guard)"
$counts = $perIcon | Where-Object { $_ -gt 0 }
"each icon used {0}-{1} times; {2} icons unused" -f ($counts | Measure-Object -Minimum).Minimum, ($counts | Measure-Object -Maximum).Maximum, (@($perIcon | Where-Object { $_ -eq 0 }).Count)

# ---------- bake both themes ------------------------------------------------
# Recolour in one DrawImage through a colour matrix rather than pixel by pixel. The matrix throws
# the source colour away (the layer is black line art), writes the theme's colour flat, and scales
# the alpha the artwork already has — which keeps the antialiasing on every stroke. Per-pixel this
# was two and a third MILLION GetPixel/SetPixel calls per theme at the new tile size.
foreach ($theme in @(@{n="dark"; r=255; g=255; b=255; a=16}, @{n="light"; r=20; g=20; b=24; a=26})) {
  $res = New-Object System.Drawing.Bitmap($T, $T, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gg = [System.Drawing.Graphics]::FromImage($res)
  $cm = New-Object System.Drawing.Imaging.ColorMatrix
  $cm.Matrix00 = 0; $cm.Matrix11 = 0; $cm.Matrix22 = 0
  $cm.Matrix33 = $theme.a / 255.0
  $cm.Matrix40 = $theme.r / 255.0
  $cm.Matrix41 = $theme.g / 255.0
  $cm.Matrix42 = $theme.b / 255.0
  $ia = New-Object System.Drawing.Imaging.ImageAttributes
  $ia.SetColorMatrix($cm)
  $gg.DrawImage($layer, (New-Object System.Drawing.Rectangle 0,0,$T,$T), 0, 0, $T, $T,
                [System.Drawing.GraphicsUnit]::Pixel, $ia)
  $gg.Dispose(); $ia.Dispose()
  $res.Save("$IMG\join-doodles-$($theme.n)-$Ver.png", [System.Drawing.Imaging.ImageFormat]::Png)
  "wrote join-doodles-$($theme.n)-$Ver.png  ({0}x{0})" -f $T
  $res.Dispose()
}
$layer.Dispose(); foreach ($d in $doodles) { $d.bmp.Dispose() }








