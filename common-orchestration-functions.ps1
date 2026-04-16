# 오케스트레이션 공통 함수 모듈

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
        ConflictRecovery = $text -match 'ORCH-STATE: CONFLICT_RECOVERY START'
    }
}

function Show-Summary {
    param([string]$BoardPath)
    $summary = Get-BoardSummary -BoardPath $BoardPath
    Write-Host ""
    Write-Host "현재 보드 상태:" -ForegroundColor Cyan
    Write-Host ("  FREEZE:            {0}" -f $summary.Freeze)
    Write-Host ("  DRAIN_FOR_TEST:    {0}" -f $summary.Drain)
    Write-Host ("  CONFLICT_RECOVERY: {0}" -f $summary.ConflictRecovery)
    Write-Host ""
}