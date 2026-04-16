param(
    [string]$Project
)

$ErrorActionPreference = 'Stop'

# Import common functions
. $PSScriptRoot\common-orchestration-functions.ps1

function Enable-ConflictRecovery {
    param([string]$BoardPath)

    $lines = Get-BoardLines -BoardPath $BoardPath
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    Insert-StateBlock -Lines $lines -State 'CONFLICT_RECOVERY' -Body @(
        '> 에이전트 충돌 자동 복구 활성화',
        "> 시작 시간: $timestamp",
        '> 상태: 모니터링 중',
        '> 기능: 파일 잠금, 세션 중복, 작업 충돌 자동 해결'
    )

    Save-BoardLines -BoardPath $BoardPath -Lines $lines
    Write-Host '에이전트 충돌 자동 복구가 활성화되었습니다.' -ForegroundColor Green
}

function Disable-ConflictRecovery {
    param([string]$BoardPath)

    $lines = Get-BoardLines -BoardPath $BoardPath
    Remove-StateBlock -Lines $lines -State 'CONFLICT_RECOVERY'
    Save-BoardLines -BoardPath $BoardPath -Lines $lines
    Write-Host '에이전트 충돌 자동 복구가 비활성화되었습니다.' -ForegroundColor Yellow
}

function Start-ConflictRecoveryService {
    param([string]$ProjectPath)

    Write-Host "에이전트 충돌 자동 복구 서비스를 시작합니다..." -ForegroundColor Cyan

    # 백그라운드에서 충돌 복구 스크립트 실행
    $scriptPath = Join-Path $PSScriptRoot 'conflict-recovery.ps1'
    $job = Start-Job -ScriptBlock {
        param($ScriptPath, $ProjectPath)
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Project $ProjectPath
    } -ArgumentList $scriptPath, $ProjectPath

    Write-Host "충돌 복구 서비스가 백그라운드에서 시작되었습니다. (Job ID: $($job.Id))" -ForegroundColor Green
    return $job
}

function Stop-ConflictRecoveryService {
    # 실행 중인 충돌 복구 작업 찾기 및 종료
    $jobs = Get-Job | Where-Object { $_.Command -like "*conflict-recovery*" -and $_.State -eq "Running" }

    if ($jobs) {
        foreach ($job in $jobs) {
            Stop-Job -Job $job
            Remove-Job -Job $job
            Write-Host "충돌 복구 서비스를 종료했습니다. (Job ID: $($job.Id))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "실행 중인 충돌 복구 서비스가 없습니다." -ForegroundColor Gray
    }
}

function Show-ConflictRecoveryStatus {
    param([string]$ProjectPath)

    # 실행 중인 작업 확인
    $jobs = Get-Job | Where-Object { $_.Command -like "*conflict-recovery*" -and $_.State -eq "Running" }

    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " 에이전트 충돌 복구 상태" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan

    if ($jobs) {
        Write-Host "실행 중인 서비스: $($jobs.Count)개" -ForegroundColor Green
        foreach ($job in $jobs) {
            Write-Host ("  - Job ID: {0}, 시작 시간: {1}" -f $job.Id, $job.PSBeginTime) -ForegroundColor White
        }
    } else {
        Write-Host "실행 중인 서비스: 없음" -ForegroundColor Gray
    }

    # 로그 파일 확인
    $logPath = Join-Path $ProjectPath 'orchestration\logs\CONFLICT_RECOVERY.md'
    if (Test-Path -LiteralPath $logPath) {
        $logContent = Get-Content -LiteralPath $logPath -Tail 10
        Write-Host ""
        Write-Host "최근 로그 (마지막 10줄):" -ForegroundColor Cyan
        foreach ($line in $logContent) {
            if ($line -match '\[ERROR\]') {
                Write-Host $line -ForegroundColor Red
            } elseif ($line -match '\[WARN\]') {
                Write-Host $line -ForegroundColor Yellow
            } elseif ($line -match '\[SUCCESS\]') {
                Write-Host $line -ForegroundColor Green
            } else {
                Write-Host $line -ForegroundColor White
            }
        }
    } else {
        Write-Host ""
        Write-Host "로그 파일이 없습니다." -ForegroundColor Gray
    }
}

# 메인 실행
$projectPath = Resolve-ProjectPath -ProvidedProject $Project
if (-not $projectPath) {
    Write-Host '프로젝트를 선택하지 않았습니다.' -ForegroundColor Yellow
    exit 0
}

$boardPath = Get-BoardPath -ProjectDir $projectPath
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 에이전트 충돌 복구 관리자" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("프로젝트: {0}" -f $projectPath)
Show-Summary -BoardPath $boardPath

Write-Host "1) 충돌 복구 활성화"
Write-Host "2) 충돌 복구 비활성화"
Write-Host "3) 복구 서비스 시작"
Write-Host "4) 복구 서비스 종료"
Write-Host "5) 복구 상태 확인"
Write-Host "6) 충돌 로그 보기"
Write-Host ""
$choice = Read-Host "선택 (1-6)"

switch ($choice) {
    '1' {
        Enable-ConflictRecovery -BoardPath $boardPath
    }
    '2' {
        Disable-ConflictRecovery -BoardPath $boardPath
    }
    '3' {
        Enable-ConflictRecovery -BoardPath $boardPath
        Start-ConflictRecoveryService -ProjectPath $projectPath
    }
    '4' {
        Stop-ConflictRecoveryService
        Disable-ConflictRecovery -BoardPath $boardPath
    }
    '5' {
        Show-ConflictRecoveryStatus -ProjectPath $projectPath
    }
    '6' {
        $logPath = Join-Path $projectPath 'orchestration\logs\CONFLICT_RECOVERY.md'
        if (Test-Path -LiteralPath $logPath) {
            Get-Content -LiteralPath $logPath | Write-Host
        } else {
            Write-Host "충돌 로그 파일이 없습니다." -ForegroundColor Gray
        }
    }
    default {
        Write-Host '작업을 수행하지 않았습니다.' -ForegroundColor Yellow
    }
}