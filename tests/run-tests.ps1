<#
  Runs tests/apply.test.html in headless Chrome and prints the result.

    powershell -ExecutionPolicy Bypass -File tests\run-tests.ps1

  There is no Node on this machine, so the tests run in the browser. A module import does not
  work from file://, so this script serves the repository on localhost itself (HttpListener, no
  install), opens the page with ?report, and waits for the page to POST its results to /__result.
  Exit code 0 = all passed, 1 = a test failed, 2 = no result (timeout / Chrome not found).

  -Show opens the page in a normal Chrome window instead and keeps serving until Ctrl+C.
#>
param([int]$Port = 0, [int]$TimeoutSec = 60, [switch]$Show)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$chrome = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LocalAppData\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { Write-Host "Chrome / Edge not found."; exit 2 }

if ($Port -eq 0) { $Port = Get-Random -Minimum 20000 -Maximum 40000 }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

$types = @{ ".html" = "text/html; charset=utf-8"; ".js" = "text/javascript; charset=utf-8";
            ".css" = "text/css"; ".json" = "application/json"; ".png" = "image/png"; ".svg" = "image/svg+xml" }

$url = "http://localhost:$Port/tests/apply.test.html"
$userDir = Join-Path ([IO.Path]::GetTempPath()) ("oritoki-tests-" + [guid]::NewGuid())
if ($Show) {
  Start-Process $chrome -ArgumentList "--user-data-dir=`"$userDir`"", "--no-first-run", "--no-default-browser-check", $url | Out-Null
  Write-Host "Serving $url - Ctrl+C to stop."
} else {
  $proc = Start-Process $chrome -PassThru -ArgumentList "--headless=new", "--disable-gpu", "--no-first-run",
    "--no-default-browser-check", "--user-data-dir=`"$userDir`"", "$url`?report"
}

$results = $null
$deadline = (Get-Date).AddSeconds($TimeoutSec)
try {
  while ($null -eq $results) {
    $task = $listener.GetContextAsync()
    while (-not $task.Wait(250)) {
      if (-not $Show -and (Get-Date) -gt $deadline) { break }
    }
    if (-not $task.IsCompleted) { break }
    $ctx = $task.Result
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)

    if ($path -eq "/__result" -and $ctx.Request.HttpMethod -eq "POST") {
      $reader = New-Object IO.StreamReader($ctx.Request.InputStream, [Text.Encoding]::UTF8)
      $results = $reader.ReadToEnd() | ConvertFrom-Json
      $ctx.Response.StatusCode = 204
      $ctx.Response.Close()
      continue
    }

    $file = [IO.Path]::GetFullPath((Join-Path $root $path.TrimStart("/")))
    if ($file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $file -PathType Leaf)) {
      $bytes = [IO.File]::ReadAllBytes($file)
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $ctx.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { "application/octet-stream" }
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
  }
} finally {
  $listener.Stop()
  if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 300
  Remove-Item $userDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($null -eq $results) { Write-Host "No result from the page within $TimeoutSec s."; exit 2 }

$failed = 0
foreach ($r in $results) {
  if ($r.ok) { Write-Host "  PASS  $($r.name)" -ForegroundColor Green }
  else { $failed++; Write-Host "  FAIL  $($r.name) - $($r.error)" -ForegroundColor Red }
}
Write-Host ""
Write-Host ("{0} / {1} passed" -f ($results.Count - $failed), $results.Count)
if ($failed) { exit 1 } else { exit 0 }
