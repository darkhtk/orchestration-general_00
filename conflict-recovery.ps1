param(
    [string]$Project
)

$ErrorActionPreference = 'Stop'

# Import common functions from manage-orchestration.ps1
. $PSScriptRoot\common-orchestration-functions.ps1

# 에이전트 충돌 감지 및 복구 설정
$CONFLICT_CHECK_INTERVAL = 30  # 30초마다 충돌 검사
$MAX_RECOVERY_ATTEMPTS = 3     # 최대 복구 시도 횟수
$RECOVERY_COOLDOWN = 60        # 복구 시도 후 대기 시간 (초)

# 충돌 타입 정의
$CONFLICT_TYPES = @{
    FILE_LOCK = "FILE_LOCK"           # 파일 잠금 충돌
    SESSION_OVERLAP = "SESSION_OVERLAP" # 세션 중복
    TASK_COLLISION = "TASK_COLLISION"  # 작업 충돌
    RESOURCE_DEADLOCK = "RESOURCE_DEADLOCK" # 리소스 교착상태
}

function Write-ConflictLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$ConflictType = ""
    )

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $logEntry = "[$timestamp] [$Level] $(if($ConflictType) {"[$ConflictType] "})$Message"

    Write-Host $logEntry -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )

    # 로그 파일에 기록
    $logPath = Join-Path $projectPath 'orchestration\logs\CONFLICT_RECOVERY.md'
    if (-not (Test-Path -LiteralPath (Split-Path $logPath))) {
        New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $logPath)) {
        Set-Content -LiteralPath $logPath -Value "# 충돌 복구 로그`n`n> 생성됨: $(Get-Date)`n" -Encoding UTF8
    }

    Add-Content -LiteralPath $logPath -Value "`n$logEntry" -Encoding UTF8
}

function Get-SessionInfo {
    param([string]$ProjectDir)

    $sessionPath = Join-Path $ProjectDir 'orchestration\logs\.session.json'
    if (-not (Test-Path -LiteralPath $sessionPath)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
    } catch {
        Write-ConflictLog "세션 정보 파싱 실패: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Test-FileLocks {
    param([string]$ProjectDir)

    $boardPath = Join-Path $ProjectDir 'orchestration\BOARD.md'
    $sessionPath = Join-Path $ProjectDir 'orchestration\logs\.session.json'

    $conflicts = @()

    # BOARD.md 파일 잠금 확인
    try {
        $stream = [System.IO.File]::Open($boardPath, 'Open', 'Write')
        $stream.Close()
    } catch {
        $conflicts += @{
            Type = $CONFLICT_TYPES.FILE_LOCK
            File = $boardPath
            Message = "BOARD.md 파일이 잠겨 있습니다"
            Details = $_.Exception.Message
        }
    }

    # 세션 파일 잠금 확인
    try {
        $stream = [System.IO.File]::Open($sessionPath, 'Open', 'Write')
        $stream.Close()
    } catch {
        $conflicts += @{
            Type = $CONFLICT_TYPES.FILE_LOCK
            File = $sessionPath
            Message = "세션 파일이 잠겨 있습니다"
            Details = $_.Exception.Message
        }
    }

    return $conflicts
}

function Test-SessionOverlap {
    param([string]$ProjectDir)

    $sessionInfo = Get-SessionInfo -ProjectDir $ProjectDir
    if (-not $sessionInfo) {
        return @()
    }

    $conflicts = @()

    # 중복 에이전트 세션 확인
    $agentCounts = @{}
    foreach ($agent in $sessionInfo.agentSessions.PSObject.Properties) {
        if ($agent.Value) {
            $agentType = $agent.Name
            if ($agentCounts.ContainsKey($agentType)) {
                $agentCounts[$agentType]++
            } else {
                $agentCounts[$agentType] = 1
            }
        }
    }

    foreach ($agent in $agentCounts.Keys) {
        if ($agentCounts[$agent] -gt 1) {
            $conflicts += @{
                Type = $CONFLICT_TYPES.SESSION_OVERLAP
                Agent = $agent
                Count = $agentCounts[$agent]
                Message = "$agent 에이전트가 $($agentCounts[$agent])개의 세션을 실행 중입니다"
            }
        }
    }

    return $conflicts
}

function Test-TaskCollision {
    param([string]$ProjectDir)

    $sessionInfo = Get-SessionInfo -ProjectDir $ProjectDir
    if (-not $sessionInfo -or -not $sessionInfo.inProgressTasks) {
        return @()
    }

    $conflicts = @()
    $taskGroups = @{}

    # 작업을 파일별로 그룹화
    foreach ($task in $sessionInfo.inProgressTasks) {
        if ($task.files) {
            foreach ($file in $task.files) {
                if (-not $taskGroups.ContainsKey($file)) {
                    $taskGroups[$file] = @()
                }
                $taskGroups[$file] += $task
            }
        }
    }

    # 동일한 파일에 대한 여러 작업 확인
    foreach ($file in $taskGroups.Keys) {
        if ($taskGroups[$file].Count -gt 1) {
            $conflicts += @{
                Type = $CONFLICT_TYPES.TASK_COLLISION
                File = $file
                Tasks = $taskGroups[$file]
                Message = "$file 파일에 대해 $($taskGroups[$file].Count)개의 작업이 충돌합니다"
            }
        }
    }

    return $conflicts
}

function Resolve-FileLockConflict {
    param([hashtable]$Conflict)

    Write-ConflictLog "파일 잠금 충돌 해결 시도: $($Conflict.File)" "INFO" $Conflict.Type

    # 파일을 사용 중인 프로세스 찾기 (Windows)
    try {
        $processes = Get-Process | Where-Object {
            try {
                $_.Modules | Where-Object { $_.FileName -eq $Conflict.File }
            } catch {
                # Access denied 등의 경우 무시
            }
        }

        if ($processes) {
            Write-ConflictLog "파일 잠금 프로세스 발견: $($processes.Count)개" "WARN" $Conflict.Type

            foreach ($proc in $processes) {
                Write-ConflictLog "프로세스 종료 시도: $($proc.ProcessName) (PID: $($proc.Id))" "INFO" $Conflict.Type
                try {
                    $proc.Kill()
                    Start-Sleep -Seconds 2
                    Write-ConflictLog "프로세스 종료 완료: $($proc.ProcessName)" "SUCCESS" $Conflict.Type
                } catch {
                    Write-ConflictLog "프로세스 종료 실패: $($proc.ProcessName) - $($_.Exception.Message)" "ERROR" $Conflict.Type
                }
            }
        }

        # 파일 잠금 재확인
        $stream = [System.IO.File]::Open($Conflict.File, 'Open', 'Write')
        $stream.Close()
        Write-ConflictLog "파일 잠금 해결 성공: $($Conflict.File)" "SUCCESS" $Conflict.Type
        return $true

    } catch {
        Write-ConflictLog "파일 잠금 해결 실패: $($Conflict.File) - $($_.Exception.Message)" "ERROR" $Conflict.Type
        return $false
    }
}

function Resolve-SessionOverlapConflict {
    param([hashtable]$Conflict, [string]$ProjectDir)

    Write-ConflictLog "세션 중복 충돌 해결 시도: $($Conflict.Agent)" "INFO" $Conflict.Type

    # 세션 정보 재설정
    $sessionPath = Join-Path $ProjectDir 'orchestration\logs\.session.json'
    $sessionInfo = Get-SessionInfo -ProjectDir $ProjectDir

    if ($sessionInfo) {
        # 중복 에이전트 세션 정리
        $sessionInfo.agentSessions.($Conflict.Agent) = $null

        try {
            $sessionInfo | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $sessionPath -Encoding UTF8
            Write-ConflictLog "세션 중복 해결 성공: $($Conflict.Agent)" "SUCCESS" $Conflict.Type
            return $true
        } catch {
            Write-ConflictLog "세션 중복 해결 실패: $($Conflict.Agent) - $($_.Exception.Message)" "ERROR" $Conflict.Type
            return $false
        }
    }

    return $false
}

function Resolve-TaskCollisionConflict {
    param([hashtable]$Conflict, [string]$ProjectDir)

    Write-ConflictLog "작업 충돌 해결 시도: $($Conflict.File)" "INFO" $Conflict.Type

    # 우선순위가 높은 작업 하나만 유지하고 나머지는 대기 상태로 변경
    $sessionPath = Join-Path $ProjectDir 'orchestration\logs\.session.json'
    $sessionInfo = Get-SessionInfo -ProjectDir $ProjectDir

    if ($sessionInfo -and $sessionInfo.inProgressTasks) {
        try {
            # 가장 오래된 작업을 우선으로 유지
            $primaryTask = $Conflict.Tasks | Sort-Object startedAt | Select-Object -First 1

            # 다른 작업들을 대기 상태로 변경
            foreach ($task in $Conflict.Tasks) {
                if ($task.id -ne $primaryTask.id) {
                    $task.status = "pending"
                    $task.conflictedWith = $primaryTask.id
                    Write-ConflictLog "작업 대기 상태로 변경: $($task.id)" "INFO" $Conflict.Type
                }
            }

            $sessionInfo | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $sessionPath -Encoding UTF8
            Write-ConflictLog "작업 충돌 해결 성공: $($Conflict.File)" "SUCCESS" $Conflict.Type
            return $true

        } catch {
            Write-ConflictLog "작업 충돌 해결 실패: $($Conflict.File) - $($_.Exception.Message)" "ERROR" $Conflict.Type
            return $false
        }
    }

    return $false
}

function Start-ConflictMonitoring {
    param([string]$ProjectPath)

    Write-ConflictLog "에이전트 충돌 모니터링 시작: $ProjectPath" "INFO"

    $recoveryAttempts = @{}

    while ($true) {
        try {
            # 각 타입별 충돌 검사
            $allConflicts = @()
            $allConflicts += Test-FileLocks -ProjectDir $ProjectPath
            $allConflicts += Test-SessionOverlap -ProjectDir $ProjectPath
            $allConflicts += Test-TaskCollision -ProjectDir $ProjectPath

            if ($allConflicts.Count -gt 0) {
                Write-ConflictLog "충돌 감지됨: $($allConflicts.Count)개" "WARN"

                foreach ($conflict in $allConflicts) {
                    $conflictKey = "$($conflict.Type)_$($conflict.File ?? $conflict.Agent ?? 'unknown')"

                    # 복구 시도 횟수 확인
                    if (-not $recoveryAttempts.ContainsKey($conflictKey)) {
                        $recoveryAttempts[$conflictKey] = 0
                    }

                    if ($recoveryAttempts[$conflictKey] -lt $MAX_RECOVERY_ATTEMPTS) {
                        $recoveryAttempts[$conflictKey]++

                        Write-ConflictLog "$($conflict.Message) (시도 $($recoveryAttempts[$conflictKey])/$MAX_RECOVERY_ATTEMPTS)" "WARN" $conflict.Type

                        # 충돌 타입별 해결 시도
                        $resolved = switch ($conflict.Type) {
                            $CONFLICT_TYPES.FILE_LOCK {
                                Resolve-FileLockConflict -Conflict $conflict
                            }
                            $CONFLICT_TYPES.SESSION_OVERLAP {
                                Resolve-SessionOverlapConflict -Conflict $conflict -ProjectDir $ProjectPath
                            }
                            $CONFLICT_TYPES.TASK_COLLISION {
                                Resolve-TaskCollisionConflict -Conflict $conflict -ProjectDir $ProjectPath
                            }
                            default {
                                Write-ConflictLog "알 수 없는 충돌 타입: $($conflict.Type)" "ERROR"
                                $false
                            }
                        }

                        if ($resolved) {
                            $recoveryAttempts.Remove($conflictKey)
                        } else {
                            Start-Sleep -Seconds $RECOVERY_COOLDOWN
                        }
                    } else {
                        Write-ConflictLog "최대 복구 시도 횟수 초과: $conflictKey" "ERROR" $conflict.Type
                    }
                }
            }

            Start-Sleep -Seconds $CONFLICT_CHECK_INTERVAL

        } catch {
            Write-ConflictLog "모니터링 오류: $($_.Exception.Message)" "ERROR"
            Start-Sleep -Seconds $CONFLICT_CHECK_INTERVAL
        }
    }
}

# 메인 실행
if (-not $Project) {
    # Import common functions for folder picker
    $projectPath = Resolve-ProjectPath -ProvidedProject $Project
} else {
    $projectPath = (Resolve-Path -LiteralPath $Project).Path
}

if (-not $projectPath) {
    Write-Host '프로젝트 경로를 선택하지 않았습니다.' -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 에이전트 충돌 자동 복구 시스템" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("프로젝트: {0}" -f $projectPath)
Write-Host ("검사 간격: {0}초" -f $CONFLICT_CHECK_INTERVAL)
Write-Host ("최대 복구 시도: {0}회" -f $MAX_RECOVERY_ATTEMPTS)
Write-Host ""

Start-ConflictMonitoring -ProjectPath $projectPath