# Renders the page with the technician DRAGGED sideways and lays the numbered grid over it, so the
# owner can mark notes on the state that only exists while something is being held. Same grid as
# tools/page-grid.ps1; the drag is done by dispatching pointer events at the figure itself (the
# handler is bound to the element, not to the document, so events sent to the document do nothing).
param([int]$DSF = 3, [int]$Drag = -60, [int]$Win = 430, [int]$WinH = 760,
      [int]$CropX = 0, [int]$CropY = 0, [int]$CropW = 430, [int]$CropH = 700,
      [int]$Zoom = 2, [int]$Step = 20, [int]$Label = 40,
      [string]$Out = "C:\Users\gilmo\Downloads\drag-grid.png")
$repo = "c:\Users\gilmo\OneDrive\Documents\GitHub\oritoki"
$sc = "C:\Users\gilmo\AppData\Local\Temp\claude\c--Users-gilmo-OneDrive-Documents-GitHub-oritoki\dbd6aea5-c872-4e60-b422-1a568d20c71e\scratchpad"
$t = [System.IO.File]::ReadAllText("$repo\index.html", [System.Text.Encoding]::UTF8)
$i = $t.IndexOf('<head>') + 6
$t = $t.Insert($i, "`n<script>try{localStorage.setItem('oritoki_theme','dark')}catch(e){}</script>")
$js = @'
<script>
addEventListener('load',function(){
  setTimeout(function(){
    var c=document.getElementById('climber'), r=c.getBoundingClientRect();
    var cx=r.left+r.width/2, cy=r.top+r.height/2, N=12, step=(DRAGPX)/N;
    function pe(type,x){ c.dispatchEvent(new PointerEvent(type,{bubbles:true,cancelable:true,clientX:x,clientY:cy,pointerId:1,isPrimary:true,buttons:1,pointerType:'mouse'})); }
    pe('pointerdown',cx);
    for(var i=1;i<=N;i++){ pe('pointermove',cx+step*i); }
  },900);
});
</script>
'@
$t = $t.Insert($t.LastIndexOf('</body>'), $js.Replace('DRAGPX', "$Drag"))
[System.IO.File]::WriteAllText("$repo\_drag.html", $t, (New-Object System.Text.UTF8Encoding($false)))

$shot = "$sc\dragshot.png"
if (Test-Path $shot) { [System.IO.File]::Delete($shot) }
$udd = Join-Path $sc ("cp" + (Get-Random))
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --no-sandbox `
  --user-data-dir="$udd" --hide-scrollbars --force-device-scale-factor=$DSF --virtual-time-budget=9000 `
  --window-size=$Win,$WinH --screenshot="$shot" "file:///c:/Users/gilmo/OneDrive/Documents/GitHub/oritoki/_drag.html" | Out-Null
for ($k = 0; $k -lt 60; $k++) { if ((Test-Path $shot) -and (Get-Item $shot).Length -gt 20000) { break }; Start-Sleep -Milliseconds 400 }
[System.IO.File]::Delete("$repo\_drag.html")

Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap($shot)
$mrg = 46
$W = $CropW * $Zoom + $mrg; $H = $CropH * $Zoom + $mrg
$canvas = New-Object System.Drawing.Bitmap $W,$H,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(255,24,24,28))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($src, (New-Object System.Drawing.Rectangle $mrg,$mrg,($CropW*$Zoom),($CropH*$Zoom)),
                   (New-Object System.Drawing.Rectangle $CropX,$CropY,$CropW,$CropH), [System.Drawing.GraphicsUnit]::Pixel)
$src.Dispose()
$thin = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70,255,0,255)),1
$fat  = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(170,255,0,255)),1
$f = New-Object System.Drawing.Font("Consolas",11,[System.Drawing.FontStyle]::Bold)
$ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,80,255))
for ($x = 0; $x -le $CropW; $x += $Step) {
  $px = $mrg + $x * $Zoom
  $g.DrawLine($(if ($x % $Label -eq 0) { $fat } else { $thin }), $px, $mrg, $px, $H)
  if ($x % $Label -eq 0) { $g.DrawString(("{0:000}" -f ($CropX + $x)), $f, $ink, [single]($px - 15), [single]6) } }
for ($y = 0; $y -le $CropH; $y += $Step) {
  $py = $mrg + $y * $Zoom
  $g.DrawLine($(if ($y % $Label -eq 0) { $fat } else { $thin }), $mrg, $py, $W, $py)
  if ($y % $Label -eq 0) { $g.DrawString(("{0:000}" -f ($CropY + $y)), $f, $ink, [single]2, [single]($py - 8)) } }
$g.Dispose()
$canvas.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png); $canvas.Dispose()
"$Out   dragged $Drag px; grid step $Step, numbers every $Label (in ${DSF}x device pixels)"
