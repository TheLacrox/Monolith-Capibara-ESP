#requires -Version 7
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$message) {
    $failures.Add($message)
}

try {
    $root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
}
catch {
    Write-Host "FAIL: Repository root does not exist: $RepositoryRoot" -ForegroundColor Red
    exit 1
}

function Get-RepositoryPath([string]$relativePath) {
    return Join-Path $root $relativePath
}

function Get-RequiredFile([string]$relativePath, [string]$kind = 'file') {
    $path = Get-RepositoryPath $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required $kind`: $relativePath"
        return $null
    }
    return $path
}

$entrypoints = @('AGENTS.md', 'CLAUDE.md')
$criticalHeadings = @(
    '## Upstream',
    '## Iron rules',
    '## Fluent-preservation rules',
    '## Verify',
    '## Deployment'
)

foreach ($entrypoint in $entrypoints) {
    $path = Get-RequiredFile $entrypoint 'entrypoint'
    if ($null -eq $path) {
        continue
    }

    $raw = Get-Content -LiteralPath $path -Raw
    foreach ($heading in $criticalHeadings) {
        $headingPattern = '(?m)^' + [regex]::Escape($heading) + '(?:\s|\()'
        if ($raw -notmatch $headingPattern) {
            Add-Failure "Missing critical heading '$heading' in $entrypoint"
        }
    }

    if ($raw -notmatch [regex]::Escape('_Capibara/agent-workflows.md')) {
        Add-Failure "Missing shared workflow reference in $entrypoint"
    }
}

[void](Get-RequiredFile '_Capibara/agent-workflows.md' 'workflow file')
$translationWorkflowPath = Get-RequiredFile '_Capibara/translate-workflow.md' 'workflow file'

$referencedRepositoryFiles = @(
    '_Capibara/glossary.md',
    '_Capibara/sync-locale.ps1',
    '_Capibara/validate-locale.ps1',
    '_Capibara/validate-guidebook.ps1',
    '_Capibara/generate-entity-ftl.ps1'
)
foreach ($relativePath in $referencedRepositoryFiles) {
    [void](Get-RequiredFile $relativePath 'referenced repository file')
}

if ($null -ne $translationWorkflowPath) {
    $translationWorkflow = Get-Content -LiteralPath $translationWorkflowPath -Raw
    if ($translationWorkflow -notmatch [regex]::Escape('Current default: incremental maintenance')) {
        Add-Failure 'Current translation workflow must declare incremental maintenance as the default.'
    }
    $legacyHeading = '## Legacy full-tree Claude workflow'
    $legacyIndex = $translationWorkflow.IndexOf($legacyHeading, [System.StringComparison]::Ordinal)
    if ($legacyIndex -lt 0) {
        Add-Failure 'Current translation workflow must isolate the legacy full-tree Claude workflow.'
    }
    else {
        $activeWorkflow = $translationWorkflow.Substring(0, $legacyIndex)
        if ($activeWorkflow -match '(?i)(main Claude session|Claude subagents|Workflow tool|resumeFromRunId|await pipeline)') {
            Add-Failure 'Claude-only instruction appears before legacy section in _Capibara/translate-workflow.md.'
        }
    }
}

$skillNames = @(
    'capibara-sync-upstream',
    'capibara-translate-fluent',
    'capibara-translate-guidebook',
    'capibara-refresh-entities',
    'capibara-verify',
    'capibara-create-pr'
)
$seenNames = @{}

foreach ($expectedName in $skillNames) {
    $relativePath = ".agents/skills/$expectedName/SKILL.md"
    $path = Get-RequiredFile $relativePath 'skill file'
    if ($null -eq $path) {
        continue
    }

    $raw = Get-Content -LiteralPath $path -Raw
    $frontmatterMatch = [regex]::Match(
        $raw,
        '\A---\r?\n(?<frontmatter>.*?)\r?\n---(?:\r?\n|\z)',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $frontmatterMatch.Success) {
        Add-Failure "Invalid frontmatter in $relativePath"
        continue
    }

    $fields = @{}
    foreach ($line in ($frontmatterMatch.Groups['frontmatter'].Value -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }
        if ($line -notmatch '^(?<key>[A-Za-z0-9_-]+):\s*(?<value>.*)$') {
            Add-Failure "Invalid frontmatter line in $relativePath`: $line"
            continue
        }

        $key = $Matches['key']
        $value = $Matches['value'].Trim().Trim('"', "'")
        if ($fields.ContainsKey($key)) {
            Add-Failure "Duplicate frontmatter field '$key' in $relativePath"
            continue
        }
        $fields[$key] = $value
    }

    foreach ($key in $fields.Keys) {
        if ($key -notin @('name', 'description')) {
            Add-Failure "Unexpected frontmatter field '$key' in $relativePath"
        }
    }
    foreach ($requiredField in @('name', 'description')) {
        if (-not $fields.ContainsKey($requiredField) -or
            [string]::IsNullOrWhiteSpace([string]$fields[$requiredField])) {
            Add-Failure "Missing or empty frontmatter field '$requiredField' in $relativePath"
        }
    }

    if ($fields.ContainsKey('name')) {
        $actualName = [string]$fields['name']
        if ($actualName -ne $expectedName) {
            Add-Failure "Skill name mismatch in $relativePath`: expected '$expectedName' got '$actualName'"
        }
        if ($seenNames.ContainsKey($actualName)) {
            Add-Failure "Duplicate skill name '$actualName' in $relativePath and $($seenNames[$actualName])"
        }
        else {
            $seenNames[$actualName] = $relativePath
        }
    }

    foreach ($reference in @('AGENTS.md', '_Capibara/agent-workflows.md', '_Capibara/glossary.md')) {
        if ($raw -notmatch [regex]::Escape($reference)) {
            Add-Failure "Missing required reference '$reference' in $relativePath"
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "FAIL: $_" -ForegroundColor Red }
    Write-Host "`n$($failures.Count) agent setup validation error(s)." -ForegroundColor Red
    exit 1
}

Write-Host 'Agent setup valid: 2 entrypoints, 6 skills, shared workflows.' -ForegroundColor Green
exit 0
