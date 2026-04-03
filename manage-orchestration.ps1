param(
    [string]$Project
)

$ErrorActionPreference = 'Stop'

function Resolve-ProjectPath {
    param([string]$ProvidedProject)

    if ($ProvidedProject) {
        return (Resolve-Path -LiteralPath $ProvidedProject).Path
    }

    $picker = Join-Path $PSScriptRoot 'pick-folder.ps1'
    $selected = & powershell -NoProfile -ExecutionPolicy Bypass -File $picker
    if (-not $selected -or $selected -eq 'CANCELLED') {
        return $null
    }
    return (Resolve-Path -LiteralPath $selected).Path
}

function Get-BoardPath {
    param([string]$ProjectDir)
    return (Join-Path $ProjectDir 'orchestration\BOARD.md')
}

function Get-BoardLines {
    param([string]$BoardPath)
    if (-not (Test-Path -LiteralPath $BoardPath)) {
        throw "BOARD.md not found: $BoardPath"
    }
    return [System.Collections.Generic.List[string]](Get-Content -LiteralPath $BoardPath)
}

function Save-BoardLines {
    param(
        [string]$BoardPath,
        [System.Collections.Generic.List[string]]$Lines
    )
    Set-Content -LiteralPath $BoardPath -Value $Lines -Encoding UTF8
}

function Remove-StateBlock {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$State
    )

    $startMarker = "<!-- ORCH-STATE: $State START -->"
    $endMarker = "<!-- ORCH-STATE: $State END -->"
    $start = $Lines.IndexOf($startMarker)
    if ($start -lt 0) {
        return
    }
    $end = $Lines.IndexOf($endMarker)
    if ($end -lt $start) {
        $end = $start
    }
    for ($i = $end; $i -ge $start; $i--) {
        $Lines.RemoveAt($i)
    }
    while ($Lines.Count -gt 1 -and [string]::IsNullOrWhiteSpace($Lines[1])) {
        if ($Lines.Count -le 2) { break }
        if ($Lines[0] -notmatch '^# ') { break }
        $Lines.RemoveAt(1)
    }
}

function Insert-StateBlock {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$State,
        [string[]]$Body
    )

    Remove-StateBlock -Lines $Lines -State $State
    $block = New-Object System.Collections.Generic.List[string]
    $block.Add("<!-- ORCH-STATE: $State START -->")
    foreach ($line in $Body) {
        $block.Add($line)
    }
    $block.Add("<!-- ORCH-STATE: $State END -->")
    $block.Add('')
    $insertAt = 1
    for ($i = $block.Count - 1; $i -ge 0; $i--) {
        $Lines.Insert($insertAt, $block[$i])
    }
}

function Get-BoardSummary {
    param([string]$BoardPath)
    $raw = Get-Content -LiteralPath $BoardPath
    $text = $raw -join "`n"
    [pscustomobject]@{
        Freeze = $text -match 'ORCH-STATE: FREEZE START'
        Drain  = $text -match 'ORCH-STATE: DRAIN_FOR_TEST START'
    }
}

function Show-Summary {
    param([string]$BoardPath)
    $summary = Get-BoardSummary -BoardPath $BoardPath
    Write-Host ""
    Write-Host "Current board state:" -ForegroundColor Cyan
    Write-Host ("  FREEZE:         {0}" -f $summary.Freeze)
    Write-Host ("  DRAIN_FOR_TEST: {0}" -f $summary.Drain)
    Write-Host ""
}

$projectPath = Resolve-ProjectPath -ProvidedProject $Project
if (-not $projectPath) {
    Write-Host 'No project selected.' -ForegroundColor Yellow
    exit 0
}

$boardPath = Get-BoardPath -ProjectDir $projectPath
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Orchestration Manager" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("Project: {0}" -f $projectPath)
Show-Summary -BoardPath $boardPath
Write-Host "1) Freeze now"
Write-Host "2) Unfreeze"
Write-Host "3) Mark drain for test"
Write-Host "4) Clear drain for test"
Write-Host "5) Open monitor snapshot"
Write-Host ""
$choice = Read-Host "Choice (1-5)"

$lines = Get-BoardLines -BoardPath $boardPath
$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

switch ($choice) {
    '1' {
        Remove-StateBlock -Lines $lines -State 'DRAIN_FOR_TEST'
        Insert-StateBlock -Lines $lines -State 'FREEZE' -Body @(
            '> FREEZE',
            "> Requested: $timestamp",
            '> Reason: Manual maintenance window. Do not start new work until this notice is removed.'
        )
        Save-BoardLines -BoardPath $boardPath -Lines $lines
        Write-Host 'FREEZE notice added.' -ForegroundColor Green
    }
    '2' {
        Remove-StateBlock -Lines $lines -State 'FREEZE'
        Remove-StateBlock -Lines $lines -State 'DRAIN_FOR_TEST'
        Save-BoardLines -BoardPath $boardPath -Lines $lines
        Write-Host 'FREEZE and DRAIN_FOR_TEST notices removed.' -ForegroundColor Green
    }
    '3' {
        Remove-StateBlock -Lines $lines -State 'FREEZE'
        Insert-StateBlock -Lines $lines -State 'DRAIN_FOR_TEST' -Body @(
            '> DRAIN_FOR_TEST',
            "> Requested: $timestamp",
            '> Rule: Finish the current task at a safe checkpoint, update BOARD/logs, do not pick new work, then idle.'
        )
        Save-BoardLines -BoardPath $boardPath -Lines $lines
        Write-Host 'DRAIN_FOR_TEST notice added.' -ForegroundColor Green
    }
    '4' {
        Remove-StateBlock -Lines $lines -State 'DRAIN_FOR_TEST'
        Save-BoardLines -BoardPath $boardPath -Lines $lines
        Write-Host 'DRAIN_FOR_TEST notice removed.' -ForegroundColor Green
    }
    '5' {
        powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'monitor-orchestration.ps1') -Project $projectPath
    }
    default {
        Write-Host 'No action taken.' -ForegroundColor Yellow
    }
}
