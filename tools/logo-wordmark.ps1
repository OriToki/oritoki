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
  [double]$OrSize = 46,           # font size for "Or"  (display px)
  [double]$TokSize = 27,          # font size for "tok"
  [double]$TokIndent = 6,         # "tok" sits in from the left, as in the reference
  [double]$AnchorTopR = 2,        # the "Or" anchor hangs from here
  [double]$AnchorTopL = 40,       # the "tok" one hangs lower
  [double]$Pad = 2,
  # Only the LETTERING changes with the theme. The anchors and the rope keep their own colours in
  # both, exactly as climber.png does - a white carabiner with black linework reads on either
  # background, and the rope has to match the SVG ropes it continues into.
  [string]$Ink = "black",
  [string]$Out = "c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images\logo-ink-black.png"
)
Add-Type -AssemblyName System.Drawing

$anchor = New-Object System.Drawing.Bitmap("c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images\anchor.png")
$anchorH = $AnchorW * $anchor.Height / $anchor.Width

# the anchors sit at the rope fractions; everything else is placed around them
$gapR = $RopeR - $RopeL                                   # 0.133 of the strip
$xRopeR = 0.0                                             # filled in below
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

# Lay out in DISPLAY px. Text starts at Pad; each anchor follows its own word, and the distance
# between the two anchors is fixed by the ropes - so the gap after "tok" absorbs the difference.
$xAnchorR = $Pad + $wOr + 3
$xAnchorL = $xAnchorR - $gapR * $StripW                  # 12.9px to the left of it
$xTok = $xAnchorL - 3 - $wTok                            # "tok" ends just before its anchor
if ($xTok -lt $Pad) { $xTok = $Pad }                     # never overlap the left edge
$Wd = $xAnchorR + $AnchorW + $Pad                        # display width of the whole lockup
$Hd = [math]::Max($AnchorTopL + $anchorH, [math]::Max($AnchorTopR + $anchorH, $hOr + $hTok)) + $Pad

$W = [int]([math]::Ceiling($Wd * $Scale)); $H = [int]([math]::Ceiling($Hd * $Scale))
$bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
if ($Ink -eq "white") { $inkCol = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
else                  { $inkCol = [System.Drawing.Color]::FromArgb(255, 17, 17, 17) }
# NOT $ink: PowerShell is case-insensitive, and $Ink is already the [string] parameter above -
# assigning a brush to it would silently turn the brush into a string.
$inkBrush = New-Object System.Drawing.SolidBrush ($inkCol)

# the words
$g.DrawString("Or",  $fOr,  $inkBrush, [single]($Pad * $Scale), [single](0), $fmt)
$g.DrawString("tok", $fTok, $inkBrush, [single]($xTok * $Scale), [single](($hOr - 2) * $Scale), $fmt)

# The anchors are NOT baked in any more: the bolt hangs fixed and the carabiner swings with the
# rope, so they are separate elements in the page. This asset is the lettering only - the canvas
# keeps its full size so the same CSS box positions both.
$g.Dispose()

$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"saved: $Out   {0}x{1} px  (shows at {2:N1}x{3:N1})" -f $W, $H, $Wd, $Hd
"  rope stems at {0:N3} and {1:N3} of the lockup's width" -f (($xAnchorL + $AnchorRopeX*$AnchorW)/$Wd), (($xAnchorR + $AnchorRopeX*$AnchorW)/$Wd)
$bmp.Dispose(); $anchor.Dispose()
