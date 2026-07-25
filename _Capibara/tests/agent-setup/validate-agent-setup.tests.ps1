#requires -Version 7
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$validator = Join-Path $repositoryRoot '_Capibara/validate-agent-setup.ps1'

if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) {
    throw "Validator script missing: $validator"
}

function Invoke-AgentValidator([string]$root) {
    $output = (& pwsh -NoProfile -File $validator -RepositoryRoot $root 2>&1 | Out-String).Trim()
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = $output
    }
}

function Assert-ExitCode($result, [int]$expected, [string]$caseName) {
    if ($result.ExitCode -ne $expected) {
        throw "$caseName expected exit $expected, got $($result.ExitCode). Output:`n$($result.Output)"
    }
}

function Assert-OutputMatch($result, [string]$pattern, [string]$caseName) {
    if ($result.Output -notmatch $pattern) {
        throw "$caseName expected output matching '$pattern'. Output:`n$($result.Output)"
    }
}

function Restore-File([string]$relativePath, [string]$fixtureRoot) {
    $source = Join-Path $repositoryRoot $relativePath
    $destination = Join-Path $fixtureRoot $relativePath
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

$real = Invoke-AgentValidator $repositoryRoot
Assert-ExitCode $real 0 'real repository'
Assert-OutputMatch $real 'Agent setup valid: 2 entrypoints, 6 skills, shared workflows\.' 'real repository'

$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$fixtureRoot = Join-Path $tempBase ("capibara-agent-setup-tests-" + [guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
    Restore-File 'AGENTS.md' $fixtureRoot
    Restore-File 'CLAUDE.md' $fixtureRoot
    Restore-File '_Capibara/agent-workflows.md' $fixtureRoot
    Restore-File '_Capibara/translate-workflow.md' $fixtureRoot
    Restore-File '_Capibara/glossary.md' $fixtureRoot
    Restore-File '_Capibara/sync-locale.ps1' $fixtureRoot
    Restore-File '_Capibara/validate-locale.ps1' $fixtureRoot
    Restore-File '_Capibara/validate-guidebook.ps1' $fixtureRoot
    Restore-File '_Capibara/generate-entity-ftl.ps1' $fixtureRoot
    Copy-Item -LiteralPath (Join-Path $repositoryRoot '.agents') -Destination $fixtureRoot -Recurse

    $validFixture = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $validFixture 0 'valid fixture'

    $verifySkill = '.agents/skills/capibara-verify/SKILL.md'
    Remove-Item -LiteralPath (Join-Path $fixtureRoot $verifySkill)
    $missingSkill = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $missingSkill 1 'missing skill'
    Assert-OutputMatch $missingSkill 'Missing required skill file: .*capibara-verify[\\/]SKILL\.md' 'missing skill'
    Restore-File $verifySkill $fixtureRoot

    $glossary = '_Capibara/glossary.md'
    Remove-Item -LiteralPath (Join-Path $fixtureRoot $glossary)
    $missingReference = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $missingReference 1 'missing referenced file'
    Assert-OutputMatch $missingReference 'Missing required referenced repository file: _Capibara/glossary\.md' 'missing referenced file'
    Restore-File $glossary $fixtureRoot

    $prSkill = '.agents/skills/capibara-create-pr/SKILL.md'
    $prSkillPath = Join-Path $fixtureRoot $prSkill
    $prRaw = Get-Content -LiteralPath $prSkillPath -Raw
    $prRaw = $prRaw.Replace('name: capibara-create-pr', 'name: capibara-create-pull-request')
    [System.IO.File]::WriteAllText($prSkillPath, $prRaw)
    $wrongName = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $wrongName 1 'skill name mismatch'
    Assert-OutputMatch $wrongName 'Skill name mismatch.*capibara-create-pr' 'skill name mismatch'
    Restore-File $prSkill $fixtureRoot

    $fluentSkill = '.agents/skills/capibara-translate-fluent/SKILL.md'
    $fluentSkillPath = Join-Path $fixtureRoot $fluentSkill
    $fluentRaw = Get-Content -LiteralPath $fluentSkillPath -Raw
    $fluentRaw = $fluentRaw.Replace("description: Use when", "metadata: invalid`ndescription: Use when")
    [System.IO.File]::WriteAllText($fluentSkillPath, $fluentRaw)
    $extraField = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $extraField 1 'unexpected frontmatter field'
    Assert-OutputMatch $extraField "Unexpected frontmatter field 'metadata'" 'unexpected frontmatter field'
    Restore-File $fluentSkill $fixtureRoot

    $claudePath = Join-Path $fixtureRoot 'CLAUDE.md'
    $claudeRaw = Get-Content -LiteralPath $claudePath -Raw
    $claudeRaw = $claudeRaw.Replace('## Iron rules (keep merges conflict-free)', '## Merge policy')
    [System.IO.File]::WriteAllText($claudePath, $claudeRaw)
    $missingHeading = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $missingHeading 1 'missing critical heading'
    Assert-OutputMatch $missingHeading "Missing critical heading '## Iron rules' in CLAUDE\.md" 'missing critical heading'
    Restore-File 'CLAUDE.md' $fixtureRoot

    $workflowPath = Join-Path $fixtureRoot '_Capibara/translate-workflow.md'
    $workflowRaw = Get-Content -LiteralPath $workflowPath -Raw
    $workflowRaw = $workflowRaw.Replace('Current default: incremental maintenance', 'Historical mode: incremental maintenance')
    [System.IO.File]::WriteAllText($workflowPath, $workflowRaw)
    $wrongDefault = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $wrongDefault 1 'non-incremental default'
    Assert-OutputMatch $wrongDefault 'must declare incremental maintenance as the default' 'non-incremental default'
    Restore-File '_Capibara/translate-workflow.md' $fixtureRoot

    $workflowRaw = Get-Content -LiteralPath $workflowPath -Raw
    $workflowRaw = $workflowRaw.Replace(
        '## Incremental maintenance',
        "Run from the main Claude session with the Workflow tool.`r`n`r`n## Incremental maintenance"
    )
    [System.IO.File]::WriteAllText($workflowPath, $workflowRaw)
    $activeClaudeOnly = Invoke-AgentValidator $fixtureRoot
    Assert-ExitCode $activeClaudeOnly 1 'active Claude-only workflow'
    Assert-OutputMatch $activeClaudeOnly 'Claude-only instruction appears before legacy section' 'active Claude-only workflow'

    Write-Host 'Agent setup validator tests passed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        $fixtureFull = [System.IO.Path]::GetFullPath($fixtureRoot)
        $safePrefix = $tempBase.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $fixtureFull.StartsWith($safePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove fixture outside temp: $fixtureFull"
        }
        Remove-Item -LiteralPath $fixtureFull -Recurse -Force
    }
}
