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
  # Linework for the outlined version: the hardware's own pen, literally. 3.5px on a 128px asset
  # shown 10.8 wide is 0.295 display px. Scaling it up to keep the same weight RELATIVE to the
  # letters was tried at 1.5 and read as a thick black outline next to hairline-drawn carabiners -
  # the very mismatch it was meant to fix. At 0.3 the outline is a soft grey edge at 1x, which is
  # exactly what the carabiner's outline is, and the letters still hold: they are 36px tall.
  [double]$Outline = 0.3,
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

# Every version in one run: they have to be the SAME lettering in the same place, because the page
# swaps between them. Over the hero and in dark mode it shows the white one; on the light bar it
# shows the OUTLINED one - white letters with black linework, so the wordmark is made of the same
# stuff as the carabiners standing next to it instead of turning into solid black beside them.
# All three are drawn from one GraphicsPath, so the letterforms cannot drift apart.
function Bake([string]$colour, [string]$file) {
  $bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $gp.AddString("Or",  $fam, 0, [single]($OrSize * $Scale),
                (New-Object System.Drawing.PointF ([single]($xOr * $Scale), [single]0)), $fmt)
  $gp.AddString("tok", $fam, 0, [single]($TokSize * $Scale),
                (New-Object System.Drawing.PointF ([single]($xTok * $Scale), [single]($yTok * $Scale))), $fmt)
  $col = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)   # both versions are white letters
  # NOT $ink: PowerShell is case-insensitive and would collide with a parameter named $Ink -
  # assigning a brush to it would silently turn the brush into a string.
  $inkBrush = New-Object System.Drawing.SolidBrush ($col)
  $g.FillPath($inkBrush, $gp)
  if ($colour -eq "out") {
    # The stroke is centred on the outline, so half of it eats into the letter. Drawn at twice the
    # width and clipped to the path, only the inside half lands - the letterforms keep the exact
    # width the other two have, which is what lets the page swap between them without a shift.
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 17, 17, 17)), ([single]($Outline * $Scale * 2))
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.SetClip($gp)
    $g.DrawPath($pen, $gp)
    $g.ResetClip(); $pen.Dispose()
  }
  # The anchors are NOT baked in: the bolt hangs fixed and the carabiner swings with the rope, so
  # they are separate elements in the page. This asset is the lettering only - the canvas keeps
  # its full size so the same CSS box positions both.
  $gp.Dispose(); $g.Dispose()
  $path = Join-Path $OutDir $file
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  return $path
}
# Two files, because the page shows two. There is no solid-black one any more: the light bar gets
# the outlined lettering instead, so nothing loaded it.
$plainPath = Bake "white" "logo-word-white.png"
[void](Bake "out" "logo-word-outline.png")

"saved: logo-word-white / -outline.png   {0}x{1} px  (shows at {2:N2} x {3:N2})" -f $W, $H, $Wd, $Hd
"  rope stems at {0:N4} and {1:N4} of the lockup's width" -f (($xAnchorL + $AnchorRopeX*$AnchorW)/$Wd), (($xAnchorR + $AnchorRopeX*$AnchorW)/$Wd)
# What index.html needs, computed rather than eyeballed. The lockup is placed so its two rope
# stems land on the strip's two rope fractions; that fixes both its width and its left offset.
$fL = ($xAnchorL + $AnchorRopeX*$AnchorW)/$Wd
"index.html:"
"  #brandRope width  = var(--worker-width) * {0:N4}" -f ($Wd / $StripW)
"  #brandRope left   = var(--climber-left) - var(--worker-width) * {0:N4}" -f (($fL*$Wd - $RopeL*$StripW) / $StripW)
# and where the lettering actually sits, so the anchors can be hung level with it
# Read the ink off the PLAIN one: the outlined version's stroke would report the letterforms a
# pixel and a half taller than they are, and these numbers place the anchors.
$chk = New-Object System.Drawing.Bitmap($plainPath)
$prev = $false
for ($y = 0; $y -lt $chk.Height; $y++) {
  $has = $false
  for ($x = 0; $x -lt $chk.Width; $x += 2) { if ($chk.GetPixel($x, $y).A -gt 40) { $has = $true; break } }
  if ($has -ne $prev) { "  ink {0} at y {1:N2} (display px)" -f $(if ($has) { "starts" } else { "ends  " }), ($y / $Scale); $prev = $has } }
$chk.Dispose(); $anchor.Dispose()
