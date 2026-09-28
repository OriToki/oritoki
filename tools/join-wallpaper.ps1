# Builds the join.html wallpaper tile FROM SCRATCH out of the owner's high-resolution icon set.
# Nothing from the previous tile is kept.
#
# WHAT THIS IS COPYING. The owner's reference is the WhatsApp chat wallpaper (Desktop\background.png).
# It was measured rather than eyeballed, and these are the numbers to hit:
#     tile period   810 px      (found by autocorrelation - correlation 1.000)
#     ink coverage  17.5 %      (share of the tile carrying ink)
#     icon size     8.9 %       of the tile side
#     rotation      upright     - not a spun scatter
# The script prints its own ink coverage and icon size at the end so a run can be read against
# those three figures instead of judged by eye. At 6% opacity the eye cannot judge it; every
# earlier pass that tried got the density wrong.
#
# WHY THE ICONS ARE ALL ONE SIZE. The previous version scaled each doodle by how big the thing is
# in real life, so a carabiner came out smaller than a pylon. The reference does not do that - a
# whale and a cactus sit at the same size on the WhatsApp tile - and matching it matters more than
# the conceit. Only a +/-6% jitter is left, so the field does not look stamped.
#
# TILE SIZE IS THE OTHER HALF. What reads as "the same icon over and over" is almost never the
# scatter, it is the tile coming round again. 1536 shown at 768 CSS px puts our repeat close to the
# reference's 810.
#
# HOW THE GAPS GET FILLED, which is the whole of the owner's second note. Doodles are placed in
# THREE PASSES, largest first: the big ones stake out the tile, then the middling ones drop into
# what is left between them, then the small ones fill the last corners. That is the principle he
# pointed at in the reference - big drawings with little drawings tucked into the spaces between -
# and it is the only way to fill a tile without letting anything overlap.
#
# AND NOTHING OVERLAPS. The test is rectangle against rectangle, on the axis-aligned box of the
# TILTED doodle, so two doodles can sit edge to edge but never on top of each other. The version
# before this measured circles round each doodle and was told to let them interlock at 0.62 of
# their radii, which is exactly what put icons on top of one another.
param(
  [int]$Seed = 21,
  [int]$Big = 34, [int]$Mid = 46, [int]$Small = 62,   # doodles per size pass; read the ink figure
  [int]$Target = 150,                 # visual size of a BIG doodle (geometric mean of its box)
  [double]$MidScale = 0.66,           # the middling pass, as a fraction of $Target
  [double]$SmallScale = 0.42,         # ...and the gap-filling pass
  [int]$Tile = 1536,
  [double]$Gap = 7,                   # clear space between two boxes, in px
  [double]$Tight = 0.90,              # the boxes are shrunk by this before the overlap test: a
                                      # bounding box has empty corners, so a shade under 1.0 lets
                                      # two doodles tuck together without their ink touching.
                                      # 1.0 = never let the boxes meet at all.
  [int]$Tries = 900,                  # darts thrown per doodle before that icon is given up on
  [double]$SameSpread = 0.24,         # two copies of ONE icon stay this far apart, as a fraction
                                      # of the tile - 0 turns the rule off
  [double]$Tilt = 22,                 # each doodle leans by up to this many degrees, either way.
                                      # The reference is not a set of upright stamps - its cat
                                      # leans left, its wheelchair leans right - and the lean is
                                      # what stops the field looking printed by a machine.
  [int]$Work = 160,                   # working size for the outline conversion
  [int]$Ring = 2,                     # traced-outline thickness at working size
  [double]$ThinInk = 13,              # line icons below this % of their own box get thickened...
  [int]$LineBoost = 1,                # ...by this much, so the set reads at one line weight
  [int]$CloseR = 4,                   # brush that seals interior detail gaps before tracing
  [string]$Ver = "v14",
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\icons in high rez",
  # Icons left out of the tile. The file stays in the owner's folder - this is the exclusion, so it
  # can be undone by deleting a line. The abseiler on the cliff is a solid black wedge taking up
  # most of its frame, and at wallpaper size it reads as a dark blob rather than a drawing; the
  # owner circled it and asked for it out.
  [string[]]$Skip = @("ChatGPT Image Sep 24, 2026, 12_41_07 PM (10).png")
)
Add-Type -AssemblyName System.Drawing
# After param(), which has to be the first statement in the file.
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rand = New-Object System.Random($Seed)
$IMG = "$REPO\images"
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

# ---------- load + normalise every icon to black-on-transparent line art ----
# The set is drawn two ways - black outlines and solid grey silhouettes - and mixing the two reads
# badly at wallpaper size, so the silhouettes are converted to OUTLINES first (the ring around the
# shape plus its interior gaps) and everything ends up in one line style.
$files = Get-ChildItem $Src -File |
  Where-Object { $_.Extension -match 'png|jpg|jpeg' -and $Skip -notcontains $_.Name } | Sort-Object Name
if ($Skip.Count) { "left out: $($Skip -join ', ')" }
$doodles = @(); $report = @(); $flipped = 0
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
  $lum = New-Object double[] $N
  for ($y = 0; $y -lt $Work; $y++) { for ($x = 0; $x -lt $Work; $x++) {
    $c = $sq.GetPixel($x, $y)
    # a transparent letterbox margin counts as ground, not as ink
    if ($c.A -lt 60) { $lum[$y*$Work + $x] = 255 } else { $lum[$y*$Work + $x] = ($c.R + $c.G + $c.B) / 3 } } }

  # Which way round is it? One icon in the set - the wordmark - is white on black, and traced as
  # supplied it comes out as a solid rectangle. The ground is whatever the BORDER is, so a dark
  # border means the image is inverted and every luminance is flipped before anything else runs.
  $bord = New-Object System.Collections.ArrayList
  for ($x = 0; $x -lt $Work; $x += 3) { [void]$bord.Add($lum[$x]); [void]$bord.Add($lum[($Work-1)*$Work + $x]) }
  for ($y = 0; $y -lt $Work; $y += 3) { [void]$bord.Add($lum[$y*$Work]); [void]$bord.Add($lum[$y*$Work + $Work-1]) }
  $bsort = $bord | Sort-Object
  $ground = $bsort[[int]($bsort.Count / 2)]
  if ($ground -lt 140) {
    for ($i = 0; $i -lt $N; $i++) { $lum[$i] = 255 - $lum[$i] }
    $ground = 255 - $ground; $flipped++
  }

  # ink = anything clearly darker than this icon's own ground
  $cut = $ground - 45
  $ink = New-Object bool[] $N; $dark = 0; $any = 0
  for ($i = 0; $i -lt $N; $i++) {
    if ($lum[$i] -lt $cut) { $ink[$i] = $true; $any++; if ($lum[$i] -lt ($ground * 0.42)) { $dark++ } } }
  if ($any -lt 60) { $sq.Dispose(); $report += "skipped (empty): $($f.Name)"; continue }
  $isLine = ($dark / [double]$any) -gt 0.55

  $mask = New-Object bool[] $N
  if ($isLine) {
    for ($i = 0; $i -lt $N; $i++) { if ($lum[$i] -lt ($ground * 0.55)) { $mask[$i] = $true } }
    # Anything drawn far lighter than the rest gets a pixel added, so one weight carries the tile.
    $cnt = 0; $bx0 = $Work; $bx1 = -1; $by0 = $Work; $by1 = -1
    for ($y = 0; $y -lt $Work; $y++) { for ($x = 0; $x -lt $Work; $x++) { if ($mask[$y*$Work + $x]) {
      $cnt++
      if ($x -lt $bx0) { $bx0 = $x }; if ($x -gt $bx1) { $bx1 = $x }
      if ($y -lt $by0) { $by0 = $y }; if ($y -gt $by1) { $by1 = $y } } } }
    $cov = 0.0
    if ($bx1 -ge 0) { $cov = $cnt / [double](($bx1-$bx0+1) * ($by1-$by0+1)) }
    if ($cov -gt 0 -and $cov -lt ($ThinInk / 100.0)) {
      $mask = Grow $mask $Work $LineBoost $true
      $report += ("line  : {0}  ({1:P0} - thickened)" -f $f.Name, $cov)
    } else { $report += ("line  : {0}  ({1:P0})" -f $f.Name, $cov) }
  } else {
    $closed = Grow (Grow $ink $Work $CloseR $true) $Work $CloseR $false
    $outer  = Grow $closed $Work $Ring $true
    $inner  = Grow $closed $Work $Ring $false
    for ($i = 0; $i -lt $N; $i++) {
      if (($outer[$i] -and -not $inner[$i]) -or ($closed[$i] -and -not $ink[$i])) { $mask[$i] = $true } }
    $report += "traced: $($f.Name)"
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
  $doodles += ,@{ bmp = $d; name = $f.Name }
  $sq.Dispose()
}
$report | ForEach-Object { $_ }
"usable doodles: $($doodles.Count) of $($files.Count) files   ($flipped inverted back to dark-on-light)"
if ($doodles.Count -lt 2) { throw "not enough usable icons in $Src" }

# ---------- scatter ---------------------------------------------------------
$layer = New-Object System.Drawing.Bitmap($T, $T, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($layer)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
# FREE scatter, not a grid: throw a dart anywhere and keep it only if it clears everything already
# down. Even spacing without the regularity a grid leaves behind.
#
# Distance here is distance on a TORUS. The tile repeats, so something near the left edge is also
# near the right one - that is where its next copy lands - and a rule that ignored the wrap would
# happily put two of an icon at x=30 and x=1500 and call them far apart.
#
# Written longhand over typed arrays, and the icon is chosen BEFORE the dart rather than sorting
# the whole set at every throw. The readable version of this loop did not finish in ten minutes.
$total = $Big + $Mid + $Small
$sameMin2 = ($T * $SameSpread) * ($T * $SameSpread)
$half = $T / 2.0
$pIdx = New-Object int[] $total
$pX = New-Object double[] $total
$pY = New-Object double[] $total
$pW = New-Object double[] $total     # half-width  of the TILTED box, already shrunk by $Tight
$pH = New-Object double[] $total     # half-height of the TILTED box
$n = 0
$perIcon = New-Object int[] $doodles.Count
$guard = 0
$placedPer = @()

# A BUCKET GRID over the tile, because the small pass throws a lot of darts. Testing every dart
# against every doodle already down is O(n) a throw, and at a few hundred doodles that is tens of
# millions of comparisons - the run went from seconds to minutes when the icons were made smaller
# and their number went up to compensate. Each doodle is filed in the buckets its box covers, and
# a dart only looks at the buckets its own box could reach.
$BK = 12
$cellSz = $T / [double]$BK
$buckets = New-Object 'System.Collections.ArrayList[]' ($BK * $BK)
for ($i = 0; $i -lt $buckets.Length; $i++) { $buckets[$i] = New-Object System.Collections.ArrayList }
$maxHalf = 0.0                       # biggest half-extent placed so far; a dart has to look this
                                     # far beyond its own box, since the neighbour's size counts too
# Copies of one icon have to stay apart wherever they are, so those are kept in their own short
# list per icon rather than hunted for through the buckets.
$iconAt = New-Object 'System.Collections.ArrayList[]' $doodles.Count
for ($i = 0; $i -lt $iconAt.Length; $i++) { $iconAt[$i] = New-Object System.Collections.ArrayList }

foreach ($pass in @(@{ want = $Big; scale = 1.0; label = "big" },
                    @{ want = $Mid; scale = $MidScale; label = "mid" },
                    @{ want = $Small; scale = $SmallScale; label = "small" })) {
  $blocked = New-Object bool[] $doodles.Count   # a fresh slate each pass: an icon that would not
                                                # fit at full size may well fit at 42%
  $got = 0
  while ($got -lt $pass.want) {
    # Least-used icon, at random among the ties, so repetition stays even across the tile instead
    # of a handful of icons carrying it.
    $min = [int]::MaxValue
    for ($i = 0; $i -lt $perIcon.Length; $i++) { if (-not $blocked[$i] -and $perIcon[$i] -lt $min) { $min = $perIcon[$i] } }
    if ($min -eq [int]::MaxValue) { break }     # every icon blocked: no room left in this pass
    $cand = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $perIcon.Length; $i++) { if (-not $blocked[$i] -and $perIcon[$i] -eq $min) { [void]$cand.Add($i) } }
    $idx = $cand[$rand.Next($cand.Count)]

    $d = $doodles[$idx].bmp
    # One visual measure - the geometric mean of width and height - so a flat icon is not left
    # looking tiny beside a tall one, times this pass's scale.
    $size = $Target * $pass.scale * (0.94 + $rand.NextDouble() * 0.12)
    $sc = $size / [math]::Sqrt($d.Width * $d.Height)
    $w = $d.Width * $sc; $h = $d.Height * $sc
    $ang = $rand.NextDouble() * 2 * $Tilt - $Tilt
    # Axis-aligned box of the leaning doodle. Leaning grows the box, which is why the lean is kept
    # modest: at 45 degrees a long icon would reserve half again its own area in empty corner.
    $r = $ang * [math]::PI / 180.0
    $ca = [math]::Abs([math]::Cos($r)); $sa = [math]::Abs([math]::Sin($r))
    $bw = ($w * $ca + $h * $sa) * $Tight / 2.0
    $bh = ($w * $sa + $h * $ca) * $Tight / 2.0

    # How far past its own box a dart has to look: the neighbour's half-extent counts too.
    $reachX = $bw + $maxHalf + $Gap
    $reachY = $bh + $maxHalf + $Gap
    $mine = $iconAt[$idx]
    $cx = 0.0; $cy = 0.0; $ok = $false
    for ($try = 0; $try -lt $Tries; $try++) {
      $guard++
      $cx = $rand.NextDouble() * $T
      $cy = $rand.NextDouble() * $T
      $good = $true
      # ...no copy of this same icon nearby, wherever it is. Checked first: it is a handful of
      # comparisons and it rejects a good share of the darts.
      foreach ($p in $mine) {
        $dx = [math]::Abs($cx - $p[0]); if ($dx -gt $half) { $dx = $T - $dx }
        $dy = [math]::Abs($cy - $p[1]); if ($dy -gt $half) { $dy = $T - $dy }
        if (($dx*$dx + $dy*$dy) -lt $sameMin2) { $good = $false; break }
      }
      if ($good) {
        $bx0 = [Math]::Floor(($cx - $reachX) / $cellSz); $bx1 = [Math]::Floor(($cx + $reachX) / $cellSz)
        $by0 = [Math]::Floor(($cy - $reachY) / $cellSz); $by1 = [Math]::Floor(($cy + $reachY) / $cellSz)
        if (($bx1 - $bx0) -ge $BK) { $bx0 = 0; $bx1 = $BK - 1 }
        if (($by1 - $by0) -ge $BK) { $by0 = 0; $by1 = $BK - 1 }
        :dart foreach ($byi in $by0..$by1) {
          $by = (($byi % $BK) + $BK) % $BK
          foreach ($bxi in $bx0..$bx1) {
            $bx = (($bxi % $BK) + $BK) % $BK
            foreach ($k in $buckets[$by * $BK + $bx]) {
              $dx = [math]::Abs($cx - $pX[$k]); if ($dx -gt $half) { $dx = $T - $dx }
              $dy = [math]::Abs($cy - $pY[$k]); if ($dy -gt $half) { $dy = $T - $dy }
              # Two boxes clear each other the moment ONE axis separates them.
              if ($dx -ge ($bw + $pW[$k] + $Gap)) { continue }
              if ($dy -ge ($bh + $pH[$k] + $Gap)) { continue }
              $good = $false; break dart
            }
          }
        }
      }
      if ($good) { $ok = $true; break }
    }
    if (-not $ok) { $blocked[$idx] = $true; continue }

    $pIdx[$n] = $idx; $pX[$n] = $cx; $pY[$n] = $cy; $pW[$n] = $bw; $pH[$n] = $bh
    [void]$mine.Add(@($cx, $cy))
    if ($bw -gt $maxHalf) { $maxHalf = $bw }
    if ($bh -gt $maxHalf) { $maxHalf = $bh }
    # file it in every bucket its own box covers
    $bx0 = [Math]::Floor(($cx - $bw) / $cellSz); $bx1 = [Math]::Floor(($cx + $bw) / $cellSz)
    $by0 = [Math]::Floor(($cy - $bh) / $cellSz); $by1 = [Math]::Floor(($cy + $bh) / $cellSz)
    foreach ($byi in $by0..$by1) { $by = (($byi % $BK) + $BK) % $BK
      foreach ($bxi in $bx0..$bx1) { $bx = (($bxi % $BK) + $BK) % $BK
        [void]$buckets[$by * $BK + $bx].Add($n) } }
    $n++
    $perIcon[$idx]++; $got++

    # Drawn nine times, so anything crossing an edge appears on the opposite one and the tile meets
    # itself cleanly.
    foreach ($ox in -$T, 0, $T) { foreach ($oy in -$T, 0, $T) {
      $st = $g.Save()
      $g.TranslateTransform([single]($cx + $ox), [single]($cy + $oy))
      $g.RotateTransform([single]$ang)
      $g.DrawImage($d, [single](-$w/2), [single](-$h/2), [single]$w, [single]$h)
      $g.Restore($st) } }
  }
  $placedPer += ("{0} {1}/{2}" -f $pass.label, $got, $pass.want)
}
$g.Dispose()
"placed: $n doodles from $($doodles.Count) icons   ($($placedPer -join ', '))   darts thrown: $guard"
$counts = $perIcon | Where-Object { $_ -gt 0 }
"each icon used {0}-{1} times; {2} icons unused" -f ($counts | Measure-Object -Minimum).Minimum, ($counts | Measure-Object -Maximum).Maximum, (@($perIcon | Where-Object { $_ -eq 0 }).Count)

# ---------- the two figures to judge the tile by ------------------------------
# Sampled on a grid rather than every pixel: 2.36 million GetPixel calls took longer than the
# scatter did, and a 4-pixel step is well inside the accuracy this needs.
$step = 4; $hit = 0; $tot = 0
for ($y = 0; $y -lt $T; $y += $step) { for ($x = 0; $x -lt $T; $x += $step) {
  $tot++; if ($layer.GetPixel($x, $y).A -gt 8) { $hit++ } } }
"ink coverage: {0:P2} of the tile        (reference 17.50%)" -f ($hit / [double]$tot)
$rs = @(); for ($i = 0; $i -lt $n; $i++) { $rs += [math]::Sqrt(($pW[$i] * 2 / $Tight) * ($pH[$i] * 2 / $Tight)) }
$rs = $rs | Sort-Object
"icon size:    {0:P2} of the tile side (median), {1:P2} biggest, {2:P2} smallest   (reference 8.86%)" -f `
  ($rs[[int]($n/2)] / $T), ($rs[$n-1] / $T), ($rs[0] / $T)

# ---------- bake both themes ------------------------------------------------
# Recolour in one DrawImage through a colour matrix rather than pixel by pixel. The matrix throws
# the source colour away (the layer is black line art), writes the theme's colour flat, and scales
# the alpha the artwork already has - which keeps the antialiasing on every stroke.
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
