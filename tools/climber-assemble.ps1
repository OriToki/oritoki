# Builds the technician the page ships from the ChatGPT redraw (2026-09-30).
#
# SOURCES - all on the owner's Desktop, none in the repo:
#   man    "new men with new harness.png"   1254 x 1254, flat green #00FF00, black-and-white.
#          His harness has two EMPTY rings: sternal (chest) and ventral (waist). His LEFT fist is
#          raised in front of his chest, gripping nothing - the I'D handle goes in it.
#   I'D    "GEAR\descender handle in dencend mode.png"   white background, handle in the descent
#          position (the black paddle standing up at the back - the owner confirmed it).
#   chain  "chat gear\...04_59_24 AM.png"   ASAP + carabiner + ASAP'SORBER 40 + carabiner, hung on
#          a rope, ALL IN ONE DRAWING - so their sizes against each other are already right.
#   cara   "chat gear\...04_59_18 AM.png"   the D-shaped locking carabiner with its CAPTIV bar,
#          used to hang the I'D from the ventral ring.
#
# NOTHING IS SIZED BY EYE. Two things fix every scale:
#   - the CHAIN is placed rigidly, UNROTATED (its rope is plumb, so the ASAP stays upright), with its
#     lower carabiner's clip point on the sternal ring and its rope line on the backup rope. That is
#     two points for two unknowns (scale, and the height follows). It lands the ASAP at ~12 cm and
#     the absorber at ~36 cm by itself - real sizes, not chosen ones.
#   - the I'D runs from the ventral ring to the fist: its handle in his fist, its carabiner in the
#     ring. Its scale is set against the ASAP by the real sizes (I'D S / ASAP = 1.75).
#
# THE ONE HARD CONSTRAINT is still the rope gap: the ropes hang from the header mark's two stems,
# $Sep of the strip apart. The frame is cut so the working rope sits at $DescFrac of its width -
# the same fraction as the figure before this one - so A.markLeft, --climber-left and #brandRope
# do not move at all.
#
# Output: images/man-body.png, man-rig.png, man-glove.png - the same three layers as before:
#   body   everything, the whole composed figure
#   rig    the I'D and his LEFT fist over it (a copy; the body is never cut)
#   glove  his RIGHT (brake) glove (a copy)
param(
  [string]$ManSrc   = "C:\Users\gilmo\OneDrive\Desktop\new men with new harness.png",
  [string]$IdSrc    = "C:\Users\gilmo\OneDrive\Desktop\GEAR\descender handle in dencend mode.png",
  # Found by their time stamp: the names carry Georgian, which Windows PowerShell 5.1 misreads in a
  # script saved without a byte-order mark.
  [string]$ChainSrc = (Get-ChildItem "C:\Users\gilmo\OneDrive\Desktop\chat gear" -Filter "*04_59_24*").FullName,
  [string]$CaraSrc  = (Get-ChildItem "C:\Users\gilmo\OneDrive\Desktop\chat gear" -Filter "*04_59_18*").FullName,
  [string]$OutDir   = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  [int]$ShipW = 760,
  # The sheet's own green, measured: the first man was (1, 248, *), finaly.png is (85, 247, *).
  [double]$KeyR = 1.5, [double]$KeyG = 248,
  # THE I'D DRAWN ON HIM. finaly.png came back from ChatGPT with the I'D already in his left fist and
  # its carabiner in the ventral ring, so nothing is placed: the I'D, its handle and the fist are
  # simply COPIED into the rig layer by $RigPoly, and the rope goes to $EntryX/$EntryY.
  [switch]$IdBaked,
  [switch]$AllBaked,
  [int[]]$TopFistPoly = @(),
  [int[]]$RigPoly = @(575,290, 590,255, 630,248, 668,262, 672,300, 668,335, 700,335, 716,355, 722,400,
                      716,440, 700,462, 672,468, 650,460, 630,440, 622,420, 625,395, 640,370, 655,350,
                      600,350, 578,330),
  [double]$EntryX = 690, [double]$EntryY = 346,
  # THE ABSORBER'S LOWER CARABINER DRAWN ON HIM TOO (G 1.png): clipped into the sternal ring by
  # ChatGPT, with the owner's orientation (gate left, sleeve down, CAPTIV up). Then the chain's own
  # lower carabiner is not drawn: the absorber's bottom eye goes to this carabiner's TOP bend, and
  # the rigid chain (hence the ASAP's size and height) is placed from that point instead of the ring.
  [switch]$SternCaraBaked,
  [double]$SternCaraX = 542, [double]$SternCaraY = 342,
  # The absorber's end is laid this far PAST the carabiner's top bend, down its axis, and the drawn
  # bend ($CaraJoinPoly, the man's own pixels) is put back on top - so the webbing reads as looped
  # round the bend instead of parked on it (the owner: "the join to the carabiner is no good").
  [double]$CaraJoinDrop = 7,
  [int[]]$CaraJoinPoly = @(),
  # ASAP a little smaller, about the point where the rope runs through it (the owner asked).
  [double]$AsapShrink = 1.0, [double]$AsapRopeY = 280,
  [double]$ChainScale = 0,
  # The absorber's upper carabiner and the ASAP are two objects: the carabiner goes INTO the ASAP's
  # hole. So past the hole (along the carabiner, away from the absorber) the ASAP is drawn back over
  # it - the owner marked the cut point in green on the ASAP (2026-09-30).
  [switch]$CaraIntoAsap,
  # THE UPPER CARABINER'S AXIS (ღერძი) is the ASAP's hole - the owner's green dot. It turns about
  # that point by $CaraTurn degrees (clockwise +), and the absorber's top eye turns with it, so
  # the absorber follows. The ASAP itself does not move.
  [double]$CaraTurn = 0,
  # UNCLIPPED from the chest carabiner (the owner: "temporarily"): the absorber hangs free from the
  # ASAP's carabiner, straight down under gravity, $SorbFreeLen long. Use -CaraTurn -21.6 with it
  # so the carabiner hangs plumb too.
  [double]$SorbFreeLen = 0,
  [double]$ChainSplitLoX = 0, [double]$ChainSplitLoY = 0,
  # LIGHTER GLOVES. At 150 px the new man's near-black gloves merged with the I'D into one black
  # blot; the old figure's gloves were a mid brown-grey and its black finger lines read. Inside each
  # polygon (man's own pixels, flattened list of polygons separated by -1), the dark FILL is lifted
  # to that brown-grey and the black LINES (below $GloveKeep) are left as drawn.
  [int[]]$GlovePolys = @(), [double]$GloveKeep = 32, [double]$GloveGain = 2.6,
  [int[]]$FitPoly = @(), [double]$FitTopX = 428, [double]$FitTopY = 975, [double]$FitShift = 0,
  # What of HIM stays in front of the absorber: the fist, the I'D and the forearm. The absorber runs
  # from his sternal ring up to the ASAP and cannot avoid crossing his raised fist; drawn over it,
  # the fist disappeared under a strap. The man's own pixels in here are laid back over the chain.
  [int[]]$FrontPoly = @(575,290, 590,255, 630,248, 668,262, 672,300, 668,335, 700,335, 716,355, 722,400,
                        716,440, 700,462, 672,468, 650,460, 630,450, 622,458, 590,458, 574,420, 572,340),
  [double]$Sep = 0.09557,        # rope gap, fraction of the strip (see climber-compose.ps1)
  [double]$DescFrac = 0.4667,    # where the working rope sits in the frame = A.desc.x, unchanged
  [int]$FW = 1110,               # frame width in the man's own pixels
  # --- the man's own pixels (1254 x 1254) -------------------------------------------------
  [double]$SternX = 517, [double]$SternY = 395,   # sternal ring, where the absorber's carabiner hangs
  [double]$VentX = 563,  [double]$VentY = 482,    # ventral ring, where the I'D's carabiner hangs
  [double]$FistX = 712,  [double]$FistY = 322,    # the middle of his left fist's grip
  [int[]]$FistPoly  = @(662,300, 676,272, 712,266, 752,272, 766,300, 764,340, 752,366, 746,384, 700,386, 690,362, 668,352),
  [int[]]$GlovePoly = @(322,640, 356,622, 420,626, 452,660, 450,712, 424,742, 372,746, 332,724, 318,684),
  [int[]]$SternRing = @(488,384, 548,440),         # box: its metal is pasted back over the carabiner
  [int[]]$VentRing  = @(534,466, 596,524),
  # --- the I'D's own pixels -------------------------------------------------------------------
  [double]$IdGripX = 235, [double]$IdGripY = 170,   # on the handle paddle - goes in his fist
  [double]$IdHoleX = 275, [double]$IdHoleY = 1190,  # where its carabiner passes through it
  [double]$IdEntryX = 330, [double]$IdEntryY = 270, # where the working rope goes in
  [double]$IdCropY = 1300,                          # below this is the drawing's cut-off carabiner
  [double[]]$IdMarks = @(720,330, 800,420, 815,700, 800,900, 700,1080),  # printed, in the frame
  [double]$IdOverAsap = 1.75,                       # real size: I'D S height / ASAP height
  [double]$IdH = 1110, [double]$AsapH = 245,        # their drawn heights (I'D px / chain px)
  # --- the chain's own pixels (1284 x 1225) -------------------------------------------------
  [double]$ChainClipX = 200, [double]$ChainClipY = 1115,  # lower carabiner's far bend (on the ring)
  [double]$ChainRopeX = 933,                              # its rope's centre line
  [double]$ChainAsapTop = 155, [double]$ChainAsapBot = 400,
  [int[]]$ChainRopeCols = @(910, 957),                    # the drawn rope, erased outside the ASAP
  [int[]]$ChainSeeds = @(255,1115, 915,235),              # see-through: inside both carabiners
  # The chain is cut in three along the absorber's axis and each piece is adjusted on its own - the
  # owner found the absorber and its carabiners too big next to the ASAP he liked:
  #   lower carabiner   shrunk by $CaraShrink about its clip point, so it stays in the ring
  #   absorber          same length end to end, made THINNER by $SorbThin across its axis
  #   ASAP              untouched in place and size; its carabiner shrunk about the ASAP's hole
  # Because both carabiners get shorter, the absorber has to stretch a little to still reach -
  # the script prints by how much.
  [double]$ChainEyeLoX = 475, [double]$ChainEyeLoY = 1000,  # lower carabiner's top = absorber's bottom eye
  [double]$ChainEyeHiX = 875, [double]$ChainEyeHiY = 392,   # upper carabiner's bottom = absorber's top eye
  [double]$ChainHoleX = 957,  [double]$ChainHoleY = 185,    # upper carabiner's top, in the ASAP's hole
  [int[]]$ChainAsapBox = @(900, 90, 1030, 405),             # always the ASAP's, whatever the axis says
  [double]$CaraShrink = 0.8,
  # How far the ASAP (with its carabiner) is slid UP its rope from where the rigid chain would put it.
  # The absorber stretches to follow. On finaly.png the rigid chain crosses his left FIST; lifted,
  # the absorber runs up between his face and his fist instead.
  [double]$AsapLift = 0,
  [double]$SorbThin = 0.65,
  # Metal is drawn near pure white and melts into his white clothing at 150 px. Multiply its tone.
  [double]$DarkCara = 0.78, [double]$DarkAsap = 0.9,
  # --- the Captiv carabiner's own pixels ----------------------------------------------------------
  [double]$CaraTopX = 640, [double]$CaraTopY = 160, [double]$CaraBotX = 640, [double]$CaraBotY = 1120,
  [int[]]$CaraSeeds = @(640, 600),
  [double]$CaraCm = 11.1, [double]$AsapCm = 11.4,
  [switch]$Preview
)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
# The two whole-image passes are C#: in PowerShell a 1254x1254 flood takes minutes.
if (-not ('ClimberPx' -as [type])) {
Add-Type -Language CSharp @"
using System; using System.Collections.Generic;
public static class ClimberPx {
  // Un-mix a grey figure from its flat green. The green is NOT pure: it reads about (1, 248, 6..20),
  // and the blue wanders, so only R and G are used. Mixed: R = a*v + (1-a)*kr, G = a*v + (1-a)*kg,
  // so G - R = (1-a)*(kg - kr) and the grey is (R - (1-a)*kr) / a.
  public static void KeyGreen(byte[] a, double kr, double kg) {
    for (int i = 0; i < a.Length; i += 4) {
      double G = a[i+1], R = a[i+2];
      double ex = G - R;
      if (ex <= 6) continue;
      double al = 1.0 - ex / (kg - kr);
      if (al <= 0.06) { a[i] = a[i+1] = a[i+2] = a[i+3] = 0; continue; }
      if (al > 1) al = 1;
      double v = (R - (1 - al) * kr) / al;
      byte b = (byte)Math.Max(0, Math.Min(255, Math.Round(v)));
      a[i] = a[i+1] = a[i+2] = b; a[i+3] = (byte)Math.Round(al * 255);
    }
  }
  // Cut the back-up chain in three along the absorber's axis (lo-eye -> hi-eye): t < 0 is the lower
  // carabiner, 0..1 the absorber, t > 1 (or inside the ASAP's box) the top. The top is split again:
  // a band along hole -> hi-eye is the upper carabiner; inside the ASAP its pixels stay on the ASAP too.
  public static void SplitChain(byte[] cb, int w, int h, double lx, double ly, double hx, double hy,
      double ox, double oy, int bx0, int by0, int bx1, int by1, double band,
      byte[] lo, byte[] sorb, byte[] asap, byte[] hi) {
    double dx = hx - lx, dy = hy - ly, dd = dx * dx + dy * dy;
    double ux = hx - ox, uy = hy - oy, ud = ux * ux + uy * uy;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int o = (y * w + x) * 4; if (cb[o + 3] == 0) continue;
      bool inA = x >= bx0 && x <= bx1 && y >= by0 && y <= by1;
      double t = ((x - lx) * dx + (y - ly) * dy) / dd;
      if (inA || t > 1) {
        double u = ((x - ox) * ux + (y - oy) * uy) / ud;
        double px = ox + u * ux - x, py = oy + u * uy - y;
        bool isBand = u >= -0.08 && u <= 1.15 && px * px + py * py <= band * band;
        if (isBand) Array.Copy(cb, o, hi, o, 4);
        if (!isBand || inA) Array.Copy(cb, o, asap, o, 4);
      }
      else if (t < 0) Array.Copy(cb, o, lo, o, 4);
      else Array.Copy(cb, o, sorb, o, 4);
    }
  }
  public static void Darken(byte[] a, double f) {
    for (int o = 0; o < a.Length; o += 4) { if (a[o + 3] == 0) continue;
      for (int j = 0; j < 3; j++) a[o + j] = (byte)Math.Round(a[o + j] * f); }
  }
  // bounding box of every pixel more opaque than thr: x0, y0, x1, y1
  public static int[] Ink(byte[] a, int w, int h, int thr) {
    int x0 = w, y0 = h, x1 = 0, y1 = 0;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) if (a[(y * w + x) * 4 + 3] > thr) {
      if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
    return new int[] { x0, y0, x1, y1 };
  }
  // the three shipped layers: body = everything; glove / rig = copies where their masks are set
  public static void Layers(byte[] s, byte[] rigM, byte[] gloveM, byte[] body, byte[] rig, byte[] glove) {
    for (int o = 0; o < s.Length; o += 4) { if (s[o + 3] == 0) continue;
      Array.Copy(s, o, body, o, 4);
      if (gloveM[o + 3] > 127) Array.Copy(s, o, glove, o, 4);
      else if (rigM[o + 3] > 127) Array.Copy(s, o, rig, o, 4); }
  }
  static double L(byte[] a, int k) { int o = k * 4; return 0.299 * a[o+2] + 0.587 * a[o+1] + 0.114 * a[o]; }
  // Flood the paper in from the border and the seeds; paper pixels become black at their darkness.
  public static int Unwhite(byte[] a, int w, int h, int[] seeds, double thr) {
    bool[] seen = new bool[w * h]; var q = new Queue<int>();
    for (int x = 0; x < w; x++) { q.Enqueue(x); q.Enqueue((h - 1) * w + x); }
    for (int y = 0; y < h; y++) { q.Enqueue(y * w); q.Enqueue(y * w + w - 1); }
    for (int s = 0; s + 1 < seeds.Length; s += 2) q.Enqueue(seeds[s + 1] * w + seeds[s]);
    int n = 0;
    while (q.Count > 0) {
      int k = q.Dequeue(); if (seen[k]) continue;
      if (a[k * 4 + 3] != 0 && L(a, k) < thr) continue;
      seen[k] = true; n++;
      int x = k % w, y = k / w;
      if (x > 0) q.Enqueue(k - 1); if (x < w - 1) q.Enqueue(k + 1);
      if (y > 0) q.Enqueue(k - w); if (y < h - 1) q.Enqueue(k + w);
    }
    for (int k = 0; k < w * h; k++) {
      if (!seen[k]) continue;
      int o = k * 4;
      double l = a[o+3] == 0 ? 255 : L(a, k);
      int al = l >= 248 ? 0 : (int)Math.Round(255 - l);
      a[o] = a[o+1] = a[o+2] = 0; a[o+3] = (byte)Math.Max(0, Math.Min(255, al));
    }
    return n;
  }
}
"@
}

# ---------------------------------------------------------------- fast pixel access
function Load($p) {
  $b = New-Object System.Drawing.Bitmap $p
  $c = New-Object System.Drawing.Bitmap $b.Width, $b.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  # explicit size: DrawImageUnscaled honours the file's DPI, and perfect.png's is not 96, which
  # silently drew it at two thirds of its size
  $g = [System.Drawing.Graphics]::FromImage($c); $g.DrawImage($b, 0, 0, $b.Width, $b.Height); $g.Dispose(); $b.Dispose()
  return $c
}
function Bytes($bmp) {
  $r = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
  $d = $bmp.LockBits($r, 'ReadOnly', [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $a = New-Object byte[] ($d.Stride * $bmp.Height)
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $a, 0, $a.Length); $bmp.UnlockBits($d)
  return , $a     # the comma stops PowerShell unrolling the byte[] into an object[] copy
}
function Put($bmp, $a) {
  $r = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
  $d = $bmp.LockBits($r, 'WriteOnly', [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  [System.Runtime.InteropServices.Marshal]::Copy([byte[]]$a, 0, $d.Scan0, $a.Length); $bmp.UnlockBits($d)
}

# ---------------------------------------------------------------- the man: un-mix the green
# He is pure grey, so every edge pixel is a*grey + (1-a)*(0,255,0). That can be solved exactly:
# G - R = (1-a)*255, and the grey is R / a. No threshold, no halo, no green fringe.
$man = Load $ManSrc
$m = Bytes $man
[ClimberPx]::KeyGreen($m, $KeyR, $KeyG)
# the sheet's own outermost pixels are a slightly different green and key to faint specks
for ($y = 0; $y -lt $man.Height; $y++) { for ($x = 0; $x -lt $man.Width; $x++) {
  if ($x -lt 4 -or $y -lt 4 -or $x -ge $man.Width - 4 -or $y -ge $man.Height - 4) { $m[($y * $man.Width + $x) * 4 + 3] = 0 }
  elseif ($x -eq 4) { $x = $man.Width - 5 }
} }
if ($GlovePolys.Count -ge 6) {
  $polys = @(); $cur = @()
  foreach ($v in $GlovePolys) { if ($v -eq -1) { if ($cur.Count) { $polys += , $cur }; $cur = @() } else { $cur += $v } }
  if ($cur.Count) { $polys += , $cur }
  $lifted = 0
  foreach ($pl in $polys) {
    $pp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = New-Object "System.Drawing.PointF[]" ($pl.Count / 2)
    for ($i = 0; $i -lt $pl.Count; $i += 2) { $pts[$i / 2] = New-Object System.Drawing.PointF ([single]$pl[$i]), ([single]$pl[$i + 1]) }
    $pp.AddPolygon($pts); $bx = $pp.GetBounds()
    for ($y = [int]$bx.Top; $y -le [int]$bx.Bottom; $y++) { for ($x = [int]$bx.Left; $x -le [int]$bx.Right; $x++) {
      if (-not $pp.IsVisible($x, $y)) { continue }
      $o = ($y * $man.Width + $x) * 4
      if ($m[$o + 3] -lt 100) { continue }
      $l = ($m[$o] + $m[$o + 1] + $m[$o + 2]) / 3.0
      if ($l -le $GloveKeep -or $l -ge 120) { continue }
      $n = [Math]::Min(205, $GloveKeep + ($l - $GloveKeep) * $GloveGain)
      $m[$o + 2] = [byte][Math]::Min(255, $n + 8); $m[$o + 1] = [byte]$n; $m[$o] = [byte][Math]::Max(0, $n - 8)   # warm brown-grey
      $lifted++
    } }
  }
  "gloves lifted: $lifted px"
}
Put $man $m
"man keyed: $($man.Width) x $($man.Height)"
# Pad him. The ASAP rides ABOVE his head, off the top of his own canvas, so everything is composed
# on a bigger sheet; every man-pixel parameter is moved by the same pad right here.
$Pad = 200
$padded = New-Object System.Drawing.Bitmap ($man.Width + 2 * $Pad), ($man.Height + 2 * $Pad), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gpd = [System.Drawing.Graphics]::FromImage($padded); $gpd.DrawImageUnscaled($man, $Pad, $Pad); $gpd.Dispose()
$man.Dispose(); $man = $padded; $m = Bytes $man
$SternX += $Pad; $SternY += $Pad; $VentX += $Pad; $VentY += $Pad; $FistX += $Pad; $FistY += $Pad
$FistPoly  = @(for ($i = 0; $i -lt $FistPoly.Count; $i++) { $FistPoly[$i] + $Pad })
$GlovePoly = @(for ($i = 0; $i -lt $GlovePoly.Count; $i++) { $GlovePoly[$i] + $Pad })
$SternRing = @(for ($i = 0; $i -lt $SternRing.Count; $i++) { $SternRing[$i] + $Pad })
$RigPoly   = @(for ($i = 0; $i -lt $RigPoly.Count; $i++) { $RigPoly[$i] + $Pad })
$FrontPoly = @(for ($i = 0; $i -lt $FrontPoly.Count; $i++) { $FrontPoly[$i] + $Pad })
$EntryX += $Pad; $EntryY += $Pad; $SternCaraX += $Pad; $SternCaraY += $Pad
$CaraJoinPoly = @(for ($i = 0; $i -lt $CaraJoinPoly.Count; $i++) { $CaraJoinPoly[$i] + $Pad })
$VentRing  = @(for ($i = 0; $i -lt $VentRing.Count; $i++) { $VentRing[$i] + $Pad })

# ---------------------------------------------------------------- the gear: lift off the white
# Flood the white in from the border (and from seeds inside see-through loops). A flooded pixel
# is paper, or paper mixed with the BLACK outline it touches - so its alpha is its darkness and its
# colour is black. White drawn INSIDE an outline (the absorber's side, the ASAP's plates) is never
# reached, so it stays.
function Unwhite($bmp, $seeds, $thr) {
  $a = Bytes $bmp
  $n = [ClimberPx]::Unwhite($a, $bmp.Width, $bmp.Height, [int[]]$seeds, [double]$thr)
  Put $bmp $a
  return $n
}

$id = Load $IdSrc
# the drawing's carabiner runs off its bottom edge, cut; the separate one replaces it
$ia = Bytes $id
for ($y = [int]$IdCropY; $y -lt $id.Height; $y++) { for ($x = 0; $x -lt $id.Width; $x++) { $ia[($y * $id.Width + $x) * 4 + 3] = 0 } }
Put $id $ia
$nid = Unwhite $id @() 200
"I'D: $($id.Width) x $($id.Height), paper lifted: $nid px"

$chain = Load $ChainSrc
$ca = Bytes $chain
for ($y = 0; $y -lt $chain.Height; $y++) {
  # a few rows INSIDE the device at the bottom: kept any lower and a stub of drawn rope showed under it
  if ($y -ge $ChainAsapTop - 3 -and $y -le $ChainAsapBot - 4) { continue }
  for ($x = $ChainRopeCols[0]; $x -le $ChainRopeCols[1]; $x++) { $ca[($y * $chain.Width + $x) * 4 + 3] = 0 }
}
Put $chain $ca
$nch = Unwhite $chain $ChainSeeds 200
"chain: $($chain.Width) x $($chain.Height), paper lifted: $nch px"

$cara = Load $CaraSrc
$ncr = Unwhite $cara $CaraSeeds 200
"carabiner: $($cara.Width) x $($cara.Height), paper lifted: $ncr px"

# ---------------------------------------------------------------- solve
# The I'D: handle in the fist, device axis pointed at the ventral ring.
$ropeWorkX = 0.0
# chain scale depends on where the backup rope is, which depends on the working rope, which depends
# on the I'D - which is sized off the ASAP, i.e. the chain. Two passes settle it.
$sId = 0.155
for ($pass = 0; $pass -lt 4; $pass++) {
  $gx = $IdGripX; $gy = $IdGripY
  $vx = $IdHoleX - $gx; $vy = $IdHoleY - $gy                      # grip -> hole, I'D px
  $haveAng = [Math]::Atan2($vx, $vy)                               # from straight DOWN
  $tx = $VentX - $FistX; $ty = $VentY - $FistY
  $needAng = [Math]::Atan2($tx, $ty)
  $rot = $haveAng - $needAng                                       # radians, clockwise positive on screen
  $c = [Math]::Cos($rot); $s = [Math]::Sin($rot)
  function IdToMan($px, $py) {
    $dx = ($px - $IdGripX) * $sId; $dy = ($py - $IdGripY) * $sId
    return @(($FistX + $dx * $c - $dy * $s), ($FistY + $dx * $s + $dy * $c))
  }
  $entry = IdToMan $IdEntryX $IdEntryY
  $hole  = IdToMan $IdHoleX $IdHoleY
  $ropeWorkX = $entry[0]
  $sepPx = $Sep * $FW
  $ropeBackX = $ropeWorkX + $sepPx
  $sChain = ($ropeBackX - $SternX) / ($ChainRopeX - $ChainClipX)
  $asapManH = $AsapH * $sChain
  $sId = $asapManH * $IdOverAsap / $IdH
}
if ($IdBaked) {
  # the I'D is in the drawing: the rope simply goes where it goes in, and the chain follows from that
  $entry = @($EntryX, $EntryY)
  $ropeWorkX = $EntryX
  $sepPx = $Sep * $FW
  $ropeBackX = $ropeWorkX + $sepPx
  $sChain = ($ropeBackX - $SternX) / ($ChainRopeX - $ChainClipX)
  $asapManH = $AsapH * $sChain
}
$rotDeg = $rot * 180 / [Math]::PI
$chainLeft = $SternX - $ChainClipX * $sChain
$chainTop  = $SternY - $ChainClipY * $sChain
if ($SternCaraBaked) {
  # rigid chain hung by its own lower EYE on the drawn carabiner's top bend, rope line on the rope
  $sChain = ($ropeBackX - $SternCaraX) / ($ChainRopeX - $ChainEyeLoX)
  if ($ChainScale -gt 0) { $sChain = $ChainScale }   # pinned, so moving the join does not resize the ASAP
  $asapManH = $AsapH * $sChain
  $chainLeft = $ropeBackX - $ChainRopeX * $sChain     # the rope line stays on the rope, always
  $chainTop  = $SternCaraY - $ChainEyeLoY * $sChain
}
$asapRopeManY = $chainTop + $AsapRopeY * $sChain - $AsapLift
$asapTopY = $asapRopeManY + $AsapShrink * ($chainTop + $ChainAsapTop * $sChain - $AsapLift - $asapRopeManY)
$asapBotY = $asapRopeManY + $AsapShrink * ($chainTop + $ChainAsapBot * $sChain - $AsapLift - $asapRopeManY)
$pxPerCm = $asapManH / $AsapCm
$sCara = ($CaraCm * $pxPerCm) / [Math]::Sqrt(($CaraBotX - $CaraTopX) * ($CaraBotX - $CaraTopX) + ($CaraBotY - $CaraTopY) * ($CaraBotY - $CaraTopY))
$caraLen = [Math]::Sqrt(($hole[0] - $VentX) * ($hole[0] - $VentX) + ($hole[1] - $VentY) * ($hole[1] - $VentY))

"--- solved, in the man's own pixels (+$Pad pad) ---"
"scale: {0:N2} px/cm   (ASAP {1:N0} px tall)" -f $pxPerCm, $asapManH
"I'D:   scale {0:N4}, turned {1:N1} deg; entry ({2:N1}, {3:N1}); carabiner hole ({4:N1}, {5:N1}); {6:N1} cm tall" -f $sId, $rotDeg, $entry[0], $entry[1], $hole[0], $hole[1], ($IdH * $sId / $pxPerCm)
"ropes: working x {0:N1}, backup x {1:N1}  (gap {2:N1} px)" -f $ropeWorkX, $ropeBackX, $sepPx
"chain: scale {0:N4}; ASAP y {1:N1}..{2:N1}" -f $sChain, $asapTopY, $asapBotY
"I'D carabiner: ring to hole {0:N1} px ({1:N1} cm); carabiner scale {2:N4} = {3:N1} px long" -f $caraLen, ($caraLen / $pxPerCm), $sCara, ($CaraCm * $pxPerCm)

# ---------------------------------------------------------------- compose, in the man's pixels
$W0 = $man.Width; $H0 = $man.Height
$comp = New-Object System.Drawing.Bitmap $W0, $H0, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($comp)
$g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
$g.DrawImageUnscaled($man, 0, 0)
function PasteBox($box) {       # the man's own light metal back on top, inside a box
  $x0 = $box[0]; $y0 = $box[1]; $x1 = $box[2]; $y1 = $box[3]
  for ($y = $y0; $y -le $y1; $y++) { for ($x = $x0; $x -le $x1; $x++) {
    $o = ($y * $W0 + $x) * 4
    if ($m[$o + 3] -lt 250) { continue }
    if ($m[$o + 2] -ge 150) { $comp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $m[$o + 2], $m[$o + 1], $m[$o])) }
  } }
}
if (-not $AllBaked) {   # -AllBaked: the drawing carries all its own gear (Desktop\perfect.png)
# 1. the back-up chain - cut in three along the absorber's axis (see the parameters)
$CW = $chain.Width; $CH = $chain.Height
$cb = Bytes $chain
$loB = New-Object byte[] $cb.Length; $sorbB = New-Object byte[] $cb.Length; $asapB = New-Object byte[] $cb.Length; $hiB = New-Object byte[] $cb.Length
$dx = $ChainEyeHiX - $ChainEyeLoX; $dy = $ChainEyeHiY - $ChainEyeLoY; $dd = $dx * $dx + $dy * $dy
# inside the ASAP the carabiner's pixels stay on the ASAP too, so the shrunk copy leaves no hole
# The absorber's own END FITTING (the metal swivel between the webbing and its lower carabiner) is
# below the eye point, so splitting AT the eye gave it to the carabiner piece - and with the drawn
# chest carabiner in use that piece is never drawn, so the absorber ended in bare webbing. The owner
# circled where it belongs. Split further down so the swivel stays on the absorber.
$splX = if ($ChainSplitLoX -gt 0) { $ChainSplitLoX } else { $ChainEyeLoX }
$splY = if ($ChainSplitLoY -gt 0) { $ChainSplitLoY } else { $ChainEyeLoY }
[ClimberPx]::SplitChain($cb, $CW, $CH, $splX, $splY, $ChainEyeHiX, $ChainEyeHiY,
  $ChainHoleX, $ChainHoleY, $ChainAsapBox[0], $ChainAsapBox[1], $ChainAsapBox[2], $ChainAsapBox[3], 26.0,
  $loB, $sorbB, $asapB, $hiB)
if ($CaraTurn -ne 0) {
  # The carabiner is drawn OVER the ASAP, and SplitChain left its pixels on the ASAP too. Turned on
  # its axis it no longer covers them - a second, ghost carabiner. So inside the ASAP those pixels are
  # painted over with the plate: each row is bridged between the plate pixels either side of the band.
  $hx = $ChainEyeHiX - $ChainHoleX; $hy = $ChainEyeHiY - $ChainHoleY; $hd = $hx * $hx + $hy * $hy
  # outside the ASAP's box the "ASAP" piece holds only carabiner crumbs the band missed - drop them
  # (only LEFT of and BELOW the box - the device itself runs on past the box's right edge)
  for ($y = 0; $y -lt 500; $y++) { for ($x = 760; $x -lt $CW; $x++) {
    if ($x -ge $ChainAsapBox[0] -and $y -le $ChainAsapBox[3]) { continue }
    $asapB[($y * $CW + $x) * 4 + 3] = 0 } }
  for ($y = $ChainAsapBox[1]; $y -le $ChainAsapBox[3]; $y++) {
    $inb = @(); for ($x = $ChainAsapBox[0]; $x -le $ChainAsapBox[2]; $x++) {
      $u = (($x - $ChainHoleX) * $hx + ($y - $ChainHoleY) * $hy) / $hd
      $px = $ChainHoleX + $u * $hx - $x; $py = $ChainHoleY + $u * $hy - $y
      $inb += ($u -ge 0.02 -and $u -le 1.15 -and ($px * $px + $py * $py) -le 28 * 28)
    }
    $x = 0; $n = $inb.Count
    while ($x -lt $n) {
      if (-not $inb[$x]) { $x++; continue }
      $s = $x; while ($x -lt $n -and $inb[$x]) { $x++ }; $e = $x - 1
      $L = $ChainAsapBox[0] + $s - 1; $R = $ChainAsapBox[0] + $e + 1
      $oL = ($y * $CW + $L) * 4; $oR = ($y * $CW + $R) * 4
      for ($k = $s; $k -le $e; $k++) {
        $t = ($k - $s + 1) / ($e - $s + 2); $o = ($y * $CW + $ChainAsapBox[0] + $k) * 4
        for ($j = 0; $j -lt 4; $j++) { $asapB[$o + $j] = [byte][Math]::Round($asapB[$oL + $j] * (1 - $t) + $asapB[$oR + $j] * $t) }
      }
    }
  }
}
function Darken($a, $f) { [ClimberPx]::Darken($a, [double]$f) }
Darken $loB $DarkCara; Darken $hiB $DarkCara; Darken $asapB $DarkAsap
function ToBmp($a) { $b = New-Object System.Drawing.Bitmap $CW, $CH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb); Put $b $a; return $b }
$loBmp = ToBmp $loB; $sorbBmp = ToBmp $sorbB; $asapBmp = ToBmp $asapB; $hiBmp = ToBmp $hiB
# where everything lands, in the man's pixels
function ChainToMan($px, $py) { return @(($chainLeft + $px * $sChain), ($chainTop + $py * $sChain)) }
$clipM = ChainToMan $ChainClipX $ChainClipY
$holeM = ChainToMan $ChainHoleX $ChainHoleY; $holeM[1] -= $AsapLift
$eyeLoM = ChainToMan $ChainEyeLoX $ChainEyeLoY; $eyeHiM = ChainToMan $ChainEyeHiX $ChainEyeHiY; $eyeHiM[1] -= $AsapLift
# the ASAP (and its carabiner) shrunk about the rope's path through it, so the rope still runs through
$ropePtM = ChainToMan $ChainRopeX $AsapRopeY; $ropePtM[1] -= $AsapLift
$holeM  = @(($ropePtM[0] + $AsapShrink * ($holeM[0] - $ropePtM[0])), ($ropePtM[1] + $AsapShrink * ($holeM[1] - $ropePtM[1])))
$eyeHiM = @(($ropePtM[0] + $AsapShrink * ($eyeHiM[0] - $ropePtM[0])), ($ropePtM[1] + $AsapShrink * ($eyeHiM[1] - $ropePtM[1])))
$eyeLoN = @(($clipM[0] + $CaraShrink * ($eyeLoM[0] - $clipM[0])), ($clipM[1] + $CaraShrink * ($eyeLoM[1] - $clipM[1])))
$eyeHiN = @(($holeM[0] + $CaraShrink * ($eyeHiM[0] - $holeM[0])), ($holeM[1] + $CaraShrink * ($eyeHiM[1] - $holeM[1])))
if ($CaraTurn -ne 0) {
  $tr = $CaraTurn * [Math]::PI / 180; $tc = [Math]::Cos($tr); $ts = [Math]::Sin($tr)
  $ex = $eyeHiN[0] - $holeM[0]; $ey = $eyeHiN[1] - $holeM[1]
  $eyeHiN = @(($holeM[0] + $ex * $tc - $ey * $ts), ($holeM[1] + $ex * $ts + $ey * $tc))
}
if ($SternCaraBaked) {
  # a few px past the drawn bend, on the absorber's own line, so the bend can be laid back over it
  $ux = $SternCaraX - $eyeHiN[0]; $uy = $SternCaraY - $eyeHiN[1]; $ul = [Math]::Sqrt($ux * $ux + $uy * $uy)
  $eyeLoN = @(($SternCaraX + $CaraJoinDrop * $ux / $ul), ($SternCaraY + $CaraJoinDrop * $uy / $ul))
}
if ($SorbFreeLen -gt 0) { $eyeLoN = @($eyeHiN[0], ($eyeHiN[1] + $SorbFreeLen)) }
$sl = [Math]::Sqrt(($eyeHiN[0] - $eyeLoN[0]) * ($eyeHiN[0] - $eyeLoN[0]) + ($eyeHiN[1] - $eyeLoN[1]) * ($eyeHiN[1] - $eyeLoN[1]))
"absorber eye to eye: {0:N1} px  (lo {1:N1},{2:N1}  hi {3:N1},{4:N1}; hi at lift 0 would be y {5:N1})" -f $sl, $eyeLoN[0], $eyeLoN[1], $eyeHiN[0], $eyeHiN[1], ($eyeHiN[1] + $AsapLift)
function DrawAffine($bmp, $mx) { $g.Transform = $mx; $g.DrawImage($bmp, 0, 0, $CW, $CH); $g.ResetTransform() }
function Sim($pivotSrcX, $pivotSrcY, $sc, $toX, $toY) {
  $mx = New-Object System.Drawing.Drawing2D.Matrix
  $mx.Translate([single](-$pivotSrcX), [single](-$pivotSrcY), 'Append')
  $mx.Scale([single]$sc, [single]$sc, 'Append')
  $mx.Translate([single]$toX, [single]$toY, 'Append')
  return $mx
}
# ASAP, where it was
DrawAffine $asapBmp (Sim $ChainRopeX $AsapRopeY ($sChain * $AsapShrink) $ropePtM[0] $ropePtM[1])
# absorber: its two eyes onto the two new eye points, stretched along its axis, thinned across it
$oAng = [Math]::Atan2($dy, $dx) * 180 / [Math]::PI
$nx = $eyeHiN[0] - $eyeLoN[0]; $ny = $eyeHiN[1] - $eyeLoN[1]
$nAng = [Math]::Atan2($ny, $nx) * 180 / [Math]::PI
$stretch = [Math]::Sqrt($nx * $nx + $ny * $ny) / ([Math]::Sqrt($dd) * $sChain)
$mx = New-Object System.Drawing.Drawing2D.Matrix
$mx.Translate([single](-$ChainEyeLoX), [single](-$ChainEyeLoY), 'Append')
$mx.Rotate([single](-$oAng), 'Append')
$mx.Scale([single]($sChain * $stretch), [single]($sChain * $SorbThin), 'Append')
$mx.Rotate([single]$nAng, 'Append')
$mx.Translate([single]$eyeLoN[0], [single]$eyeLoN[1], 'Append')
DrawAffine $sorbBmp $mx
if ($FitPoly.Count -ge 6) {
  # THE ABSORBER'S END FITTING, as its own piece and NOT thinned: the metal swivel under the webbing
  # (the owner circled where it belongs). It is lifted from the chain drawing by $FitPoly and hung
  # from the thinned strip's bottom-centre, turned like the absorber, at the chain's own scale.
  $fb = New-Object byte[] $cb.Length
  $fpath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $fpts = New-Object "System.Drawing.PointF[]" ($FitPoly.Count / 2)
  for ($i = 0; $i -lt $FitPoly.Count; $i += 2) { $fpts[$i / 2] = New-Object System.Drawing.PointF ([single]$FitPoly[$i]), ([single]$FitPoly[$i + 1]) }
  $fpath.AddPolygon($fpts); $fbx = $fpath.GetBounds()
  for ($y = [int]$fbx.Top; $y -le [int]$fbx.Bottom; $y++) { for ($x = [int]$fbx.Left; $x -le [int]$fbx.Right; $x++) {
    if ($fpath.IsVisible($x, $y)) { $o = ($y * $CW + $x) * 4; for ($j = 0; $j -lt 4; $j++) { $fb[$o + $j] = $cb[$o + $j] } } } }
  Darken $fb $DarkCara
  $fitBmp = ToBmp $fb
  $jp = [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF ([single]$FitTopX), ([single]$FitTopY)))
  $mx.TransformPoints($jp)
  $fm = New-Object System.Drawing.Drawing2D.Matrix
  $fm.Translate([single](-$FitTopX), [single](-($FitTopY + $FitShift)), 'Append')   # + shift closes the gap the thinning opens
  $fm.Rotate([single]($nAng - $oAng), 'Append')
  $fm.Scale([single]$sChain, [single]$sChain, 'Append')
  $fm.Translate($jp[0].X, $jp[0].Y, 'Append')
  DrawAffine $fitBmp $fm
  "end fitting hung at ({0:N1}, {1:N1})" -f $jp[0].X, $jp[0].Y
}
# the two carabiners, shrunk about the ends that must not move, over the absorber's eyes
if (-not $SternCaraBaked) { DrawAffine $loBmp (Sim $ChainClipX $ChainClipY ($sChain * $CaraShrink) $clipM[0] $clipM[1]) }
$hm = Sim $ChainHoleX $ChainHoleY ($sChain * $CaraShrink * $AsapShrink) $holeM[0] $holeM[1]
if ($CaraTurn -ne 0) { $hm.RotateAt([single]$CaraTurn, (New-Object System.Drawing.PointF ([single]$holeM[0]), ([single]$holeM[1])), 'Append') }
DrawAffine $hiBmp $hm
"upper carabiner: axis at the ASAP hole ({0:N1}, {1:N1}), turned {2:N1} deg" -f $holeM[0], $holeM[1], $CaraTurn
if ($CaraIntoAsap) {
  # half-plane beyond the hole, square to the carabiner's axis: the ASAP goes back on top there
  $ax = $holeM[0] - $eyeHiN[0]; $ay = $holeM[1] - $eyeHiN[1]; $al = [Math]::Sqrt($ax * $ax + $ay * $ay); $ax /= $al; $ay /= $al
  $px = -$ay; $py = $ax; $big = 400
  $hp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $hp.AddPolygon([System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF ([single]($holeM[0] + $px * $big)), ([single]($holeM[1] + $py * $big))),
    (New-Object System.Drawing.PointF ([single]($holeM[0] + $px * $big + $ax * $big)), ([single]($holeM[1] + $py * $big + $ay * $big))),
    (New-Object System.Drawing.PointF ([single]($holeM[0] - $px * $big + $ax * $big)), ([single]($holeM[1] - $py * $big + $ay * $big))),
    (New-Object System.Drawing.PointF ([single]($holeM[0] - $px * $big)), ([single]($holeM[1] - $py * $big)))))
  $g.SetClip($hp)
  DrawAffine $asapBmp (Sim $ChainRopeX $AsapRopeY ($sChain * $AsapShrink) $ropePtM[0] $ropePtM[1])
  $g.ResetClip()
}
if ($CaraJoinPoly.Count -ge 6) {
  # the drawn carabiner's top bend back over the absorber's end: the webbing loops round it
  $jp = New-Object "System.Drawing.Point[]" ($CaraJoinPoly.Count / 2)
  for ($i = 0; $i -lt $CaraJoinPoly.Count; $i += 2) { $jp[$i / 2] = New-Object System.Drawing.Point $CaraJoinPoly[$i], $CaraJoinPoly[$i + 1] }
  $jpath = New-Object System.Drawing.Drawing2D.GraphicsPath; $jpath.AddPolygon($jp)
  # only the bend's METAL and outline come back - not the white shirt seen through its opening, so
  # the webbing shows through the loop and passes under the bar
  $g.Flush(); $jb = $jpath.GetBounds()
  for ($y = [int]$jb.Top; $y -le [int]$jb.Bottom; $y++) { for ($x = [int]$jb.Left; $x -le [int]$jb.Right; $x++) {
    if (-not $jpath.IsVisible($x, $y)) { continue }
    $o = ($y * $man.Width + $x) * 4
    if ($m[$o + 3] -lt 200 -or $m[$o + 2] -gt 222) { continue }
    $comp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($m[$o + 3], $m[$o + 2], $m[$o + 1], $m[$o]))
  } }
}
"absorber: thinned to {0:P0}, stretched {1:P1} to reach the smaller carabiners (turned {2:N1} deg)" -f $SorbThin, ($stretch - 1), ($nAng - $oAng)
$g.Flush(); if (-not $SternCaraBaked) { PasteBox $SternRing }
}
if ($IdBaked) {
  # nothing to place: the rig layer is the drawing's own I'D and fist, lifted by $RigPoly
  $fp = New-Object "System.Drawing.Point[]" ($RigPoly.Count / 2)
  for ($i = 0; $i -lt $RigPoly.Count; $i += 2) { $fp[$i / 2] = New-Object System.Drawing.Point $RigPoly[$i], $RigPoly[$i + 1] }
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath; $path.AddPolygon($fp)
  $fq = New-Object "System.Drawing.Point[]" ($FrontPoly.Count / 2)
  for ($i = 0; $i -lt $FrontPoly.Count; $i += 2) { $fq[$i / 2] = New-Object System.Drawing.Point $FrontPoly[$i], $FrontPoly[$i + 1] }
  $front = New-Object System.Drawing.Drawing2D.GraphicsPath; $front.AddPolygon($fq)
  $g.SetClip($front); $g.DrawImageUnscaled($man, 0, 0); $g.ResetClip()
  $g.Dispose()
  $idMask = New-Object System.Drawing.Bitmap $W0, $H0, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gm = [System.Drawing.Graphics]::FromImage($idMask)
  $gm.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), $path); $gm.Dispose()
} else {
# 2. the I'D's carabiner, ventral ring -> through the device's hole (darkened like the others)
$cab = Bytes $cara; Darken $cab $DarkCara; Put $cara $cab
$cang = [Math]::Atan2($hole[0] - $VentX, -($hole[1] - $VentY)) * 180 / [Math]::PI   # from straight UP
$g.TranslateTransform([single]$VentX, [single]$VentY)
$g.RotateTransform([single]$cang)
$g.ScaleTransform([single]$sCara, [single]$sCara)
$g.TranslateTransform([single](-$CaraBotX), [single](-$CaraBotY))   # its BOTTOM end sits in the ring
$g.DrawImage($cara, 0, 0, $cara.Width, $cara.Height)
$g.ResetTransform(); $g.Flush(); PasteBox $VentRing
# 3. the I'D
$g.TranslateTransform([single]$FistX, [single]$FistY)
$g.RotateTransform([single]$rotDeg)
$g.ScaleTransform([single]$sId, [single]$sId)
$g.TranslateTransform([single](-$IdGripX), [single](-$IdGripY))
$g.DrawImage($id, 0, 0, $id.Width, $id.Height)
$g.ResetTransform()
# 4. his left fist back over the handle
$fp = New-Object "System.Drawing.Point[]" ($FistPoly.Count / 2)
for ($i = 0; $i -lt $FistPoly.Count; $i += 2) { $fp[$i / 2] = New-Object System.Drawing.Point $FistPoly[$i], $FistPoly[$i + 1] }
$path = New-Object System.Drawing.Drawing2D.GraphicsPath; $path.AddPolygon($fp)
$g.SetClip($path); $g.DrawImageUnscaled($man, 0, 0); $g.ResetClip()
$g.Dispose()

# the I'D's own footprint, for the rig mask
$idMask = New-Object System.Drawing.Bitmap $W0, $H0, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gm = [System.Drawing.Graphics]::FromImage($idMask)
$gm.InterpolationMode = 'HighQualityBicubic'
$gm.TranslateTransform([single]$FistX, [single]$FistY); $gm.RotateTransform([single]$rotDeg)
$gm.ScaleTransform([single]$sId, [single]$sId); $gm.TranslateTransform([single](-$IdGripX), [single](-$IdGripY))
$gm.DrawImage($id, 0, 0, $id.Width, $id.Height); $gm.ResetTransform()
$gm.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), $path)
$gm.Dispose()
}

# ---------------------------------------------------------------- the frame
$left = $ropeWorkX - $DescFrac * $FW
$ca2 = Bytes $comp
$ink = [ClimberPx]::Ink($ca2, $W0, $H0, 60)
$minX = $ink[0]; $minY = $ink[1]; $maxX = $ink[2]; $maxY = $ink[3]
$top = $minY - 4
$FH = $maxY + 4 - $top
"ink: x {0}..{1}  y {2}..{3};  frame left {4:N1}, width {5} -> right {6:N1}" -f $minX, $maxX, $minY, $maxY, $left, $FW, ($left + $FW)
if ($minX -lt $left -or $maxX -gt $left + $FW) { throw "the figure does not fit the frame - widen `$FW" }

if ($Preview) {
  foreach ($bg in @(@('light', 255, 255, 255), @('dark', 34, 37, 43))) {
    $pv = New-Object System.Drawing.Bitmap $FW, $FH
    $gp = [System.Drawing.Graphics]::FromImage($pv)
    $gp.Clear([System.Drawing.Color]::FromArgb(255, $bg[1], $bg[2], $bg[3]))
    $gp.DrawImage($comp, [single](-$left), [single](-$top))
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 255, 0, 0)), 1
    $gp.DrawLine($pen, [single]($ropeWorkX - $left), 0, [single]($ropeWorkX - $left), [single]($entry[1] - $top))
    $gp.DrawLine($pen, [single]($ropeBackX - $left), 0, [single]($ropeBackX - $left), [single]$FH)
    $gp.Dispose()
    $pp = "C:\Users\gilmo\Downloads\climber-assembled-$($bg[0]).png"
    $pv.Save($pp); $pv.Dispose(); $pp
  }
  return
}

# ---------------------------------------------------------------- ship: scale, then copy layers
$k = $ShipW / [double]$FW
$SH = [int][Math]::Round($FH * $k)
function Shrink($src) {
  $o = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gs = [System.Drawing.Graphics]::FromImage($o)
  $gs.InterpolationMode = 'HighQualityBicubic'; $gs.PixelOffsetMode = 'HighQuality'
  $gs.DrawImage($src, (New-Object System.Drawing.RectangleF 0, 0, $ShipW, $SH), (New-Object System.Drawing.RectangleF ([single]$left), ([single]$top), ([single]$FW), ([single]$FH)), [System.Drawing.GraphicsUnit]::Pixel)
  $gs.Dispose(); return $o
}
$small = Shrink $comp
$rigM = Shrink $idMask
$gl = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gg = [System.Drawing.Graphics]::FromImage($gl)
$gpts = New-Object "System.Drawing.PointF[]" ($GlovePoly.Count / 2)
for ($i = 0; $i -lt $GlovePoly.Count; $i += 2) { $gpts[$i / 2] = New-Object System.Drawing.PointF ([single](($GlovePoly[$i] - $left) * $k)), ([single](($GlovePoly[$i + 1] - $top) * $k)) }
$gg.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), $gpts)
if ($TopFistPoly.Count -ge 6) {
  # a second piece in the top layer: his DESCENDER fist, so the brake strand's upper tip runs in
  # behind it (the owner's ask for the flat figure)
  $fpts2 = New-Object "System.Drawing.PointF[]" ($TopFistPoly.Count / 2)
  for ($i = 0; $i -lt $TopFistPoly.Count; $i += 2) { $fpts2[$i / 2] = New-Object System.Drawing.PointF ([single](($TopFistPoly[$i] + $Pad - $left) * $k)), ([single](($TopFistPoly[$i + 1] + $Pad - $top) * $k)) }
  $gg.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), $fpts2)
}
$gg.Dispose()
$sb = Bytes $small; $rb = Bytes $rigM; $gb = Bytes $gl
$bodyB = New-Object byte[] $sb.Length; $rigB = New-Object byte[] $sb.Length; $gloveB = New-Object byte[] $sb.Length
[ClimberPx]::Layers($sb, $rb, $gb, $bodyB, $rigB, $gloveB)
foreach ($pair in @(@('man-body.png', $bodyB), @('man-rig.png', $rigB), @('man-glove.png', $gloveB))) {
  $bm = New-Object System.Drawing.Bitmap $ShipW, $SH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  Put $bm $pair[1]; $bm.Save((Join-Path $OutDir $pair[0]), [System.Drawing.Imaging.ImageFormat]::Png); $bm.Dispose()
}
"shipped: $ShipW x $SH   (aspect {0:N4})" -f ($SH / $ShipW)
function F($x, $y) { "{0:N4}, {1:N4}" -f (($x - $left) / $FW), (($y - $top) / $FH) }
"--- for index.html's A table (fractions of the frame) ---"
"  working rope x   {0:N4}   (must equal A.desc.x / A.workTopX)" -f (($ropeWorkX - $left) / $FW)
"  backup rope x    {0:N4}   (A.backupX / A.camX / asapIn.x / asapOut.x)" -f (($ropeBackX - $left) / $FW)
"  ASAP top / bot y {0:N4} / {1:N4}" -f (($asapTopY - $top) / $FH), (($asapBotY - $top) / $FH)
"  rope entry       $(F $entry[0] $entry[1])"
"  frame: left {0:N1} top {1:N1} size {2} x {3}   k = {4:N5}" -f $left, $top, $FW, $FH, $k
# Named points on the I'D, carried through its placement: where the brake strand comes off it.
for ($i = 0; -not $IdBaked -and $i + 1 -lt $IdMarks.Count; $i += 2) {
  $p = IdToMan $IdMarks[$i] $IdMarks[$i + 1]
  "  I'D ({0},{1}) -> {2}   frame px ({3:N1}, {4:N1})" -f $IdMarks[$i], $IdMarks[$i + 1], (F $p[0] $p[1]), ($p[0] - $left), ($p[1] - $top)
}
