# Puts the owner's WHOLE carabiner-and-knot drawing where each of the two cut-out assemblies sits.
#
# Why bother, when the cut already reproduces the mark exactly: the cut can only contain what is
# VISIBLE. Whatever the bolt hanger and the lettering cover is not in it, so the moment a carabiner
# turns, those hidden parts are missing and a hole opens at its top. The owner supplied the piece
# whole and on transparency (Desktop\parts\take it 1.png), which has no holes in it at all.
#
# The transform is found, not typed: the piece is slid and scaled over the CUT layer - which is
# already in exactly the right place, being pixels of the finished drawing - and scored on mean
# grey difference over the cut's own ink. So the search is against a target that is known correct,
# and only over the part of it that is actually visible in the drawing.
#
# Everything is done on the mark's ink box (1058 x 1159), which is the box index.html places the
# layers by, so the numbers here and the numbers there mean the same thing.
param(
  [string]$Piece = "C:\Users\gilmo\OneDrive\Desktop\parts\take it 1.png",
  [string]$CutDir = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad",
  [double]$S0 = 0.36, [double]$S1 = 0.50, [double]$SStep = 0.005,
  [int]$Range = 26, [int]$Sample = 2, [int]$NudgeX = 0, [int]$NudgeY = 0
)
Add-Type -AssemblyName System.Drawing
function Load($p) {
  $fs = [System.IO.File]::OpenRead($p)
  $im = [System.Drawing.Image]::FromStream($fs)
  $b = New-Object System.Drawing.Bitmap($im)
  $im.Dispose(); $fs.Close(); $fs.Dispose()
  $r = New-Object System.Drawing.Rectangle 0, 0, $b.Width, $b.Height
  $d = $b.LockBits($r, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $buf = New-Object 'byte[]' ($d.Stride * $b.Height)
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $buf, 0, $buf.Length)
  $o = @{ W = $b.Width; H = $b.Height; S = $d.Stride; B = $buf }
  $b.UnlockBits($d); $b.Dispose(); return $o
}
$Pc = Load $Piece
"piece: $($Pc.W) x $($Pc.H)"
# NOTE the names. $P and $p are one variable here - PowerShell does not care about case - and the
# byte index $p inside the pixel loop wiped the piece out from under the search. Third time this
# has bitten these scripts; see CLAUDE.md.

foreach ($side in @("work", "back")) {
  $Tg = Load (Join-Path $CutDir ("logo-" + $side + ".png"))
  # the cut's own ink box gives the seed: same left edge, same top, and the width ratio the scale
  $lx = $Tg.W; $hx = -1; $ly = $Tg.H; $hy = -1
  for ($y = 0; $y -lt $Tg.H; $y++) { for ($x = 0; $x -lt $Tg.W; $x++) {
    if ($Tg.B[$y * $Tg.S + $x * 4 + 3] -le 60) { continue }
    if ($x -lt $lx) { $lx = $x }; if ($x -gt $hx) { $hx = $x }
    if ($y -lt $ly) { $ly = $y }; if ($y -gt $hy) { $hy = $y } } }
  $plx = $Pc.W; $phx = -1; $ply = $Pc.H
  for ($y = 0; $y -lt $Pc.H; $y++) { for ($x = 0; $x -lt $Pc.W; $x++) {
    if ($Pc.B[$y * $Pc.S + $x * 4 + 3] -le 60) { continue }
    if ($x -lt $plx) { $plx = $x }; if ($x -gt $phx) { $phx = $x }
    if ($y -lt $ply) { $ply = $y } } }
  $seedS = ($hx - $lx + 1) / [double]($phx - $plx + 1)
  $seedX = $lx - $plx * $seedS + $NudgeX
  $seedY = $ly - $ply * $seedS + $NudgeY
  "{0}: cut ink {1}..{2} x {3}..{4}   seed scale {5:N3} at ({6:N0},{7:N0})" -f $side, $lx, $hx, $ly, $hy, $seedS, $seedX, $seedY

  $bestV = [double]::MaxValue; $bX = 0; $bY = 0; $bS = 0.0
  for ($s = $S0; $s -le $S1 + 1e-9; $s += $SStep) {
    # the piece's opaque pixels at this scale
    $cap = [int](($Pc.W * $Pc.H) / ($Sample * $Sample)) + 16
    $qx = New-Object 'int[]' $cap; $qy = New-Object 'int[]' $cap; $qg = New-Object 'int[]' $cap
    $n = 0
    for ($yy = 0; $yy -lt $Pc.H; $yy += $Sample) {
      for ($xx = 0; $xx -lt $Pc.W; $xx += $Sample) {
        $p = $yy * $Pc.S + $xx * 4
        if ($Pc.B[$p + 3] -le 200) { continue }
        $qx[$n] = [int]($xx * $s); $qy[$n] = [int]($yy * $s)
        $qg[$n] = ([int]$Pc.B[$p] + [int]$Pc.B[$p + 1] + [int]$Pc.B[$p + 2]) / 3
        $n++
      }
    }
    for ($oy = [int]$seedY - $Range; $oy -le [int]$seedY + $Range; $oy += 1) {
      for ($ox = [int]$seedX - $Range; $ox -le [int]$seedX + $Range; $ox += 1) {
        $sum = 0.0; $used = 0
        for ($i = 0; $i -lt $n; $i++) {
          $tx = $ox + $qx[$i]; $ty = $oy + $qy[$i]
          if ($tx -lt 0 -or $ty -lt 0 -or $tx -ge $Tg.W -or $ty -ge $Tg.H) { continue }
          $q = $ty * $Tg.S + $tx * 4
          if ($Tg.B[$q + 3] -le 200) { continue }      # only where the cut actually has ink
          $used++
          $g = ([int]$Tg.B[$q] + [int]$Tg.B[$q + 1] + [int]$Tg.B[$q + 2]) / 3
          $dd = $qg[$i] - $g; if ($dd -lt 0) { $dd = -$dd }
          $sum += $dd
        }
        # Coverage is a GATE, not a reward. Rewarding it pulled the piece up and left, because the
        # cut carries the anchor's diagonal bar - ink the piece does not have - and any position
        # that parked the ring on that bar scored as better covered.
        if ($used -lt 0.55 * $n) { continue }
        $v = $sum / $used
        if ($v -lt $bestV) { $bestV = $v; $bX = $ox; $bY = $oy; $bS = $s }
      }
    }
  }
  "   best: scale {0:N3} at ({1},{2})   score {3:N2}" -f $bS, $bX, $bY, $bestV
  "   -> A.{0}: place the piece at ({1},{2}) scaled {3:N4} on the 1058-wide mark box" -f $side, $bX, $bY, $bS
}
