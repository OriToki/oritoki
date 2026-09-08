# Cuts the anchor out of the owner's anchors.png as TWO pieces, because they do different things
# on the page: the bolt hanger is bolted to the building and never moves, while the carabiner,
# the knot and the rope below them swing with the rope - a carabiner turns in its hanger.
#
#   anchor-bolt.png  the hanger plate alone          (fixed)
#   anchor-hang.png  carabiner + knot + rope tail    (rotates about the hanger's clip point)
#
# Also, and this is the point of the whole exercise: the ROPE and KNOT get the same braided
# texture as the drawn ropes, and their outline is recoloured from black to the drawn rope's own
# edge grey - the knot is the same rope, so it has to be built out of the same rope. The knot's
# LINEWORK is otherwise untouched: its shape is the owner's drawing, not mine.
#
# The carabiner's inner opening is punched transparent: it is a hole, and the page should show
# through it. The metal's own white fill stays, exactly as in climber.png.
param(
  [int]$X1 = 1014, [int]$Y1 = 540, [int]$X2 = 1298, [int]$Y2 = 1552,
  [int]$SplitY = 150,             # crop row where the hanger ends and the carabiner starts
  [int]$Overlap = 4,              # the two pieces share this many rows, so no hairline shows
  # One pixel inside each opening you can actually see through. Everything else that is enclosed
  # and pale is METAL - the plate, the bolt head, the hanger's tongue, the carabiner's body - and
  # keeps its white fill, exactly as climber.png does. Found by labelling every enclosed region on
  # the source drawing and reading off which ones are holes; see tools/README.md.
  [int[]]$Holes = @(150,350,   # the carabiner's opening
                    136,180),  # the hanger's eye, the part of it seen under the tongue
  # Enclosed and pale, but NOT holes - all of these are metal, and punching them out took bites
  # out of the hardware:
  #   (102,92)  and (115,131)  the plate itself. The tongue crosses the plate and cuts its white
  #                            fill into separate pieces; those pieces are still the plate.
  #   (223,201)                the carabiner's nose, where the gate closes onto it.
  [double]$Tile = 14.0, [double]$LineW = 5.0,
  [int]$OutW = 128,               # asset width in px (the pieces are shown ~11px wide)
  [string]$OutDir = "c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images"
)
Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap("C:\Users\gilmo\OneDrive\Desktop\anchors.png")
$w = $X2 - $X1; $h = $Y2 - $Y1
$crop = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gg = [System.Drawing.Graphics]::FromImage($crop)
$gg.DrawImage($src, (New-Object System.Drawing.Rectangle(0,0,$w,$h)), (New-Object System.Drawing.Rectangle($X1,$Y1,$w,$h)), [System.Drawing.GraphicsUnit]::Pixel)
$gg.Dispose(); $src.Dispose()

$N = $w * $h
$lum = New-Object byte[] $N
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
  $c = $crop.GetPixel($x, $y); $lum[$y*$w + $x] = [byte](($c.R + $c.G + $c.B) / 3) } }

function FloodPale([int]$sx, [int]$sy, [bool[]]$mark) {
  if ($lum[$sy*$w + $sx] -le 233) { return }
  $st = New-Object System.Collections.Generic.Stack[int]
  $st.Push($sy*$w + $sx); $mark[$sy*$w + $sx] = $true
  while ($st.Count -gt 0) {
    $i = $st.Pop(); $x = $i % $w; $y = [int](($i - $x) / $w)
    foreach ($d in @(@(1,0), @(-1,0), @(0,1), @(0,-1))) {
      $nx = $x + $d[0]; $ny = $y + $d[1]
      if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) { $j = $ny*$w + $nx
        if (-not $mark[$j] -and $lum[$j] -gt 233) { $mark[$j] = $true; $st.Push($j) } } } }
}
# outer background, and separately the carabiner's opening
$clearMask = New-Object bool[] $N
for ($x = 0; $x -lt $w; $x++) { FloodPale $x 0 $clearMask; FloodPale $x ($h-1) $clearMask }
for ($y = 0; $y -lt $h; $y++) { FloodPale 0 $y $clearMask; FloodPale ($w-1) $y $clearMask }
for ($k = 0; $k -lt $Holes.Length; $k += 2) { FloodPale $Holes[$k] $Holes[$k+1] $clearMask }

# repaint: rope fill -> weave, rope outline -> the drawn rope's edge grey, holes -> clear
$done = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$clear = [System.Drawing.Color]::FromArgb(0,0,0,0)
$core  = [System.Drawing.Color]::FromArgb(255, 238, 238, 238)
$dark  = [System.Drawing.Color]::FromArgb(255, 21, 21, 21)
$edge  = [System.Drawing.Color]::FromArgb(255, 97, 97, 97)     # #616161, as .rope-out
$r2 = [math]::Sqrt(2)
# a pixel counts as rope OUTLINE if it is dark AND sits next to the rope's fill
function NearRope([int]$x, [int]$y) {
  for ($dy = -3; $dy -le 3; $dy++) { for ($dx = -3; $dx -le 3; $dx++) {
    $nx = $x+$dx; $ny = $y+$dy
    if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $w -and $ny -lt $h) {
      $L = $lum[$ny*$w + $nx]; if ($L -ge 190 -and $L -le 228) { return $true } } } }
  return $false
}
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
  $i = $y*$w + $x
  if ($clearMask[$i]) { $done.SetPixel($x, $y, $clear); continue }
  $L = $lum[$i]
  if ($L -ge 190 -and $L -le 228) {                       # rope / knot fill -> weave
    $u = (($x + $y) / $r2) % $Tile; if ($u -lt 0) { $u += $Tile }
    $v = (($x - $y) / $r2) % $Tile; if ($v -lt 0) { $v += $Tile }
    if ($u -lt $LineW -or $v -lt $LineW) { $done.SetPixel($x, $y, $dark) } else { $done.SetPixel($x, $y, $core) }
  } elseif ($L -lt 120 -and (NearRope $x $y)) {           # the rope's own outline -> edge grey
    $done.SetPixel($x, $y, $edge)
  } else { $done.SetPixel($x, $y, $crop.GetPixel($x, $y)) } } }
$crop.Dispose()

# The hanger does not stop at the split: its tongue runs on diagonally through the carabiner, down
# to about row 256. Left in the moving piece it tore away from the plate as the carabiner turned.
# These two bounds follow that tongue down, so each piece can keep only what belongs to it.
function TongueL([double]$y) { return 88 + 0.42 * ($y - 146) }
function TongueR([double]$y) { return 132 + 0.30 * ($y - 146) }
$TongueEnd = 258

function SavePiece([int]$y0, [int]$y1, [string]$name, [bool]$isBolt) {
  $ph = $y1 - $y0
  $piece = New-Object System.Drawing.Bitmap($w, $ph, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $clr = [System.Drawing.Color]::FromArgb(0,0,0,0)
  for ($y = 0; $y -lt $ph; $y++) { for ($x = 0; $x -lt $w; $x++) {
    $cy = $y0 + $y
    $inTongue = ($cy -ge $SplitY -and $cy -le $TongueEnd -and $x -ge (TongueL $cy) -and $x -le (TongueR $cy))
    # below the split the bolt piece keeps ONLY the tongue; the hanging piece keeps everything but
    if ($isBolt -and $cy -ge $SplitY -and -not $inTongue) { $piece.SetPixel($x, $y, $clr) }
    elseif (-not $isBolt -and $inTongue) { $piece.SetPixel($x, $y, $clr) }
    else { $piece.SetPixel($x, $y, $done.GetPixel($x, $cy)) } } }
  $oh = [int]([math]::Round($ph * $OutW / $w))
  $out = New-Object System.Drawing.Bitmap($OutW, $oh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g2 = [System.Drawing.Graphics]::FromImage($out)
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g2.DrawImage($piece, 0, 0, $OutW, $oh); $g2.Dispose(); $piece.Dispose()
  $out.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png); $out.Dispose()
  "  $name  ${OutW}x$oh   (crop rows $y0..$y1)"
}
SavePiece 0 ($TongueEnd + 4) "anchor-bolt.png" $true
SavePiece ($SplitY - $Overlap) $h "anchor-hang.png" $false
$done.Dispose()

# numbers index.html needs, as fractions so they survive any scale
$pivotX = 215.0; $pivotY = $SplitY + 8.0
"geometry (fractions of the anchor's WIDTH unless said otherwise):"
"  rope centre      {0:N4}" -f (119.0 / $w)
"  rope width       {0:N4}   -> anchor {1:N1}px gives the drawn rope's 1.55px" -f (41.0 / $w), (1.552 * $w / 41.0)
"  bolt piece       {0:N4} tall" -f (($SplitY + $Overlap) / $w)
"  hang piece       {0:N4} tall" -f (($h - $SplitY + $Overlap) / $w)
"  pivot in hang    x {0:N4}  y {1:N4}" -f ($pivotX / $w), (($pivotY - ($SplitY - $Overlap)) / $w)
