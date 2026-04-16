param(
    [string]$Project,
    [switch]$Watch,
    [int]$RefreshSeconds = 10
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

function Get-InProgressCount {
    param([string]$BoardPath)
    $lines = Get-Content -LiteralPath $BoardPath
    $inSection = $false
    $count = 0
    foreach ($line in $lines) {
        if ($line -match '^## ' -and $line -match 'In Progress') {
            $inSection = $true
            continue
        }
        if ($inSection -and $line -match '^## ') {
            break
        }
        if (-not $inSection) {
            continue
        }
        if ($line -match '^\|' -and $line -notmatch '^\|\s*-') {
            if ($line -notmatch '^\|\s*Task\s*\|' -and $line -notmatch '^\|\s*$') {
                $count++
            }
        }
    }
    return $count
}

function Set-DrainMarker {
    param([string]$BoardPath)
    $content = Get-Content -LiteralPath $BoardPath -Raw
    $start = '<!-- ORCH-STATE: DRAIN_FOR_TEST START -->'
    if ($content -match [regex]::Escape($start)) {
        return
    }
    $header = @"
<!-- ORCH-STATE: DRAIN_FOR_TEST START -->
> DRAIN_FOR_TEST
> Requested: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
> Rule: Finish the current task at a safe checkpoint, update BOARD/logs, do not pick new work, then idle.
<!-- ORCH-STATE: DRAIN_FOR_TEST END -->

"@
    $lines = Get-Content -LiteralPath $BoardPath
    if ($lines.Count -gt 1) {
        $updated = @($lines[0], '', $header.TrimEnd()) + $lines[1..($lines.Count - 1)]
    } else {
        $updated = @($lines[0], '', $header.TrimEnd())
    }
    Set-Content -LiteralPath $BoardPath -Value $updated -Encoding UTF8
}

function Set-FreezeMarker {
    param([string]$BoardPath)
    $raw = Get-Content -LiteralPath $BoardPath -Raw
    $raw = [regex]::Replace($raw, '(?s)<!-- ORCH-STATE: DRAIN_FOR_TEST START -->.*?<!-- ORCH-STATE: DRAIN_FOR_TEST END -->\r?\n?', '')
    if ($raw -notmatch '<!-- ORCH-STATE: FREEZE START -->') {
        $raw = $raw -replace '(?m)^(# .+\r?\n)', "`$1`r`n<!-- ORCH-STATE: FREEZE START -->`r`n> FREEZE`r`n> Requested: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n> Reason: Test window active. Do not start new work until this notice is removed.`r`n<!-- ORCH-STATE: FREEZE END -->`r`n"
    }
    Set-Content -LiteralPath $BoardPath -Value $raw -Encoding UTF8
}

$projectPath = Resolve-ProjectPath -ProvidedProject $Project
if (-not $projectPath) {
    Write-Host 'No project selected.' -ForegroundColor Yellow
    exit 0
}

$boardPath = Join-Path $projectPath 'orchestration\BOARD.md'
if (-not (Test-Path -LiteralPath $boardPath)) {
    throw "BOARD.md not found: $boardPath"
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Test Orchestration" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("Project: {0}" -f $projectPath)
Write-Host ""
Write-Host "1) Enter drain for test"
Write-Host "2) Watch until safe test point"
Write-Host "3) Freeze now for test"
Write-Host "4) Open orchestration monitor"
Write-Host ""
$choice = Read-Host "Choice (1-4)"

switch ($choice) {
    '1' {
        Set-DrainMarker -BoardPath $boardPath
        Write-Host 'DRAIN_FOR_TEST marker added.' -ForegroundColor Green
        Write-Host 'Agents should finish their current task, update BOARD/logs, and stop picking new work.' -ForegroundColor Green
    }
    '2' {
        Write-Host 'Watching In Progress until it reaches 0. Press Ctrl+C to stop.' -ForegroundColor Yellow

        # 성능 최적화: 이전 카운트를 저장하여 변경 시에만 출력
        $lastCount = -1
        $lastFileTime = $null

        while ($true) {
            # 성능 최적화: 파일이 변경되지 않았으면 카운트 재계산 건너뛰기
            $currentFileTime = (Get-Item -LiteralPath $boardPath).LastWriteTime

            if ($null -eq $lastFileTime -or $currentFileTime -ne $lastFileTime) {
                $count = Get-InProgressCount -BoardPath $boardPath
                $lastFileTime = $currentFileTime

                # 카운트가 변경된 경우에만 출력 (스팸 방지)
                if ($count -ne $lastCount) {
                    Write-Host ("[{0}] In Progress: {1}" -f (Get-Date -Format 'HH:mm:ss'), $count)
                    $lastCount = $count
                }

                if ($count -le 0) {
                    Set-FreezeMarker -BoardPath $boardPath
                    Write-Host 'Safe test point reached. FREEZE marker added.' -ForegroundColor Green
                    break
                }
            }

            # 성능 최적화: 적응형 대기 시간 (변화가 없으면 대기 시간 증가)
            if ($null -ne $lastFileTime -and $currentFileTime -eq $lastFileTime) {
                Start-Sleep -Seconds ([Math]::Min($RefreshSeconds * 2, 30))  # 최대 30초
            } else {
                Start-Sleep -Seconds $RefreshSeconds
            }
        }
    }
    '3' {
        Set-FreezeMarker -BoardPath $boardPath
        Write-Host 'FREEZE marker added for immediate test mode.' -ForegroundColor Green
    }
    '4' {
        if ($Watch) {
            powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'monitor-orchestration.ps1') -Project $projectPath -Watch
        } else {
            powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'monitor-orchestration.ps1') -Project $projectPath
        }
    }
    default {
        Write-Host 'No action taken.' -ForegroundColor Yellow
    }
}
