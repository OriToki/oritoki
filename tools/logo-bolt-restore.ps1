# Rebuilds the INSIDE of each hex bolt head in images/logo-plate.png from the owner's original
# drawing (Desktop\logo parts\final logo.png): white ring, black circle, white middle.
#
# Why: logo-bolt.ps1 once greyed the middle, and logo-bolt-white.ps1 (taking it back to white)
# also lightened the thin black circle round it, so the bolt read as damaged. Rather than guess at
# pixels 1 px wide, the inside is resampled from the original.
#
# The plate is the original drawn smaller and moved, so the scale and offset are FOUND, not typed:
# every candidate is scored against the plate's own hexagon outline and circle (the grey middle is
# left out of the score, since that is the part being replaced), and the best one is used.
#
# Run against the plate as it was BEFORE logo-bolt-white.ps1 (-Base), whose outline and circle are
# intact. Only pixels inside each hexagon are written; the outline and everything else stay as the
# plate has them.
param(
  [string]$Base = "",                      # the plate to start from; default images\logo-plate.png
  [string]$Orig = "C:\Users\gilmo\OneDrive\Desktop\logo parts\final logo.png",
  [double]$Inner = 5.6,                    # plate px from the bolt centre that get rewritten
  [switch]$WhatIf
)
Add-Type -AssemblyName System.Drawing
$REPO = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$plateOut = "$REPO\images\logo-plate.png"
if (-not $Base) { $Base = $plateOut }
if (-not ("BoltFit" -as [type])) { Add-Type -TypeDefinition @'
using System;
public static class BoltFit {
  // lightness of the original at a sub-pixel point, bilinear
  static double At(double[] L, int W, int H, double x, double y) {
    int x0 = (int)Math.Floor(x), y0 = (int)Math.Floor(y);
    if (x0 < 0 || y0 < 0 || x0 + 1 >= W || y0 + 1 >= H) return 0;
    double fx = x - x0, fy = y - y0;
    return L[y0*W+x0]*(1-fx)*(1-fy) + L[y0*W+x0+1]*fx*(1-fy) + L[(y0+1)*W+x0]*(1-fx)*fy + L[(y0+1)*W+x0+1]*fx*fy;
  }
  // a plate pixel's footprint in the original, averaged (4x4 supersamples)
  public static double Px(double[] L, int W, int H, double ox, double oy, double s, double u, double v) {
    double sum = 0;
    for (int j = 0; j < 4; j++) for (int i = 0; i < 4; i++) {
      double pu = u + (i + 0.5) / 4.0, pv = v + (j + 0.5) / 4.0;
      sum += At(L, W, H, ox + pu / s, oy + pv / s); }
    return sum / 16.0;
  }
  // score: squared error over the plate window, leaving out the grey middle
  public static double Score(double[] L, int W, int H, double[] P, bool[] use, int pw, int px0, int py0,
                             double ox, double oy, double s) {
    double e = 0; int n = 0;
    for (int v = 0; v < pw; v++) for (int u = 0; u < pw; u++) {
      int k = v*pw+u; if (!use[k]) continue;
      double d = Px(L, W, H, ox, oy, s, px0 + u, py0 + v) - P[k]; e += d*d; n++; }
    return n > 0 ? e / n : 1e18;
  }
}
'@ }
function Lum([System.Drawing.Bitmap]$b) {
  $W = $b.Width; $H = $b.Height; $L = New-Object double[] ($W*$H)
  for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) { $c = $b.GetPixel($x, $y)
    $L[$y*$W+$x] = $(if ($c.A -lt 60) { 0 } else { ($c.R + $c.G + $c.B) / 3.0 }) } }
  ,$L }
$ob = New-Object System.Drawing.Bitmap $Orig
"reading the original ($($ob.Width) x $($ob.Height)) ..."
$OL = Lum $ob; $OW = $ob.Width; $OH = $ob.Height; $ob.Dispose()
$pb = New-Object System.Drawing.Bitmap $Base
# (PowerShell names are case-insensitive: $R below is the window radius, so the results loop uses
# $fit, never $r; and there is no $PW beside $pw.)
# bolt centre in the plate, and a rough centre in the original to search around
$jobs = @(@{ name = "upper"; pc = @(305, 36);  oc = @(939.75, 135.5) },
          @{ name = "lower"; pc = @(363, 215); oc = @(1090, 611) })
$R = 12; $pw = 2*$R + 1
$results = @()
foreach ($j in $jobs) {
  $px0 = $j.pc[0] - $R; $py0 = $j.pc[1] - $R
  $P = New-Object double[] ($pw*$pw); $use = New-Object bool[] ($pw*$pw)
  for ($v = 0; $v -lt $pw; $v++) { for ($u = 0; $u -lt $pw; $u++) {
    $c = $pb.GetPixel($px0+$u, $py0+$v); $l = $(if ($c.A -lt 60) { 0 } else { ($c.R+$c.G+$c.B)/3.0 })
    $P[$v*$pw+$u] = $l
    $du = $u - $R; $dv = $v - $R
    # leave out the greyed middle (inside r 3.5) - it is what is being replaced
    $use[$v*$pw+$u] = (($du*$du + $dv*$dv) -gt 12.25) } }
  $best = 1e18; $bs = 0; $bx = 0; $by = 0
  # coarse, then fine
  foreach ($stage in @(@{ s0 = 0.19; s1 = 0.25; ss = 0.005; r = 30.0; st = 2.0 }, @{ s0 = -0.004; s1 = 0.004; ss = 0.0005; r = 2.0; st = 0.25 })) {
    $cs = $bs; $cx = $bx; $cy = $by
    for ($s = $stage.s0; $s -le $stage.s1 + 1e-9; $s += $stage.ss) {
      $sc = $(if ($stage.s0 -lt 0) { $cs + $s } else { $s })
      for ($dy = -$stage.r; $dy -le $stage.r; $dy += $stage.st) { for ($dx = -$stage.r; $dx -le $stage.r; $dx += $stage.st) {
        $ocx = $(if ($stage.s0 -lt 0) { $cx + $dx } else { $j.oc[0] + $dx })
        $ocy = $(if ($stage.s0 -lt 0) { $cy + $dy } else { $j.oc[1] + $dy })
        # the original point under the plate's top-left corner of the window
        $ox = $ocx - ($R + 0.5) / $sc; $oy = $ocy - ($R + 0.5) / $sc
        $e = [BoltFit]::Score($OL, $OW, $OH, $P, $use, $pw, 0, 0, $ox, $oy, $sc)
        if ($e -lt $best) { $best = $e; $bs = $sc; $bx = $ocx; $by = $ocy } } } } }
  "{0}: scale {1:N4}, original centre ({2:N2}, {3:N2}), rms error {4:N1} levels" -f $j.name, $bs, $bx, $by, [Math]::Sqrt($best)
  $results += ,@{ j = $j; s = $bs; ox = $bx - ($R + 0.5) / $bs; oy = $by - ($R + 0.5) / $bs; px0 = $px0; py0 = $py0 }
}
if ($WhatIf) { $pb.Dispose(); "(WhatIf) not written"; return }
$out = New-Object System.Drawing.Bitmap $pb; $pb.Dispose()
foreach ($fit in $results) {
  $n = 0
  for ($v = 0; $v -lt $pw; $v++) { for ($u = 0; $u -lt $pw; $u++) {
    $du = $u - $R; $dv = $v - $R
    if (($du*$du + $dv*$dv) -gt ($Inner*$Inner)) { continue }
    $l = [BoltFit]::Px($OL, $OW, $OH, $fit.ox, $fit.oy, $fit.s, $u, $v)
    $x = $fit.px0 + $u; $y = $fit.py0 + $v; $c = $out.GetPixel($x, $y)
    $gv = [int][Math]::Max(0, [Math]::Min(255, [Math]::Round($l)))
    $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c.A, $gv, $gv, $gv)); $n++ } }
  "  $($fit.j.name): $n pixels rewritten from the original"
}
$tmp = "$plateOut.tmp"; $out.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png); $out.Dispose()
Move-Item $tmp $plateOut -Force; "written $plateOut"
