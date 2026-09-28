# Finds the separate drawings on the owner's sheet and reports each one's box.
#
# `Desktop\try.png` is three pieces on one transparent canvas, drawn apart on purpose:
# the technician with his descender, the absorber with its two carabiners and the harness
# ring, and the ASAP - which has a real HOLE in it for the rope to pass through.
#
# Nothing here places anything. It only labels the connected blobs of ink so the pieces can
# be named and measured before climber-compose.ps1 puts them where the ropes need them.
#
# Labelled in C#: the sheet is 2541x2013, five million pixels, and GetPixel in PowerShell
# would take minutes.
param(
  [string]$Src = "C:\Users\gilmo\OneDrive\Desktop\try.png",
  [int]$Alpha = 24,
  [int]$MinArea = 400,        # ignore specks and stray antialiasing
  [string]$OutDir = ""        # set to write each part out as its own cropped PNG
)
Add-Type -AssemblyName System.Drawing
if (-not ("PartFind" -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public class PartFind {
  public static string Run(string src, int alpha, int minArea, string outDir) {
    Bitmap b = new Bitmap(src);
    int W = b.Width, H = b.Height, N = W * H;
    BitmapData d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    byte[] buf = new byte[N * 4];
    Marshal.Copy(d.Scan0, buf, 0, N * 4);
    b.UnlockBits(d);
    // 8-connected flood fill over an explicit stack - recursion would blow up on a blob
    // this size, and a blob here is hundreds of thousands of pixels.
    int[] lab = new int[N];
    int[] stack = new int[N];
    List<int[]> boxes = new List<int[]>();   // x0,y0,x1,y1,area
    int next = 0;
    for (int s = 0; s < N; s++) {
      if (lab[s] != 0 || buf[s * 4 + 3] < alpha) continue;
      next++;
      int sp = 0; stack[sp++] = s; lab[s] = next;
      int x0 = W, y0 = H, x1 = -1, y1 = -1, area = 0;
      while (sp > 0) {
        int p = stack[--sp];
        int px = p % W, py = p / W;
        area++;
        if (px < x0) x0 = px; if (px > x1) x1 = px;
        if (py < y0) y0 = py; if (py > y1) y1 = py;
        for (int dy = -1; dy <= 1; dy++) {
          int ny = py + dy; if (ny < 0 || ny >= H) continue;
          for (int dx = -1; dx <= 1; dx++) {
            int nx = px + dx; if (nx < 0 || nx >= W) continue;
            int q = ny * W + nx;
            if (lab[q] != 0 || buf[q * 4 + 3] < alpha) continue;
            lab[q] = next; stack[sp++] = q;
          }
        }
      }
      boxes.Add(new int[] { x0, y0, x1, y1, area, next });
    }
    // biggest first
    boxes.Sort(delegate(int[] p, int[] q) { return q[4].CompareTo(p[4]); });
    System.Text.StringBuilder sb = new System.Text.StringBuilder();
    sb.AppendLine("sheet " + W + " x " + H + ";  " + next + " blobs, listing those over " + minArea + " px:");
    int kept = 0;
    foreach (int[] o in boxes) {
      if (o[4] < minArea) continue;
      kept++;
      sb.AppendLine(string.Format("  part {0}:  x {1}..{2} ({3} wide)   y {4}..{5} ({6} tall)   {7} px of ink",
        kept, o[0], o[2], o[2] - o[0] + 1, o[1], o[3], o[3] - o[1] + 1, o[4]));
      if (outDir.Length > 0) {
        int pw = o[2] - o[0] + 1, ph = o[3] - o[1] + 1;
        byte[] ob = new byte[pw * ph * 4];
        for (int y = o[1]; y <= o[3]; y++)
          for (int x = o[0]; x <= o[2]; x++) {
            int sidx = y * W + x;
            if (lab[sidx] != o[5]) continue;          // only THIS blob, not a neighbour's ink
            int didx = (y - o[1]) * pw + (x - o[0]);
            for (int c = 0; c < 4; c++) ob[didx * 4 + c] = buf[sidx * 4 + c];
          }
        Bitmap ob2 = new Bitmap(pw, ph, PixelFormat.Format32bppArgb);
        BitmapData d2 = ob2.LockBits(new Rectangle(0, 0, pw, ph), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(ob, 0, d2.Scan0, ob.Length);
        ob2.UnlockBits(d2);
        ob2.Save(System.IO.Path.Combine(outDir, "part-" + kept + ".png"), ImageFormat.Png);
        ob2.Dispose();
      }
    }
    b.Dispose();
    return sb.ToString();
  }
}
"@
}
if ($OutDir.Length -gt 0 -and -not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
[PartFind]::Run($Src, $Alpha, $MinArea, $OutDir)
