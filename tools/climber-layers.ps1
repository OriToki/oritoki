# Cuts the technician into the layers the ropes need to pass between.
#
#   climber-body.png   everything else, with a hole where each piece was
#   climber-head.png   head + helmet          (the backup rope passes BEHIND his head)
#   climber-hand-u.png the upper fist/glove   (the working rope passes behind it)
#   climber-hand-l.png the lower brake fist   (the brake tail's tip hides behind it)
#
# All four are the SAME canvas size and the pieces stay at their original coordinates, so
# the page stacks them at the same position with nothing to line up. Painted body -> rope
# -> piece, the rope is covered exactly where the piece covered it.
#
# WHY CUTTING IS SAFE HERE, unlike logo-layers.ps1, where cutting was the thing that went
# wrong for days: there a cut hanger lost the sliver its own bar covered, and the hole
# showed the moment it turned. Here every piece is the TOPMOST shape at its spot and it
# goes back on top at the same coordinates, so the hole it leaves is exactly the hole it
# refills. Nothing hidden is lost because nothing was hiding it.
#
# The cut therefore does not have to be anatomically perfect - it only has to CONTAIN the
# piece and run somewhere a seam cannot be seen, which is along the black outline between
# the glove and its sleeve, and along the collar. A few pixels of sleeve riding along with
# the glove costs nothing.
#
# Clipping is deliberately NOT antialiased: the piece and the hole must be exact
# complements, and a soft edge on both would double up into a visible line.
#
# PowerShell note: $x and $X are one variable, so loop counters here are $ix / $iy, and
# there is no pre-decrement operator - `--$i` parses as -(-$i).
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\chack it.png",
  [string]$OutDir = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images",
  # The owner's file is drawn facing the viewer's LEFT; the site has always faced RIGHT
  # (his right profile), so it is mirrored on the way in. Every polygon below is in
  # MIRRORED coordinates.
  [switch]$NoMirror,
  # Canvas the layers are written at. The owner's file is 1254 square and #climber is
  # 116 CSS px wide (86 on phones), so 1254 is about nine times what any screen can show
  # and four files of it came to 874 KB against the old single 315 KB. 800 still leaves
  # nearly 7x for retina. The SOURCE is scaled before the cut, never the layers after it:
  # downscaling four finished layers would antialias both sides of every cut edge and the
  # two soft edges would add up into a hairline seam.
  [int]$Size = 800,
  [switch]$Preview
)
Add-Type -AssemblyName System.Drawing

# --- the cuts, in the mirrored figure's own 1254x1254 pixels -------------------------------
# Head: over the helmet, down past the face, then back along the shirt collar and shoulder.
$HEAD = @(230,265, 220,180, 245,110, 300,55, 380,38, 450,50, 505,105, 525,175,
          515,245, 495,295, 460,335, 420,352, 360,328, 300,298)
# Upper fist: cut across the wrist just behind the glove's cuff.
$HANDU = @(614,404, 645,372, 700,364, 735,390, 744,442, 732,484, 698,508, 652,516)
# Lower (brake) fist: same, on the other wrist.
$HANDL = @(498,722, 440,722, 395,745, 378,790, 382,838, 420,872, 480,878, 530,860, 558,836)

function Poly($flat) {
  $pts = New-Object "System.Drawing.Point[]" ($flat.Count / 2)
  for ($ix = 0; $ix -lt $flat.Count; $ix += 2) {
    $pts[$ix / 2] = New-Object System.Drawing.Point ([int]$flat[$ix]), ([int]$flat[$ix + 1])
  }
  return $pts
}
function PathOf($flat) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddPolygon([System.Drawing.Point[]](Poly $flat))
  return $p
}

# $img, NOT $src: the parameter is [string]$Src, and $src IS $Src, so assigning a Bitmap
# to it silently coerces the Bitmap back to the text "System.Drawing.Bitmap".
$img = New-Object System.Drawing.Bitmap($Src)
if (-not $NoMirror) { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
$W = $img.Width; $H = $img.Height

if ($Preview) {
  $o = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($o)
  $g.Clear([System.Drawing.Color]::White)
  $g.DrawImage($img, 0, 0, $W, $H)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 255, 0, 200)), 3
  $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(60, 255, 0, 200))
  foreach ($f in @($HEAD, $HANDU, $HANDL)) {
    $pts = [System.Drawing.Point[]](Poly $f)
    $g.FillPolygon($fill, $pts); $g.DrawPolygon($pen, $pts)
  }
  $g.Dispose(); $img.Dispose()
  $out = "C:\Users\gilmo\Downloads\climber-cuts.png"
  $o.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $o.Dispose()
  "$out   (preview only, nothing written to images/)"
  return
}

# --- the four layers ----------------------------------------------------------------------
# Done pixel by pixel in C#, not with SetClip + DrawImage. GDI+ was off by 260849 pixels:
# DrawImage into a destination RECTANGLE resamples even at 1:1, and drawing a layer over a
# transparent canvas composites rather than copies, so the alpha came back rounded. Here
# each pixel is assigned to exactly ONE layer and copied verbatim, which is also what makes
# the restack check below meaningful instead of a test of GDI+'s rounding.
$K = $Size / [double]$W
$masks = @()
foreach ($f in @($HEAD, $HANDU, $HANDL)) {
  $m = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gm = [System.Drawing.Graphics]::FromImage($m)
  $gm.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $gm.Clear([System.Drawing.Color]::Black)
  $sf = New-Object "double[]" $f.Count
  for ($ix = 0; $ix -lt $f.Count; $ix++) { $sf[$ix] = [double]$f[$ix] * $K }
  $gm.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), [System.Drawing.Point[]](Poly $sf))
  $gm.Dispose()
  $mp = Join-Path $env:TEMP ("nm-mask-" + $masks.Count + ".png")
  $m.Save($mp, [System.Drawing.Imaging.ImageFormat]::Png); $m.Dispose()
  $masks += $mp
}
$mirror = if ($NoMirror) { "false" } else { "true" }
if (-not ("NmCut" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public class NmCut {
  static byte[] Grab(Bitmap b) {
    int N = b.Width * b.Height;
    BitmapData d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    byte[] buf = new byte[N * 4];
    Marshal.Copy(d.Scan0, buf, 0, N * 4);
    b.UnlockBits(d);
    return buf;
  }
  static void Put(byte[] buf, int W, int H, string path) {
    Bitmap b = new Bitmap(W, H, PixelFormat.Format32bppArgb);
    BitmapData d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    Marshal.Copy(buf, 0, d.Scan0, buf.Length);
    b.UnlockBits(d);
    b.Save(path, ImageFormat.Png);
    b.Dispose();
  }
  public static string Run(string srcPath, bool mirror, int size, string[] maskPaths, string[] outPaths) {
    Bitmap s0 = new Bitmap(srcPath);
    if (mirror) s0.RotateFlip(RotateFlipType.RotateNoneFlipX);
    Bitmap s = new Bitmap(size, size, PixelFormat.Format32bppArgb);
    using (Graphics g = Graphics.FromImage(s)) {
      g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
      g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
      g.DrawImage(s0, new Rectangle(0, 0, size, size), new Rectangle(0, 0, s0.Width, s0.Height), GraphicsUnit.Pixel);
    }
    s0.Dispose();
    int W = s.Width, H = s.Height, N = W * H;
    byte[] src = Grab(s); s.Dispose();
    // owner[i]: 0 body, 1 head, 2 upper fist, 3 lower fist
    byte[] owner = new byte[N];
    for (int k = 0; k < maskPaths.Length; k++) {
      Bitmap m = new Bitmap(maskPaths[k]);
      byte[] mb = Grab(m); m.Dispose();
      for (int i = 0; i < N; i++) if (owner[i] == 0 && mb[i * 4] > 127) owner[i] = (byte)(k + 1);
    }
    byte[][] outb = new byte[4][];
    for (int k = 0; k < 4; k++) outb[k] = new byte[N * 4];
    for (int i = 0; i < N; i++) {
      int k = owner[i], q = i * 4;
      outb[k][q] = src[q]; outb[k][q + 1] = src[q + 1]; outb[k][q + 2] = src[q + 2]; outb[k][q + 3] = src[q + 3];
    }
    for (int k = 0; k < 4; k++) Put(outb[k], W, H, outPaths[k]);
    // restack from the files just written: last opaque layer wins, exactly as the page paints
    byte[] re = new byte[N * 4];
    for (int k = 0; k < 4; k++) {
      Bitmap b = new Bitmap(outPaths[k]);
      byte[] lb = Grab(b); b.Dispose();
      for (int i = 0; i < N; i++) {
        int q = i * 4;
        if (lb[q + 3] == 0) continue;
        re[q] = lb[q]; re[q + 1] = lb[q + 1]; re[q + 2] = lb[q + 2]; re[q + 3] = lb[q + 3];
      }
    }
    // A pixel that is fully transparent on BOTH sides is identical as far as anything can
    // see: PNG still stores RGB under alpha 0 and GDI+ normalises it, which is worth 900
    // false alarms here. Only VISIBLE differences count.
    int diff = 0, hidden = 0;
    for (int i = 0; i < N; i++) {
      int q = i * 4;
      if (src[q] == re[q] && src[q + 1] == re[q + 1] && src[q + 2] == re[q + 2] && src[q + 3] == re[q + 3]) continue;
      if (src[q + 3] == 0 && re[q + 3] == 0) { hidden++; continue; }
      diff++;
    }
    return string.Format("{0}x{1}; restack check: {2} visible pixels differ from the source{3}  ({4} invisible alpha-0 RGB differences ignored)",
      W, H, diff, diff == 0 ? "  OK" : "  *** THE CUT IS WRONG, DO NOT SHIP ***", hidden);
  }
}
"@
}
$outs = @("body", "head", "hand-u", "hand-l") | ForEach-Object { Join-Path $OutDir "climber-$_.png" }
$img.Dispose()
$report = [NmCut]::Run($Src, ($mirror -eq "true"), $Size, [string[]]$masks, [string[]]$outs)
$masks | ForEach-Object { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
"wrote climber-body / -head / -hand-u / -hand-l to $OutDir"
$report
