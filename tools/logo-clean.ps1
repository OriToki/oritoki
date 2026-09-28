# Tidies artwork that was separated by hand in Paint.
#
# Cutting the pieces apart left every repainted edge ragged - stair-steps and wobble a few pixels
# deep, with no anti-aliasing - which at the size the mark is shown reads as a furry outline.
#
# The drawing only ever uses four inks: near-black outline, near-white body, the rope's light
# grey and the bolt head's darker grey. So each pixel is classified as one of those, each class
# is smoothed as its own mask, and the picture is rebuilt from the smoothed masks. That removes
# hand-drawn wobble without touching the design: a jagged edge averages back to the line it was
# meant to be, while a real corner is held up by the whole region behind it.
#
# PowerShell variable names are case-insensitive: param names and locals must not collide.
param(
  [string[]]$SrcPaths = @(
    "C:\Users\gilmo\OneDrive\Desktop\knot carabiner anchor.png",
    "C:\Users\gilmo\OneDrive\Desktop\only ori toki.png"
  ),
  [string]$OutDir = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\883d0638-729b-43b1-919a-037d25f6b24f\scratchpad",
  [int]$Radius = 3        # box radius, in source px. Features here are 100-900px across.
)
Add-Type -AssemblyName System.Drawing

# the four inks, sampled off the artwork
$inks = @(
  @(11, 11, 11),      # 1 outline
  @(250, 250, 250),   # 2 body
  @(200, 200, 201),   # 3 rope grey
  @(140, 140, 140)    # 4 bolt head
)

foreach ($srcPath in $SrcPaths) {
  $bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
  $W = $bmp.Width; $H = $bmp.Height
  $rect = New-Object System.Drawing.Rectangle 0, 0, $W, $H
  $lb = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride = $lb.Stride
  $bytes = New-Object 'byte[]' ($stride * $H)
  [System.Runtime.InteropServices.Marshal]::Copy($lb.Scan0, $bytes, 0, $bytes.Length)
  $bmp.UnlockBits($lb); $bmp.Dispose()

  $N = $W * $H
  # one mask per ink, plus one for "any ink at all" which becomes the alpha
  $mask = @( (New-Object 'single[]' $N), (New-Object 'single[]' $N), (New-Object 'single[]' $N), (New-Object 'single[]' $N) )
  $any = New-Object 'single[]' $N
  for ($y = 0; $y -lt $H; $y++) {
    $r = $y * $stride; $o = $y * $W
    for ($x = 0; $x -lt $W; $x++) {
      $i = $r + $x * 4
      $a = $bytes[$i + 3]
      if ($a -le 40) { continue }
      $any[$o + $x] = 1
      $lum = $bytes[$i + 2] * 0.299 + $bytes[$i + 1] * 0.587 + $bytes[$i] * 0.114
      $k = if ($lum -lt 70) { 0 } elseif ($lum -gt 225) { 1 } elseif ($lum -gt 172) { 2 } else { 3 }
      $mask[$k][$o + $x] = 1
    }
  }

  # separable box blur, so the cost does not grow with the radius
  function BoxBlur($src, [int]$w, [int]$h, [int]$rad) {
    $tmp = New-Object 'single[]' ($w * $h)
    $dst = New-Object 'single[]' ($w * $h)
    $den = 2 * $rad + 1
    for ($y = 0; $y -lt $h; $y++) {
      $o = $y * $w; $sum = 0.0
      for ($x = -$rad; $x -le $rad; $x++) { if ($x -ge 0 -and $x -lt $w) { $sum += $src[$o + $x] } }
      for ($x = 0; $x -lt $w; $x++) {
        $tmp[$o + $x] = $sum / $den
        $out = $x - $rad; $inn = $x + $rad + 1
        if ($out -ge 0) { $sum -= $src[$o + $out] }
        if ($inn -lt $w) { $sum += $src[$o + $inn] }
      }
    }
    for ($x = 0; $x -lt $w; $x++) {
      $sum = 0.0
      for ($y = -$rad; $y -le $rad; $y++) { if ($y -ge 0 -and $y -lt $h) { $sum += $tmp[$y * $w + $x] } }
      for ($y = 0; $y -lt $h; $y++) {
        $dst[$y * $w + $x] = $sum / $den
        $out = $y - $rad; $inn = $y + $rad + 1
        if ($out -ge 0) { $sum -= $tmp[$out * $w + $x] }
        if ($inn -lt $h) { $sum += $tmp[$inn * $w + $x] }
      }
    }
    return $dst
  }

  for ($k = 0; $k -lt 4; $k++) { $mask[$k] = BoxBlur $mask[$k] $W $H $Radius }
  $anyB = BoxBlur $any $W $H $Radius

  $outBmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $obRect = New-Object System.Drawing.Rectangle 0, 0, $W, $H
  $ob = $outBmp.LockBits($obRect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $obStride = $ob.Stride
  $obBytes = New-Object 'byte[]' ($obStride * $H)
  for ($y = 0; $y -lt $H; $y++) {
    $o = $y * $W; $r = $y * $obStride
    for ($x = 0; $x -lt $W; $x++) {
      $p = $o + $x
      # Alpha: the smoothed coverage, pushed back to a hard edge with a narrow ramp so the shape
      # keeps its size instead of bleeding outward by the blur radius.
      $cov = ($anyB[$p] - 0.5) * 3.2 + 0.5
      if ($cov -le 0.004) { continue }
      if ($cov -gt 1) { $cov = 1 }
      # The SAME ramp on every ink, not just on the alpha. Blending the raw blurred masks left
      # each internal boundary - the black outline against the white body, the gate against the
      # frame - smeared across the whole blur radius, which at this size read as out of focus.
      # Sharpened, a boundary gets a one-pixel edge and the regions stay flat.
      $ws = @(0.0, 0.0, 0.0, 0.0)
      $wsum = 0.0
      for ($k = 0; $k -lt 4; $k++) {
        $v = ($mask[$k][$p] - 0.5) * 3.2 + 0.5
        if ($v -lt 0) { $v = 0 } elseif ($v -gt 1) { $v = 1 }
        $ws[$k] = $v; $wsum += $v
      }
      if ($wsum -le 0.0001) {
        # nothing dominant (a three-way corner): fall back to the unsharpened weights
        for ($k = 0; $k -lt 4; $k++) { $ws[$k] = $mask[$k][$p]; $wsum += $ws[$k] }
        if ($wsum -le 0.0001) { continue }
      }
      $rr = 0.0; $gg = 0.0; $bb = 0.0
      for ($k = 0; $k -lt 4; $k++) {
        $wk = $ws[$k] / $wsum
        if ($wk -le 0) { continue }
        $rr += $wk * $inks[$k][0]; $gg += $wk * $inks[$k][1]; $bb += $wk * $inks[$k][2]
      }
      $i = $r + $x * 4
      $obBytes[$i]     = [byte][Math]::Min(255, [Math]::Max(0, [int]$bb))
      $obBytes[$i + 1] = [byte][Math]::Min(255, [Math]::Max(0, [int]$gg))
      $obBytes[$i + 2] = [byte][Math]::Min(255, [Math]::Max(0, [int]$rr))
      $obBytes[$i + 3] = [byte][int]([Math]::Round($cov * 255))
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($obBytes, 0, $ob.Scan0, $obBytes.Length)
  $outBmp.UnlockBits($ob)
  $leaf = [System.IO.Path]::GetFileNameWithoutExtension($srcPath)
  $dest = Join-Path $OutDir ("clean - " + $leaf + ".png")
  $outBmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
  $outBmp.Dispose()
  "cleaned $leaf -> $dest"
}
