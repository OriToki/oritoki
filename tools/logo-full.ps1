# Prepares the company logo - the owner's finished mark, the one that goes in the footer, the
# browser tab and join.html's header. Not the header mark on index.html: that one is five moving
# layers, because the technician rappels out of it, and it is built by tools/logo-layers.ps1.
#
# The supplied file is FLAT: 1254x1254, fully opaque, with a cream ground baked in. On the footer's
# dark panel a cream square would read as a sticker, so the ground is keyed out first.
#
# Keyed by FLOODING IN FROM THE BORDER, not by matching the colour everywhere. The lettering's
# white (255,255,255) and the cream (249,248,239) are sixteen levels apart in one channel, which is
# close enough that a plain colour match eats into the letters. Nothing inside a letter touches the
# border, so a flood cannot reach it.
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\FINAL LOGO.png",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [int]$OutW = 560,          # the footer shows it around 150px, so this is generous for any screen
  [int]$IconW = 192,         # the browser tab and the apple-touch icon
  # The tab icon is TINTED. At sixteen pixels a white mark inside a black outline is a grey smudge
  # on a light tab bar and invisible on a dark one; one solid colour is the only thing that reads
  # at that size. This is the site's accent orange, so the tab matches the buttons.
  [string]$IconTint = "#f97316"
)
Add-Type -AssemblyName System.Drawing
$fs = [System.IO.File]::OpenRead($Src)
$im = [System.Drawing.Image]::FromStream($fs)
# NOT $src - that is the PATH parameter, and PowerShell treats the two as one variable.
$srcBmp = New-Object System.Drawing.Bitmap($im)
$im.Dispose(); $fs.Close(); $fs.Dispose()
$W = $srcBmp.Width; $H = $srcBmp.Height
$rect = New-Object System.Drawing.Rectangle 0, 0, $W, $H
$dat = $srcBmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$S = $dat.Stride
$B = New-Object 'byte[]' ($S * $H)
[System.Runtime.InteropServices.Marshal]::Copy($dat.Scan0, $B, 0, $B.Length)
"source $W x $H"

# Is there a ground to key out at all? The owner sent this file twice - once flat on cream, once on
# transparency - and keying the second one would be a disaster: its corner reads as black, so the
# flood would set off hunting black and eat the mark's own outline. A transparent corner means the
# work is already done.
$KeyOut = ($B[3] -gt 200)
if (-not $KeyOut) { "corner is already transparent - nothing to key out" }
# the ground's colour, read off a corner rather than assumed
$gB = [int]$B[0]; $gG = [int]$B[1]; $gR = [int]$B[2]
if ($KeyOut) { "ground colour: R$gR G$gG B$gB" }
$TOL = 26
$clear = New-Object 'bool[]' ($W * $H)
$stk = New-Object System.Collections.Generic.Stack[int]
for ($x = 0; $x -lt $W; $x++) {
  foreach ($y in @(0, ($H - 1))) { $i = $y * $W + $x; if (-not $clear[$i]) { $clear[$i] = $true; $stk.Push($i) } }
}
for ($y = 0; $y -lt $H; $y++) {
  foreach ($x in @(0, ($W - 1))) { $i = $y * $W + $x; if (-not $clear[$i]) { $clear[$i] = $true; $stk.Push($i) } }
}
$n = 0
while ($KeyOut -and $stk.Count -gt 0) {
  $j = $stk.Pop(); $jy = [Math]::Floor($j / $W); $jx = $j - $jy * $W
  $p = $jy * $S + $jx * 4
  $dr = [Math]::Abs([int]$B[$p + 2] - $gR); $dg = [Math]::Abs([int]$B[$p + 1] - $gG); $db = [Math]::Abs([int]$B[$p] - $gB)
  if ([Math]::Max($dr, [Math]::Max($dg, $db)) -gt $TOL) { continue }
  $n++
  foreach ($dd in @(@(1, 0), @(-1, 0), @(0, 1), @(0, -1))) {
    $nx = $jx + $dd[0]; $ny = $jy + $dd[1]
    if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $W -or $ny -ge $H) { continue }
    $k = $ny * $W + $nx
    if ($clear[$k]) { continue }
    $clear[$k] = $true; $stk.Push($k)
  }
}
if ($KeyOut) { "ground: $n px keyed out" }
# Write it back with a soft edge: a pixel next to the ground fades by how close to the ground it
# is, so the mark does not come away with a hard cream fringe around it.
if ($KeyOut) {
for ($y = 0; $y -lt $H; $y++) {
  for ($x = 0; $x -lt $W; $x++) {
    $p = $y * $S + $x * 4
    if ($clear[$y * $W + $x]) { $B[$p + 3] = 0; continue }
    $dr = [Math]::Abs([int]$B[$p + 2] - $gR); $dg = [Math]::Abs([int]$B[$p + 1] - $gG); $db = [Math]::Abs([int]$B[$p] - $gB)
    $d = [Math]::Max($dr, [Math]::Max($dg, $db))
    if ($d -lt $TOL * 2) {
      $touching = $false
      for ($dy = -1; $dy -le 1 -and -not $touching; $dy++) {
        for ($dx = -1; $dx -le 1; $dx++) {
          $nx = $x + $dx; $ny = $y + $dy
          if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $W -or $ny -ge $H) { continue }
          if ($clear[$ny * $W + $nx]) { $touching = $true; break }
        }
      }
      if ($touching) { $B[$p + 3] = [byte]([Math]::Min(255, $d * 255 / ($TOL * 2))) }
    }
  }
}
}
[System.Runtime.InteropServices.Marshal]::Copy($B, 0, $dat.Scan0, $B.Length)
$srcBmp.UnlockBits($dat)

# crop to the ink
$lx = $W; $hx = -1; $ly = $H; $hy = -1
for ($y = 0; $y -lt $H; $y++) {
  for ($x = 0; $x -lt $W; $x++) {
    if ($B[$y * $S + $x * 4 + 3] -le 24) { continue }
    if ($x -lt $lx) { $lx = $x }; if ($x -gt $hx) { $hx = $x }
    if ($y -lt $ly) { $ly = $y }; if ($y -gt $hy) { $hy = $y }
  }
}
$bw = $hx - $lx + 1; $bh = $hy - $ly + 1
"ink box: $lx..$hx x $ly..$hy   ($bw x $bh)"

foreach ($job in @(@("logo-full.png", $OutW, $false), @("icon.png", $IconW, $true))) {
  $name = $job[0]; $wide = $job[1]; $square = $job[2]
  if ($square) {
    # the tab icon is square, and the mark should fill it - so it is fitted to the longer side and
    # centred, with nothing else added
    $side = [Math]::Max($bw, $bh)
    $sc = $wide / [double]$side
    $iw = [int]($bw * $sc); $ih = [int]($bh * $sc)
    $bmp = New-Object System.Drawing.Bitmap($wide, $wide, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcBmp, (New-Object System.Drawing.Rectangle ([int](($wide - $iw) / 2)), ([int](($wide - $ih) / 2)), $iw, $ih),
                       $lx, $ly, $bw, $bh, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    # Only the OUTLINE takes the tint. The letters stay white and the rope stays grey, exactly as
    # the owner drew them; what was black is orange instead. A flat ramp does it: a pixel that is
    # black goes fully to the tint, one at $INKMAX keeps itself, and the antialiasing in between
    # slides across - so the outline has no stepped edge where it meets a letter.
    # $INKMAX sits below the rope's grey (about 200) and the hex nut's (about 150), so neither is
    # touched.
    $INKMAX = 130
    $tr = [Convert]::ToInt32($IconTint.Substring(1, 2), 16)
    $tg = [Convert]::ToInt32($IconTint.Substring(3, 2), 16)
    $tb = [Convert]::ToInt32($IconTint.Substring(5, 2), 16)
    $ir = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
    $idat = $bmp.LockBits($ir, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $iS = $idat.Stride; $iB = New-Object 'byte[]' ($iS * $bmp.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($idat.Scan0, $iB, 0, $iB.Length)
    for ($iy = 0; $iy -lt $bmp.Height; $iy++) {
      for ($ix = 0; $ix -lt $bmp.Width; $ix++) {
        $ip = $iy * $iS + $ix * 4
        if ($iB[$ip + 3] -eq 0) { continue }
        $L = ([int]$iB[$ip] + [int]$iB[$ip + 1] + [int]$iB[$ip + 2]) / 3
        if ($L -ge $INKMAX) { continue }
        $k = $L / $INKMAX                      # 0 = black, 1 = at the threshold
        $iB[$ip]     = [byte][Math]::Round($tb * (1 - $k) + [int]$iB[$ip] * $k)
        $iB[$ip + 1] = [byte][Math]::Round($tg * (1 - $k) + [int]$iB[$ip + 1] * $k)
        $iB[$ip + 2] = [byte][Math]::Round($tr * (1 - $k) + [int]$iB[$ip + 2] * $k)
      }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($iB, 0, $idat.Scan0, $iB.Length)
    $bmp.UnlockBits($idat)
  } else {
    $ih = [int][Math]::Round($wide * $bh / $bw)
    $bmp = New-Object System.Drawing.Bitmap($wide, $ih, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcBmp, (New-Object System.Drawing.Rectangle 0, 0, $wide, $ih), $lx, $ly, $bw, $bh, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
  }
  $fp = Join-Path $OutDir $name
  $bmp.Save($fp, [System.Drawing.Imaging.ImageFormat]::Png)
  "wrote $fp   ($($bmp.Width) x $($bmp.Height))"
  if (-not $square) { $bmp.Dispose(); continue }

  # ---- the small tab sizes, drawn on purpose rather than shrunk ---------------------------------
  # A browser given only a 192 will squeeze it into the 16 pixels a tab has, and the outline - one
  # pixel of orange at that size - washes out to a grey smear. So each small size is made from the
  # master with its ORANGE BLED OUTWARD first: the tint is pushed one step into the white beside it
  # per 32 pixels of shrink, which keeps the outline's weight on screen roughly constant. The white
  # letters and the counters stay; only the line gets its thickness back.
  foreach ($px in @(48, 32, 16)) {
    $grow = [int][Math]::Ceiling(($IconW - $px) / 64.0)
    $work = New-Object System.Drawing.Bitmap($bmp)
    for ($pass = 0; $pass -lt $grow; $pass++) {
      $wr = New-Object System.Drawing.Rectangle 0, 0, $work.Width, $work.Height
      $wd = $work.LockBits($wr, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
      $wS = $wd.Stride; $wB = New-Object 'byte[]' ($wS * $work.Height)
      [System.Runtime.InteropServices.Marshal]::Copy($wd.Scan0, $wB, 0, $wB.Length)
      $src2 = $wB.Clone()
      for ($yy = 0; $yy -lt $work.Height; $yy++) {
        for ($xx = 0; $xx -lt $work.Width; $xx++) {
          $wp = $yy * $wS + $xx * 4
          if ($src2[$wp + 3] -eq 0) { continue }
          # already the tint? leave it
          if ([Math]::Abs([int]$src2[$wp + 2] - $tr) -lt 30 -and [Math]::Abs([int]$src2[$wp + 1] - $tg) -lt 30) { continue }
          $touch = $false
          for ($dy2 = -1; $dy2 -le 1 -and -not $touch; $dy2++) {
            for ($dx2 = -1; $dx2 -le 1; $dx2++) {
              $nx2 = $xx + $dx2; $ny2 = $yy + $dy2
              if ($nx2 -lt 0 -or $ny2 -lt 0 -or $nx2 -ge $work.Width -or $ny2 -ge $work.Height) { continue }
              $np = $ny2 * $wS + $nx2 * 4
              if ($src2[$np + 3] -eq 0) { continue }
              if ([Math]::Abs([int]$src2[$np + 2] - $tr) -lt 30 -and [Math]::Abs([int]$src2[$np + 1] - $tg) -lt 30) { $touch = $true; break }
            }
          }
          if ($touch) { $wB[$wp] = [byte]$tb; $wB[$wp + 1] = [byte]$tg; $wB[$wp + 2] = [byte]$tr }
        }
      }
      [System.Runtime.InteropServices.Marshal]::Copy($wB, 0, $wd.Scan0, $wB.Length)
      $work.UnlockBits($wd)
    }
    $small = New-Object System.Drawing.Bitmap($px, $px, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gs = [System.Drawing.Graphics]::FromImage($small)
    $gs.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gs.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gs.DrawImage($work, (New-Object System.Drawing.Rectangle 0, 0, $px, $px))
    $gs.Dispose(); $work.Dispose()
    $sp = Join-Path $OutDir ("icon-$px.png")
    $small.Save($sp, [System.Drawing.Imaging.ImageFormat]::Png)
    "wrote $sp   ($px x $px, outline grown $grow)"
    $small.Dispose()
  }
  $bmp.Dispose()
}
$srcBmp.Dispose()
