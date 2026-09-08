# Builds the ORITOKI wordmark: "Or" over "tok", with the two dotted i's replaced by an anchor -
# bolt hanger, locking carabiner, knot - and the rope running on down out of each knot.
#
# The two rope stems are the whole point: they land at exactly the fractions of the strip where
# index.html draws its two ropes (A.workTopX and A.backupX), so the SVG ropes continue out of the
# knots with no seam. Change those fractions and RopeL/RopeR here have to change with them.
#
# Drawn at 8x the size it is shown at, in black on transparent, like the rest of this artwork -
# the header inverts it for the dark theme.
param(
  [double]$Scale = 8,             # canvas px per display px
  [double]$RopeL = 0.44,          # working rope   \ fractions of the 97px strip, from index.html
  [double]$RopeR = 0.573,         # backup rope    /
  [double]$StripW = 97,
  [double]$AnchorW = 10.8,        # display px - at this width the anchor's own rope is exactly
                                  # the 1.55px the page draws, so the two meet with no step
  [double]$AnchorRopeX = 0.419,   # where the rope sits across the anchor asset
  # Sizes and leading are the owner's, measured off the layout he drew (tools/logo-arrangement.png)
  # against the anchor's known 10.8px width: cap height 36.3 for "Or", 25.5 for "tok", and the two
  # lines almost touching. "tok" is the wider word at these sizes, so it hangs out to the left -
  # that stagger is deliberate, it is in the drawing.
  [double]$OrSize = 48,           # font size for "Or"  (display px)
  [double]$TokSize = 35,          # font size for "tok"
  [double]$LineGap = 2,           # from the bottom of "Or"'s ink to the top of "tok"'s
  [double]$AnchorTopR = 1,        # the "Or" anchor hangs from here  \ only sets the canvas
  [double]$AnchorTopL = 37,       # the "tok" one hangs lower        / height; the page places
                                  # them itself, from A.anchorTopBack / anchorTopWork
  [double]$Pad = 2,
  # Only the LETTERING changes with the theme. The anchors and the rope keep their own colours in
  # both, exactly as climber.png does - a white carabiner with black linework reads on either
  # background, and the rope has to match the SVG ropes it continues into.
  [string]$OutDir = "c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images"
)
Add-Type -AssemblyName System.Drawing

# Only for the canvas height. The anchor used to be one images/anchor.png; it is two pieces now
# (the hanger is fixed, the carabiner swings), and they are the same size, so either will do.
$anchor = New-Object System.Drawing.Bitmap("c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images\anchor-hang.png")
$anchorH = $AnchorW * $anchor.Height / $anchor.Width

# the anchors sit at the rope fractions; everything else is placed around them
$gapR = $RopeR - $RopeL                                   # 0.133 of the strip
$fonts = New-Object System.Drawing.Text.PrivateFontCollection
$fonts.AddFontFile("c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\fonts\HelveticaNeue-Black.otf")
$fam = $fonts.Families[0]
$fOr  = New-Object System.Drawing.Font($fam, [single]($OrSize * $Scale), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fTok = New-Object System.Drawing.Font($fam, [single]($TokSize * $Scale), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

# measure the two words
$tmp = New-Object System.Drawing.Bitmap(10, 10)
$mg = [System.Drawing.Graphics]::FromImage($tmp)
$mg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$fmt = [System.Drawing.StringFormat]::GenericTypographic
$szOr  = $mg.MeasureString("Or",  $fOr,  10000, $fmt)
$szTok = $mg.MeasureString("tok", $fTok, 10000, $fmt)
$mg.Dispose(); $tmp.Dispose()
$wOr = $szOr.Width / $Scale; $hOr = $szOr.Height / $Scale
$wTok = $szTok.Width / $Scale; $hTok = $szTok.Height / $Scale

# Where the INK sits inside a line box. The font's line height is no use for setting two lines this
# close: it carries leading the letters do not fill, and "Or" has no descender while "tok" has
# ascenders, so the only honest measure is the ink itself. Draw the word once on a scratch canvas
# at y = 0 and read off its first and last inked row.
function InkRows([string]$text, $font) {
  $wid = [int]([math]::Ceiling($wOr * $Scale * 2)); $hei = [int]([math]::Ceiling($hOr * $Scale * 2))
  $bm = New-Object System.Drawing.Bitmap($wid, $hei, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gg = [System.Drawing.Graphics]::FromImage($bm)
  $gg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  $gg.DrawString($text, $font, [System.Drawing.Brushes]::White, [single]0, [single]0, $fmt)
  $gg.Dispose()
  $top = -1; $bot = -1
  for ($y = 0; $y -lt $hei; $y++) {
    for ($x = 0; $x -lt $wid; $x += 2) {
      if ($bm.GetPixel($x, $y).A -gt 40) { if ($top -lt 0) { $top = $y }; $bot = $y; break } } }
  $bm.Dispose()
  # Parenthesised on purpose: in PowerShell the comma binds tighter than the division, so
  # @($top / $Scale, $bot / $Scale) means $top / ($Scale, $bot) / $Scale and blows up.
  return @(($top / $Scale), ($bot / $Scale))
}
$inkOr  = InkRows "Or"  $fOr
$inkTok = InkRows "tok" $fTok

# Lay out in DISPLAY px, from the anchors outwards: each word ends 3px before its own anchor, and
# the two anchors are a fixed 12.9px apart because the ropes are. So the words cannot both start
# at the left edge - whichever one needs more room pushes the canvas out to the LEFT, and the CSS
# offset (which is worked out from the rope stems this script prints) follows it.
$xOr = 0.0
$xAnchorR = $xOr + $wOr + 3
$xAnchorL = $xAnchorR - $gapR * $StripW                  # 12.9px to the left of it
$xTok = $xAnchorL - 3 - $wTok                            # "tok" ends just before its anchor
$shift = $Pad - [math]::Min(0.0, [math]::Min($xOr, $xTok))
$xOr += $shift; $xTok += $shift; $xAnchorR += $shift; $xAnchorL += $shift
$Wd = $xAnchorR + $AnchorW + $Pad                        # display width of the whole lockup
# Vertical: "tok" is set so that its ink starts $LineGap below where "Or"'s ink ends - the two
# lines are tucked right up against each other, which is what makes the lockup read as one mark
# instead of two words. $yTok is the DRAW position, so the ink offset comes off it.
$yTok = $inkOr[1] + $LineGap - $inkTok[0]
$Hd = [math]::Max($AnchorTopL + $anchorH, [math]::Max($AnchorTopR + $anchorH, $yTok + $inkTok[1])) + $Pad

$W = [int]([math]::Ceiling($Wd * $Scale)); $H = [int]([math]::Ceiling($Hd * $Scale))

# Both inks in one run: the page shows the black one on the light bar and the white one over the
# hero and in dark mode, and they have to be the SAME lettering in the same place.
function Bake([string]$colour, [string]$file) {
  $bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  if ($colour -eq "white") { $col = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
  else                     { $col = [System.Drawing.Color]::FromArgb(255, 17, 17, 17) }
  # NOT $ink: PowerShell is case-insensitive and would collide with a parameter named $Ink -
  # assigning a brush to it would silently turn the brush into a string.
  $inkBrush = New-Object System.Drawing.SolidBrush ($col)
  $g.DrawString("Or",  $fOr,  $inkBrush, [single]($xOr * $Scale),  [single](0), $fmt)
  $g.DrawString("tok", $fTok, $inkBrush, [single]($xTok * $Scale), [single]($yTok * $Scale), $fmt)
  # The anchors are NOT baked in: the bolt hangs fixed and the carabiner swings with the rope, so
  # they are separate elements in the page. This asset is the lettering only - the canvas keeps
  # its full size so the same CSS box positions both.
  $g.Dispose()
  $path = Join-Path $OutDir $file
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  return $path
}
$blackPath = Bake "black" "logo-word-black.png"
[void](Bake "white" "logo-word-white.png")

"saved: logo-word-black.png / logo-word-white.png   {0}x{1} px  (shows at {2:N2} x {3:N2})" -f $W, $H, $Wd, $Hd
"  rope stems at {0:N4} and {1:N4} of the lockup's width" -f (($xAnchorL + $AnchorRopeX*$AnchorW)/$Wd), (($xAnchorR + $AnchorRopeX*$AnchorW)/$Wd)
# What index.html needs, computed rather than eyeballed. The lockup is placed so its two rope
# stems land on the strip's two rope fractions; that fixes both its width and its left offset.
$fL = ($xAnchorL + $AnchorRopeX*$AnchorW)/$Wd
"index.html:"
"  #brandRope width  = var(--worker-width) * {0:N4}" -f ($Wd / $StripW)
"  #brandRope left   = var(--climber-left) - var(--worker-width) * {0:N4}" -f (($fL*$Wd - $RopeL*$StripW) / $StripW)
# and where the lettering actually sits, so the anchors can be hung level with it
$chk = New-Object System.Drawing.Bitmap($blackPath)
$prev = $false
for ($y = 0; $y -lt $chk.Height; $y++) {
  $has = $false
  for ($x = 0; $x -lt $chk.Width; $x += 2) { if ($chk.GetPixel($x, $y).A -gt 40) { $has = $true; break } }
  if ($has -ne $prev) { "  ink {0} at y {1:N2} (display px)" -f $(if ($has) { "starts" } else { "ends  " }), ($y / $Scale); $prev = $has } }
$chk.Dispose(); $anchor.Dispose()
