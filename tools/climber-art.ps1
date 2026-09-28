# Makes the technician READ at 116px by simplifying the drawing, not by enlarging it.
#
# Enlarging worked and was rejected: at 190px he is crisp, but --worker-width is the size of
# the whole lockup, so the wordmark grew 1.64x with him and that is not acceptable.
#
# The actual problem is that this drawing carries more line than 116 pixels can hold: fine
# hatching, stitch lines, thin fold shading. Shrunk 6x they do not disappear, they average
# into a grey haze over everything, which is exactly what "blurry" looks like. The previous
# technician read cleanly at the same size because his linework was bolder and simpler.
#
# So, at FULL source resolution, before any downscaling:
#   1. levels - everything lighter than Hi goes to pure white, killing the hatching and the
#      fold shading outright; everything darker than Lo goes to pure black.
#   2. dilate - grow the remaining dark by Dilate px, so the outlines that survive are thick
#      enough to still be a line after a 6x reduction.
# Then the usual premultiplied downscale and unsharp.
#
# Dilate is in SOURCE pixels and the source is 1227 wide against a 116px strip, so one pixel
# here is about a tenth of a screen pixel - it takes 6 or 8 before anything shows.
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\man mana.png",
  [int]$Width = 232,          # 2x a 116px strip
  [int]$Lo = 100, [int]$Hi = 150, [int]$Dilate = 0,   # settled: see the header
  [double]$Amount = 1.2, [double]$Contrast = 1.15,
  [string]$Dst = "C:\Users\gilmo\OneDrive\Documents\GitHub\oritoki\images\climber.png"
)
Add-Type -AssemblyName System.Drawing
if (-not ("BoldArt" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;using System.Drawing;using System.Drawing.Imaging;using System.Drawing.Drawing2D;using System.Runtime.InteropServices;
public class BoldArt{
 static byte[] G(Bitmap b){int N=b.Width*b.Height;BitmapData d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);byte[] v=new byte[N*4];Marshal.Copy(d.Scan0,v,0,N*4);b.UnlockBits(d);return v;}
 static Bitmap P(byte[] v,int W,int H){Bitmap b=new Bitmap(W,H,PixelFormat.Format32bppArgb);BitmapData d=b.LockBits(new Rectangle(0,0,W,H),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);return b;}
 public static string Go(string src,string dst,int W,int lo,int hi,int dil,double amount,double contrast){
  Bitmap s=new Bitmap(src); int SW=s.Width,SH=s.Height,SN=SW*SH; byte[] sb=G(s); s.Dispose();
  // 1. levels, on luminance - the drawing is pure greyscale so this is exact
  byte[] lv=new byte[SN];
  for(int i=0;i<SN;i++){int q=i*4;
   double l=0.299*sb[q+2]+0.587*sb[q+1]+0.114*sb[q];
   double v=(l-lo)/(double)(hi-lo); if(v<0)v=0; if(v>1)v=1;
   lv[i]=(byte)Math.Round(v*255);}
  // 2. dilate the dark: a pixel goes as dark as the darkest within the radius
  if(dil>0){
   byte[] dl=new byte[SN];
   for(int y=0;y<SH;y++)for(int x=0;x<SW;x++){
    int mn=255;
    for(int dy=-dil;dy<=dil;dy++){int ny=y+dy;if(ny<0||ny>=SH)continue;
     for(int dx=-dil;dx<=dil;dx++){int nx=x+dx;if(nx<0||nx>=SW)continue;
      if(dx*dx+dy*dy>dil*dil)continue;
      int v=lv[ny*SW+nx]; if(v<mn)mn=v;}}
    dl[y*SW+x]=(byte)mn;}
   lv=dl;}
  byte[] pm=new byte[SN*4];
  for(int i=0;i<SN;i++){int q=i*4;double a=sb[q+3]/255.0;byte g0=lv[i];
   pm[q]=(byte)Math.Round(g0*a);pm[q+1]=pm[q];pm[q+2]=pm[q];pm[q+3]=sb[q+3];}
  Bitmap pmb=P(pm,SW,SH);
  int H=(int)Math.Round((double)W*SH/SW);
  Bitmap small=new Bitmap(W,H,PixelFormat.Format32bppArgb);
  using(Graphics g=Graphics.FromImage(small)){
   g.CompositingMode=CompositingMode.SourceCopy;
   g.InterpolationMode=InterpolationMode.HighQualityBicubic;
   g.PixelOffsetMode=PixelOffsetMode.HighQuality;
   g.DrawImage(pmb,new Rectangle(0,0,W,H),new Rectangle(0,0,SW,SH),GraphicsUnit.Pixel);}
  pmb.Dispose();
  int N=W*H; byte[] ob=G(small); small.Dispose();
  for(int i=0;i<N;i++){int q=i*4;int a=ob[q+3];if(a==0){ob[q]=ob[q+1]=ob[q+2]=0;continue;}
   double f=255.0/a;
   for(int c=0;c<3;c++) ob[q+c]=(byte)Math.Min(255,Math.Round(ob[q+c]*f));}
  double[] lum=new double[N];
  for(int i=0;i<N;i++) lum[i]=ob[i*4+1];
  double[] bl=new double[N];
  for(int y=0;y<H;y++)for(int x=0;x<W;x++){
   double sum=0;int cnt=0;
   for(int dy=-1;dy<=1;dy++){int ny=y+dy;if(ny<0||ny>=H)continue;
    for(int dx=-1;dx<=1;dx++){int nx=x+dx;if(nx<0||nx>=W)continue;sum+=lum[ny*W+nx];cnt++;}}
   bl[y*W+x]=sum/cnt;}
  for(int i=0;i<N;i++){int q=i*4;double d0=lum[i]-bl[i];
   for(int c=0;c<3;c++){double v=ob[q+c]+amount*d0;
    v=((v/255.0-0.5)*contrast+0.5)*255.0;
    ob[q+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(v)));}}
  Bitmap outb=P(ob,W,H); outb.Save(dst,ImageFormat.Png); outb.Dispose();
  return W+"x"+H;
 }}
"@
}
if ($Dst -eq "") { $Dst = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad\bold-$Lo-$Hi-$Dilate.png" }
$size = [BoldArt]::Go($Src, $Dst, $Width, $Lo, $Hi, $Dilate, $Amount, $Contrast)
"{0}  {1}  {2} KB  (levels {3}..{4}, dilate {5})" -f $Dst, $size, [math]::Round((Get-Item $Dst).Length/1KB), $Lo, $Hi, $Dilate
