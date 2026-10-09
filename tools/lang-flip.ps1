# lang-flip.ps1 — ONE-TIME conversion of index.html (2026-10-09) from "English in the markup,
# Georgian in data-ka" to "Georgian in the markup, English in data-en".
#
# Why: crawlers that do not run JavaScript (ChatGPT, Claude, Perplexity …) saw only the English
# text of a page marked lang="ka". With the Georgian written into the markup they read Georgian
# at oritoki.ge/, and functions/en.js serves the same file at oritoki.ge/en with every [data-en]
# element's content swapped back to English.
#
# Every one of the elements carrying data-ka holds plain text (no child tags), which is what makes
# a regex conversion safe; the script refuses to run otherwise, and re-checks its own output by
# decoding every new data-en and comparing it with the English it replaced.
#
# Usage:  powershell -File tools\lang-flip.ps1 [-Path index.html] [-WhatIf]
param([string]$Path = "index.html", [switch]$WhatIf)

$enc  = New-Object System.Text.UTF8Encoding($false)
$full = (Resolve-Path $Path).Path
$src  = [IO.File]::ReadAllText($full, $enc)

if ($src -match '\sdata-en="') { throw "data-en already present - this file was flipped before." }

$re = [regex]'<(?<tag>[a-zA-Z0-9]+)(?<pre>\b[^>]*?)\sdata-ka="(?<ka>[^"]*)"(?<post>[^>]*)>(?<inner>[^<]*)</\k<tag>>'
$all = [regex]::Matches($src, '<[a-zA-Z0-9]+\b[^>]*\sdata-ka="[^"]*"[^>]*>').Count
$hits = $re.Matches($src)
if ($hits.Count -ne $all) { throw "Only $($hits.Count) of $all data-ka elements are plain-text leaves - refusing." }

function AttrEsc([string]$s) { $s.Replace('&', '&amp;').Replace('"', '&quot;') }

$out = $re.Replace($src, {
  param($m)
  $tag = $m.Groups['tag'].Value
  $ka  = $m.Groups['ka'].Value
  $kaHtml = [Net.WebUtility]::HtmlDecode($ka)          # exactly what applyLanguage assigns to innerHTML
  if ($kaHtml -match '<') { throw "data-ka with markup: $ka" }
  # keep entities that matter as HTML text
  $kaHtml = $kaHtml.Replace('&', '&amp;')
  '<' + $tag + $m.Groups['pre'].Value + ' data-ka="' + $ka + '" data-en="' + (AttrEsc $m.Groups['inner'].Value) + '"' + $m.Groups['post'].Value + '>' + $kaHtml + '</' + $tag + '>'
})

# Self-check: every data-en must decode back to the English it replaced, in order.
$check = [regex]::Matches($out, '\sdata-en="([^"]*)"')
if ($check.Count -ne $hits.Count) { throw "count mismatch $($check.Count) vs $($hits.Count)" }
for ($i = 0; $i -lt $hits.Count; $i++) {
  $back = [Net.WebUtility]::HtmlDecode($check[$i].Groups[1].Value)
  $orig = $hits[$i].Groups['inner'].Value                # data-en holds innerHTML, so compare raw
  if ($back -ne $orig) { throw "round-trip failed at #$i : '$orig' -> '$back'" }
}
# Nothing outside the converted elements may change.
$strip = { param($s) [regex]::Replace($s, '<[a-zA-Z0-9]+\b[^>]*\sdata-ka="[^"]*"[^>]*>[^<]*</[a-zA-Z0-9]+>', '#') }
if ((& $strip $src) -ne (& $strip $out)) { throw "text outside the data-ka elements changed - refusing." }

"converted $($hits.Count) elements; round-trip OK; rest of file identical"
if (-not $WhatIf) { [IO.File]::WriteAllText($full, $out, $enc); "written $full" }
