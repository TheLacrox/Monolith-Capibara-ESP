#requires -Version 7
[CmdletBinding()]
param(
    [string]$EnRoot = "Resources/Locale/en-US",
    [string]$EsRoot = "Resources/Locale/es-ES"
)
$ErrorActionPreference = 'Stop'
$errors = [System.Collections.Generic.List[string]]::new()

function Get-Messages([string]$path) {
    $map = @{}; $current = $null; $depth = 0
    foreach ($line in Get-Content -LiteralPath $path -Encoding utf8) {
        $o = ([regex]::Matches($line, '\{')).Count
        $c = ([regex]::Matches($line, '\}')).Count
        if ($line -match '^([A-Za-z][A-Za-z0-9_-]*)\s*=(.*)$') {
            $current = $Matches[1]; $map[$current] = $Matches[2]
            $depth = $o - $c
        } elseif ($null -ne $current -and ($line -match '^[\s{}]' -or $depth -gt 0) -and $line -notmatch '^\s*$') {
            # Fluent reads an indented line that starts with '[' or '*' as a variant key, not text.
            # Outside a select expression the engine rejects the whole file at load.
            if ($depth -eq 0 -and $line -match '^\s+([\[\*])') {
                $script:errors.Add("$path : '$current' continuation line starts with '$($Matches[1])' (Fluent parse error; put text before it or prefix { `"`" })")
            }
            $map[$current] += ' ' + $line; $depth += $o - $c
        } elseif ($line -match '^\s*$') {
            $current = $null; $depth = 0
        }
    }
    return $map
}
function Get-Vars([string]$text) {
    return @([regex]::Matches($text, '\$[A-Za-z][A-Za-z0-9_]*') | ForEach-Object { $_.Value } | Sort-Object -Unique)
}

# Intentional variable drops. Spanish grammar replaces POSS-ADJ($var) before plural body
# parts with a definite article ("junta las manos"), which can remove the message's only
# use of the variable. Every entry here is a reviewed, deliberate drop — the gate stays
# strict for everything else.
$AllowedDrops = @{
    'chat-emote-msg-clap-single' = @('$entity')
    'chat-emote-msg-snap'        = @('$entity')
    'chat-emote-msg-deathgasp'   = @('$entity')
    'silicon-emote-deathgasp'    = @('$entity')
    'chat-emote-msg-crack'       = @('$entity')
}

$esRootResolved = (Resolve-Path $EsRoot).Path
$enRootResolved = (Resolve-Path $EnRoot).Path
foreach ($esFile in Get-ChildItem -Recurse -Filter *.ftl -LiteralPath $EsRoot -ErrorAction SilentlyContinue) {
    $rel = $esFile.FullName.Substring($esRootResolved.Length).TrimStart('\','/')
    $enPath = Join-Path $enRootResolved $rel
    if (-not (Test-Path -LiteralPath $enPath)) {
        if ($rel -notmatch '^_Capibara[\\/]') { $errors.Add("$rel : no matching en-US file (orphan translation)") }
        continue
    }
    $enMsgs = Get-Messages $enPath
    $esMsgs = Get-Messages $esFile.FullName
    foreach ($id in $esMsgs.Keys) {
        if (-not $enMsgs.ContainsKey($id)) { $errors.Add("$rel : message '$id' not in en-US (hallucinated/renamed key)"); continue }
        $enVars = Get-Vars $enMsgs[$id]; $esVars = Get-Vars $esMsgs[$id]
        $missing = @($enVars | Where-Object { $_ -notin $esVars -and -not ($AllowedDrops[$id] -and $_ -in $AllowedDrops[$id]) })
        $extra   = @($esVars | Where-Object { $_ -notin $enVars })
        if ($missing) { $errors.Add("$rel : '$id' dropped variable(s): $($missing -join ', ')") }
        if ($extra)   { $errors.Add("$rel : '$id' introduced variable(s) not in source: $($extra -join ', ')") }
        $o = ([regex]::Matches($esMsgs[$id], '\{')).Count
        $c = ([regex]::Matches($esMsgs[$id], '\}')).Count
        if ($o -ne $c) { $errors.Add("$rel : '$id' unbalanced braces ($o open / $c close)") }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "FAIL: $_" -ForegroundColor Red }
    Write-Host "`n$($errors.Count) validation error(s)." -ForegroundColor Red
    exit 1
}
Write-Host "All es-ES files structurally valid." -ForegroundColor Green
exit 0
