#requires -Version 7
<#
Capibara ESP — entity localization generator.
Merges the per-batch translation maps (_Capibara/entities/tmp/tr-*.json) produced by the
entity-translation workflow, then emits valid es-ES Fluent `ent-<id>` override files from
entity-source.json. Names/descriptions with no translation fall back to English (the loc
system would fall back anyway). Handles Fluent brace-escaping and multi-line descriptions.

Output: Resources/Locale/es-ES/_Capibara/entities/entities-NN.ftl
#>
[CmdletBinding()]
param(
    [string]$Source   = "_Capibara/entities/entity-source.json",
    [string]$TmpDir   = "_Capibara/entities/tmp",
    [string]$OutDir   = "Resources/Locale/es-ES/_Capibara/entities",
    [int]   $ChunkSize = 2500
)
$ErrorActionPreference = 'Stop'

# --- merge translation maps ---
# Entity source strings are case-sensitive (for example, proper names can differ only by case).
$map = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$badFiles = @()
foreach ($f in Get-ChildItem -LiteralPath $TmpDir -Filter tr-*.json -ErrorAction SilentlyContinue) {
    try {
        $obj = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json -AsHashtable
        foreach ($k in $obj.Keys) { if (-not $map.ContainsKey($k)) { $map[$k] = $obj[$k] } }
    } catch { $badFiles += $f.Name }
}
Write-Host "Merged $($map.Count) translated strings from $TmpDir."
if ($badFiles) { Write-Host "WARN: could not parse $($badFiles.Count) batch file(s): $($badFiles -join ', ')" -ForegroundColor Yellow }

# Fluent-escape: single pass so replacements don't re-match. Literal { and } become {"{"} / {"}"}.
function ConvertTo-Fluent([string]$v) {
    return [regex]::Replace($v, '[{}]', { param($m) if ($m.Value -eq '{') { '{"{"}' } else { '{"}"}' } })
}

# --- Spanish grammatical gender heuristic. The .gender attribute drives THE()/INDEFINITE()
# article choice (el/la, un/una) via the es-ES zzzz-* grammar overrides in
# es-ES/_Capibara/grammar.ftl. Gender comes from the FIRST word of the TRANSLATED name (the
# head noun in Spanish noun phrases). Plural/unknown heads emit no attribute -> engine
# default (neuter) -> bare-name/"un" fallback. GrammarComponent (mobs) outranks this at
# runtime, so tagging creatures is harmless. Extend the exception lists as errors surface. ---
$GenderFemO    = @('mano','foto','moto','radio')                       # -o but feminine
$GenderMascA   = @('día','mapa','planeta','cometa','sofá','pijama','tranvía','mediodía',
                   'problema','sistema','tema','programa','clima','idioma','esquema','diagrama',
                   'holograma','telegrama','fantasma','plasma','drama','trauma','síntoma','dilema',
                   'emblema','poema','lema','aroma','carisma','prisma','enigma','dogma','magma',
                   'panorama','crucigrama','anagrama','genoma','cromosoma','koala','gorila','panda','pirata')
$GenderFemMisc = @('leche','sangre','llave','nave','carne','gente','mente','fuente','muerte','noche',
                   'nube','serpiente','fiebre','hambre','base','clase','frase','torre','corriente','parte',
                   'suerte','superficie','especie','serie','calle','piel','sal','miel','hiel','cárcel','señal',
                   'catedral','red','pared','sed','salud','imagen','razón','sartén','flor','labor','coliflor',
                   'luz','cruz','paz','nariz','matriz','cicatriz','raíz','nuez','vez','dosis','crisis','mujer','ley')
$GenderMascS   = @('gas','virus','mes','autobús','arnés','compás','interés','anís','oasis','análisis','énfasis')
# Feminine nouns with tonic a- ("agua", "arma", "hacha") take el/un in Spanish, so they are
# deliberately tagged male: the attribute only drives article choice, not adjective agreement.
$GenderTonicA  = '^(agua|arma|hacha|alma|área|águila|ala|hada|ancla|aula|arca|asta|alga|ave|acta|aya|ansia|habla|hambre)$'

function Get-SpanishGender([string]$esName) {
    if (-not $esName) { return $null }
    $w = (($esName.Trim()) -split '\s+')[0].ToLowerInvariant() -replace '[^a-záéíóúüñ]', ''
    if ($w.Length -lt 2) { return $null }
    if ($w -match $GenderTonicA)  { return 'male' }
    if ($w -in $GenderMascS)      { return 'male' }
    if ($w -in $GenderMascA)      { return 'male' }
    if ($w -in $GenderFemO)       { return 'female' }
    if ($w -in $GenderFemMisc)    { return 'female' }
    if ($w.EndsWith('s'))         { return $null }   # plural head noun: la/las mismatch, skip
    if ($w -match '(ción|sión|xión|dad|tad|tud|umbre|itis)$') { return 'female' }
    if ($w.EndsWith('a'))         { return 'female' }
    return 'male'   # -o / -or / -e / consonant default; exceptions listed above
}
# Emit an id/name/desc as a Fluent message, handling multi-line values via indented blocks.
function Format-Entry([string]$id, [string]$name, [string]$desc, [string]$gender) {
    $sb = [System.Text.StringBuilder]::new()
    $nl = "`n"
    $nEsc = ConvertTo-Fluent $name
    if ($nEsc -match "\r?\n") {
        [void]$sb.Append("ent-$id =$nl")
        foreach ($ln in ($nEsc -split "\r?\n")) {
            if ($ln.Length -eq 0) { [void]$sb.Append($nl) }
            else { [void]$sb.Append("    $ln$nl") }
        }
    } else {
        [void]$sb.Append("ent-$id = $nEsc$nl")
    }
    if ($gender) { [void]$sb.Append("    .gender = $gender$nl") }
    if ($desc -and $desc.Trim()) {
        $dEsc = ConvertTo-Fluent $desc
        if ($dEsc -match "\r?\n") {
            [void]$sb.Append("    .desc =$nl")
            foreach ($ln in ($dEsc -split "\r?\n")) {
                if ($ln.Length -eq 0) { [void]$sb.Append($nl) }
                else { [void]$sb.Append("        $ln$nl") }
            }
        } else {
            [void]$sb.Append("    .desc = $dEsc$nl")
        }
    }
    return $sb.ToString()
}

# --- exclusion set: ent- ids already defined in the mirrored es-ES tree (translated from
# upstream .ftl files that define entity overrides, e.g. _DV vending-crates). Emitting them
# again here would be a duplicate-message Fluent error at load time. ---
$already = @{}
$outDirResolved = (Resolve-Path -ErrorAction SilentlyContinue $OutDir)?.Path
foreach ($f in Get-ChildItem -Recurse "Resources/Locale/es-ES" -Filter *.ftl) {
    if ($outDirResolved -and $f.FullName.StartsWith($outDirResolved)) { continue }
    foreach ($m in [regex]::Matches((Get-Content -LiteralPath $f.FullName -Raw), '(?m)^ent-([A-Za-z0-9_-]+)\s*=')) {
        $already[$m.Groups[1].Value] = $true
    }
}
Write-Host "Excluding $($already.Count) entity id(s) already defined in the mirrored es-ES tree."

# --- generate ---
$data = Get-Content -LiteralPath $Source -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force $OutDir | Out-Null
Get-ChildItem -LiteralPath $OutDir -Filter *.ftl -ErrorAction SilentlyContinue | Remove-Item -Force

$missName = 0; $missDesc = 0; $emitted = 0; $chunkIdx = 0; $gendered = 0
$buf = [System.Text.StringBuilder]::new()
$inChunk = 0
function Flush-Chunk([System.Text.StringBuilder]$b, [int]$idx, [string]$dir) {
    if ($b.Length -eq 0) { return }
    $path = Join-Path $dir ("entities-{0:D2}.ftl" -f $idx)
    Set-Content -LiteralPath $path -Value $b.ToString() -NoNewline
}

foreach ($e in ($data | Sort-Object id)) {
    if (-not ($e.name -and $e.name.Trim())) { continue }   # skip name-less entities (keep English)
    if ($already.ContainsKey($e.id)) { continue }          # already localized in the mirrored tree
    $esName = if ($map.ContainsKey($e.name)) { $map[$e.name] } else { $missName++; $e.name }
    $esDesc = ""
    if ($e.desc -and $e.desc.Trim()) {
        if ($map.ContainsKey($e.desc)) { $esDesc = $map[$e.desc] } else { $missDesc++; $esDesc = $e.desc }
    }
    # Gender only when the name actually got translated (the heuristic is Spanish-only) AND
    # the entry emits a .desc: the engine demands .desc on any message that has attributes
    # (LocalizationManager.Entity.cs) and would log "No value: ent-X.desc" per boot otherwise.
    $gender = if ($map.ContainsKey($e.name) -and $esDesc -and $esDesc.Trim()) { Get-SpanishGender $esName } else { $null }
    if ($gender) { $gendered++ }
    [void]$buf.Append((Format-Entry $e.id $esName $esDesc $gender))
    [void]$buf.Append("`n")
    $emitted++; $inChunk++
    if ($inChunk -ge $ChunkSize) { Flush-Chunk $buf $chunkIdx $OutDir; $buf.Clear() | Out-Null; $chunkIdx++; $inChunk = 0 }
}
Flush-Chunk $buf $chunkIdx $OutDir

Write-Host "Emitted $emitted entities into $($chunkIdx + 1) file(s) under $OutDir."
Write-Host "Untranslated (fell back to English): names=$missName descs=$missDesc"
Write-Host "Tagged with .gender: $gendered (plural/untranslated heads left neuter)"
