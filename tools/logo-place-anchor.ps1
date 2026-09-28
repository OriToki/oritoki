# Finds where the owner's WHOLE bolt hanger (Desktop\parts\take it 2.png) sits on each of the two
# anchors in the finished logo.
#
# Needed for the same reason the carabiner needed its own whole drawing: once the hanger's plate is
# moved BEHIND the carabiner - which is what the owner asked for, so the carabiner shows over it
# when the technician swings - anything missing from the plate would show. Cutting the plate out of
# the logo gets nearly all of it, but its outline is shared with the ring it crosses and some of
# that outline goes with the ring. The owner's file has no such holes.
#
# The search is the same as tools/logo-place.ps1: slide and scale the piece over the logo, score
# mean grey difference, but look only inside the one hanger, and only where the logo is not being
# covered by something else.
param(
  [string]$Logo = "C:\Users\gilmo\OneDrive\Desktop\parts\final logo.png",
  [string]$Piece = "C:\Users\gilmo\OneDrive\Desktop\parts\take it 2.png",
  [double]$S0 = 0.215, [double]$S1 = 0.285, [double]$SStep = 0.005,
  [int]$Range = 16, [int]$Sample = 3
)
Add-Type -AssemblyName System.Drawing
function Load($path) {
  $fs = [System.IO.File]::OpenRead($path)
  $im = [System.Drawing.Image]::FromStream($fs)
  $bm = New-Object System.Drawing.Bitmap($im)
  $im.Dispose(); $fs.Close(); $fs.Dispose()
  $r = New-Object System.Drawing.Rectangle 0, 0, $bm.Width, $bm.Height
  $d = $bm.LockBits($r, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $buf = New-Object 'byte[]' ($d.Stride * $bm.Height)
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $buf, 0, $buf.Length)
  $o = @{ W = $bm.Width; H = $bm.Height; S = $d.Stride; B = $buf }
  $bm.UnlockBits($d); $bm.Dispose(); return $o
}
$Lg = Load $Logo
$Pc = Load $Piece
# the logo's ink box - all coordinates reported below are inside it
$lx = $Lg.W; $hx = -1; $ly = $Lg.H; $hy = -1
for ($y = 0; $y -lt $Lg.H; $y++) { for ($x = 0; $x -lt $Lg.W; $x++) {
  if ($Lg.B[$y * $Lg.S + $x * 4 + 3] -le 40) { continue }
  if ($x -lt $lx) { $lx = $x }; if ($x -gt $hx) { $hx = $x }
  if ($y -lt $ly) { $ly = $y }; if ($y -gt $hy) { $hy = $y } } }
$bw = $hx - $lx + 1; $bh = $hy - $ly + 1
"logo ink box $bw x $bh    piece $($Pc.W) x $($Pc.H)"
# the piece's own ink, so the seed can line its corner up with the hanger's
$plx = $Pc.W; $phx = -1; $ply = $Pc.H; $phy = -1
for ($y = 0; $y -lt $Pc.H; $y++) { for ($x = 0; $x -lt $Pc.W; $x++) {
  if ($Pc.B[$y * $Pc.S + $x * 4 + 3] -le 60) { continue }
  if ($x -lt $plx) { $plx = $x }; if ($x -gt $phx) { $phx = $x }
  if ($y -lt $ply) { $ply = $y }; if ($y -gt $phy) { $phy = $y } } }
"piece ink $plx..$phx x $ply..$phy   ($($phx - $plx + 1) x $($phy - $ply + 1))"

# each hanger's window, from the owner's own red and green marks, in the 400-wide grid he drew on
$Kscale = $bw / 400.0
$windows = @(@("upper", 270, -6, 344, 86), @("lower", 327, 176, 400, 264))
foreach ($wnd in $windows) {
  $wx0 = [int]($wnd[1] * $Kscale); $wy0 = [int]($wnd[2] * $Kscale)
  $wx1 = [int]($wnd[3] * $Kscale); $wy1 = [int]($wnd[4] * $Kscale)
  $seedS = ($wx1 - $wx0 + 1) / [double]($phx - $plx + 1)
  $seedX = $wx0 - $plx * $seedS
  $seedY = $wy0 - $ply * $seedS
  "{0}: window {1}..{2} x {3}..{4}   seed scale {5:N3} at ({6:N0},{7:N0})" -f $wnd[0], $wx0, $wx1, $wy0, $wy1, $seedS, $seedX, $seedY

  $bestV = [double]::MaxValue; $bX = 0; $bY = 0; $bS = 0.0
  for ($s = $S0; $s -le $S1 + 1e-9; $s += $SStep) {
    $cap = [int](($Pc.W * $Pc.H) / ($Sample * $Sample)) + 16
    $qx = New-Object 'int[]' $cap; $qy = New-Object 'int[]' $cap; $qg = New-Object 'int[]' $cap
    $n = 0
    for ($yy = 0; $yy -lt $Pc.H; $yy += $Sample) {
      for ($xx = 0; $xx -lt $Pc.W; $xx += $Sample) {
        $pp = $yy * $Pc.S + $xx * 4
        if ($Pc.B[$pp + 3] -le 200) { continue }
        $qx[$n] = [int]($xx * $s); $qy[$n] = [int]($yy * $s)
        $qg[$n] = ([int]$Pc.B[$pp] + [int]$Pc.B[$pp + 1] + [int]$Pc.B[$pp + 2]) / 3
        $n++
      }
    }
    for ($oy = [int]$seedY - $Range; $oy -le [int]$seedY + $Range; $oy++) {
      for ($ox = [int]$seedX - $Range; $ox -le [int]$seedX + $Range; $ox++) {
        $sum = 0.0; $used = 0
        for ($i = 0; $i -lt $n; $i++) {
          $tx = $ox + $qx[$i]; $ty = $oy + $qy[$i]
          if ($tx -lt 0 -or $ty -lt 0 -or $tx -ge $bw -or $ty -ge $bh) { continue }
          $qq = ($ty + $ly) * $Lg.S + ($tx + $lx) * 4
          if ($Lg.B[$qq + 3] -le 200) { continue }
          $used++
          $g = ([int]$Lg.B[$qq] + [int]$Lg.B[$qq + 1] + [int]$Lg.B[$qq + 2]) / 3
          $dd = $qg[$i] - $g; if ($dd -lt 0) { $dd = -$dd }
          $sum += $dd
        }
        if ($used -lt 0.6 * $n) { continue }
        $v = $sum / $used
        if ($v -lt $bestV) { $bestV = $v; $bX = $ox; $bY = $oy; $bS = $s }
      }
    }
  }
  "   best: ({0},{1}) scale {2:N3}   score {3:N2}" -f $bX, $bY, $bS, $bestV
}
