# Prepares the header mark from the owner's finished drawing, and measures the two points where
# the page's ropes have to take over from it.
#
# This replaces tools/logo-compose.ps1, which cut ONE flat picture into four layers so that the
# carabiners could swivel. Every placement problem this mark ever had came from that cut: the
# pieces had to be found by fitting them back against the finished drawing, and a fit can be right
# on every piece and still get the order of them wrong - which is what left a rope loop sitting on
# top of a carabiner instead of threaded through it. The owner's new drawing is correct as drawn,
# so it is used AS DRAWN. Nothing to fit, nothing to get wrong. The cost is that the carabiners no
# longer turn with the ropes; the ropes still swing, and they leave the knots where the drawing
# says they leave them.
#
# The mark is cropped to its own ink, so every fraction below is a fraction of what you see, and
# index.html can place it from the two stems alone.
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\parts\final logo.png",
  [string]$Out = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images\logo-mark.png",
  [int]$OutW = 400
)
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap($Src)
$rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
$dat = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $dat.Stride
$buf = New-Object 'byte[]' ($stride * $bmp.Height)
[System.Runtime.InteropServices.Marshal]::Copy($dat.Scan0, $buf, 0, $buf.Length)
$bmp.UnlockBits($dat)
$wid = $bmp.Width; $hei = $bmp.Height
"source: $wid x $hei"

$lx = $wid; $hx = -1; $ly = $hei; $hy = -1
for ($y = 0; $y -lt $hei; $y++) {
  for ($x = 0; $x -lt $wid; $x++) {
    if ($buf[$y * $stride + $x * 4 + 3] -le 40) { continue }
    if ($x -lt $lx) { $lx = $x }; if ($x -gt $hx) { $hx = $x }
    if ($y -lt $ly) { $ly = $y }; if ($y -gt $hy) { $hy = $y }
  }
}
$bw = $hx - $lx + 1; $bh = $hy - $ly + 1
"ink box: x $lx..$hx  y $ly..$hy   ($bw x $bh)"

# --- the two stems: where a knot's cord stops and the rope carries on --------------------------
# The cord is the only LIGHT GREY in the drawing - letters and hardware are white, outlines black -
# so each strand can be found by colour. Measured in the drawing's own pixels; fractions are of the
# ink box, which is what index.html places the mark by.
# The two assemblies overlap in height - the lower carabiner reaches up past the upper knot's cord
# - so each strand is looked for in its own window, not in a band of rows. Without the x limits the
# upper search walked straight into the lower carabiner and reported its ring as the cord.
function Strand($y0, $y1, $ax, $bx2) {
  $bestY = -1
  for ($y = $y1; $y -ge $y0 -and $bestY -lt 0; $y--) {
    $run = 0; $best = 0; $bestEnd = -1
    for ($x = $ax; $x -le $bx2; $x++) {
      $p = $y * $stride + $x * 4
      $ok = $false
      if ($buf[$p + 3] -ge 250) {
        $g = ([int]$buf[$p] + [int]$buf[$p + 1] + [int]$buf[$p + 2]) / 3
        if ($g -ge 170 -and $g -le 232) { $ok = $true }
      }
      if ($ok) { $run++; if ($run -gt $best) { $best = $run; $bestEnd = $x } } else { $run = 0 }
    }
    # a cord core is a good dozen pixels wide; anything less is a highlight or an edge
    if ($best -ge 12) { $bestY = $y; $script:sw = $best; $script:sx = $bestEnd - $best / 2.0 }
  }
  return $bestY
}
# name, rows to search, columns to search - the windows are in the drawing's own pixels and hold
# only the one cord each. Re-measure them if the mark is redrawn.
foreach ($band in @(
    @("work (upper)",   $ly, [int]($ly + $bh * 0.62), [int]($lx + $bw * 0.68), [int]($lx + $bw * 0.80)),
    @("backup (lower)", [int]($ly + $bh * 0.62), $hy, [int]($lx + $bw * 0.83), [int]($lx + $bw * 0.96)))) {
  $y = Strand $band[1] $band[2] $band[3] $band[4]
  if ($y -lt 0) { "  $($band[0]): not found"; continue }
  "  {0,-14} tip ({1:N0},{2})  core {3}px  ->  stem ({4:N4}, {5:N4})" -f `
    $band[0], $script:sx, $y, $script:sw, (($script:sx - $lx) / $bw), (($y - $ly) / $bh)
}

$outH = [int][Math]::Round($OutW * $bh / $bw)
$small = New-Object System.Drawing.Bitmap($OutW, $outH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g2 = [System.Drawing.Graphics]::FromImage($small)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g2.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g2.DrawImage($bmp, (New-Object System.Drawing.Rectangle 0, 0, $OutW, $outH), $lx, $ly, $bw, $bh, [System.Drawing.GraphicsUnit]::Pixel)
$g2.Dispose()
$small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose(); $bmp.Dispose()
""
"wrote $Out   ($OutW x $outH)"
"index.html:  A.markAspect = $bh / $bw"

