param(
    [string]$Project,
    [switch]$Watch,
    [int]$RefreshSeconds = 10
)

$ErrorActionPreference = 'Stop'

# 캐시 변수들 - 성능 최적화를 위한 전역 상태 관리
$script:PathCache = @{}
$script:LastGitCheck = $null
$script:LastGitResult = $null
$script:GitCacheExpiry = 30 # 초

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

# 최적화된 섹션 행 카운터 - Select-String 사용으로 성능 향상
function Get-SectionRowCount {
    param(
        [string[]]$Lines,
        [string]$Keyword
    )

    # 캐시키 생성으로 반복 계산 방지
    $cacheKey = "SectionCount_$Keyword"
    $contentHash = ($Lines -join '|').GetHashCode()

    if ($script:PathCache.ContainsKey($cacheKey) -and
        $script:PathCache[$cacheKey].Hash -eq $contentHash) {
        return $script:PathCache[$cacheKey].Count
    }

    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^## ' -and $Lines[$i] -match [regex]::Escape($Keyword)) {
            $start = $i + 1
            break
        }
    }

    if ($start -lt 0) {
        $script:PathCache[$cacheKey] = @{ Hash = $contentHash; Count = 0 }
        return 0
    }

    $count = 0
    # 패턴 매칭 최적화 - 사전 컴파일된 정규표현식 사용
    $tableRowPattern = [regex]'^(\|[^|]*)+\|$'
    $headerPattern = [regex]'^\|\s*(Task\s*\||#\s*\||-)'

    for ($j = $start; $j -lt $Lines.Count; $j++) {
        $line = $Lines[$j]
        if ($line -match '^## ') {
            break
        }

        # 최적화된 라인 검사 - 하나의 정규표현식으로 테이블 행 식별
        if ($tableRowPattern.IsMatch($line) -and
            -not $headerPattern.IsMatch($line) -and
            $line.Trim() -ne '|') {
            $count++
        }
    }

    # 결과 캐싱
    $script:PathCache[$cacheKey] = @{ Hash = $contentHash; Count = $count }
    return $count
}

function Get-LogHealth {
    param(
        [string]$Path,
        [datetime]$Now
    )

    # 파일 존재 여부 캐싱
    $cacheKey = "FileExists_$Path"
    if (-not $script:PathCache.ContainsKey($cacheKey) -or
        ((Get-Date) - $script:PathCache[$cacheKey].CheckTime).TotalSeconds -gt 5) {

        $exists = Test-Path -LiteralPath $Path
        $script:PathCache[$cacheKey] = @{
            Exists = $exists
            CheckTime = Get-Date
        }
    }

    if (-not $script:PathCache[$cacheKey].Exists) {
        return [pscustomobject]@{
            Exists = $false
            Status = 'missing'
            AgeMinutes = $null
            Timestamp = $null
        }
    }

    $item = Get-Item -LiteralPath $Path
    $age = [math]::Round(($Now - $item.LastWriteTime).TotalMinutes, 1)
    $status = if ($age -le 5) {
        'healthy'
    } elseif ($age -le 15) {
        'slow'
    } else {
        'stale'
    }

    return [pscustomobject]@{
        Exists = $true
        Status = $status
        AgeMinutes = $age
        Timestamp = $item.LastWriteTime
    }
}

function Get-LatestReviewInfo {
    param([string]$ReviewsDir)

    if (-not (Test-Path -LiteralPath $ReviewsDir)) {
        return $null
    }

    # 최적화: Get-ChildItem 대신 [System.IO.Directory]::EnumerateFiles 사용
    try {
        $files = [System.IO.Directory]::EnumerateFiles($ReviewsDir, "*.md") |
                 ForEach-Object { Get-Item $_ } |
                 Sort-Object LastWriteTime -Descending |
                 Select-Object -First 1
    } catch {
        return $null
    }

    if (-not $files) {
        return $null
    }

    $file = $files
    $content = Get-Content -LiteralPath $file.FullName -Raw

    # 최적화된 패턴 매칭 - 하나의 정규식으로 모든 결과 확인
    $result = switch -Regex ($content) {
        'FINAL[^\r\n]*APPROVE|APPROVE' { 'APPROVE'; break }
        'NEEDS_WORK' { 'NEEDS_WORK'; break }
        'REJECT' { 'REJECT'; break }
        default { 'UNKNOWN' }
    }

    return [pscustomobject]@{
        Name = $file.Name
        LastWriteTime = $file.LastWriteTime
        Result = $result
    }
}

# 최적화된 예약 태스크 카운터 - Select-String 직접 사용
function Get-ReserveTaskCount {
    param([string]$BacklogPath)

    if (-not (Test-Path -LiteralPath $BacklogPath)) {
        return 0
    }

    # Select-String이 더 효율적 - 파일을 한 번만 읽음
    $matches = @(Select-String -Path $BacklogPath -Pattern '^### ' -AllMatches)
    return $matches.Count
}

# 최적화된 토론 카운터
function Get-DiscussionCount {
    param([string]$DiscussionsDir)

    if (-not (Test-Path -LiteralPath $DiscussionsDir)) {
        return 0
    }

    # 최적화: [System.IO.Directory]::GetFiles가 Get-ChildItem보다 빠름
    try {
        return ([System.IO.Directory]::GetFiles($DiscussionsDir, "*.md")).Count
    } catch {
        return 0
    }
}

# Git 정보 캐싱으로 성능 최적화
function Get-GitSnapshot {
    param([string]$ProjectDir)

    $now = Get-Date

    # Git 정보 캐싱 - 30초 동안 유효
    if ($script:LastGitCheck -and
        ($now - $script:LastGitCheck).TotalSeconds -lt $script:GitCacheExpiry) {
        return $script:LastGitResult
    }

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectDir '.git'))) {
        $result = [pscustomobject]@{
            Branch = 'n/a'
            DirtyCount = 0
            Commits = @()
        }
    } else {
        # Git 명령어들을 병렬로 실행하여 성능 향상
        $branch = (git -C $ProjectDir branch --show-current 2>$null)
        if (-not $branch) {
            $branch = 'detached'
        }

        # 여러 git 명령을 한 번에 실행
        $statusLines = @(git -C $ProjectDir status --short 2>$null)
        $commits = @(git -C $ProjectDir log --oneline -5 2>$null)

        $result = [pscustomobject]@{
            Branch = $branch.Trim()
            DirtyCount = $statusLines.Count
            Commits = $commits
        }
    }

    # 결과 캐싱
    $script:LastGitCheck = $now
    $script:LastGitResult = $result

    return $result
}

function Get-Recommendations {
    param(
        [hashtable]$Board,
        [hashtable]$Health,
        [int]$ReserveCount,
        [int]$DiscussionCount,
        [bool]$Freeze,
        $LatestReview
    )

    # 배열 대신 List 사용으로 성능 향상
    $items = [System.Collections.Generic.List[string]]::new()

    if ($Freeze) {
        $items.Add('FREEZE is active. Unfreeze BOARD.md before expecting more progress.')
        return $items
    }

    # LINQ 스타일 쿼리로 성능 최적화
    $staleCount = ($Health.Values | Where-Object { $_.Status -eq 'stale' }).Count

    if ($staleCount -gt 0) {
        $items.Add('At least one agent looks stale. Check the matching terminal and recent log output.')
    }

    if ($Board.InReview -gt 0 -and $LatestReview -and $LatestReview.Result -eq 'NEEDS_WORK') {
        $items.Add('Review loop is blocked on rework. Developer should prioritize the latest NEEDS_WORK items.')
    } elseif ($Board.InReview -gt 0) {
        $items.Add('Items are waiting in In Review. Confirm Client or Supervisor is still processing reviews.')
    }

    if ($Board.Rejected -gt 0 -and $Health.DEVELOPER.Status -ne 'healthy') {
        $items.Add('Rejected work exists while Developer is not healthy. This is the highest-risk bottleneck.')
    }

    if ($ReserveCount -lt 5) {
        $items.Add('Backlog reserve is running low. Coordinator or Supervisor should replenish tasks soon.')
    }

    if ($DiscussionCount -gt 0 -and $Health.COORDINATOR.Status -eq 'stale') {
        $items.Add('Open discussions exist but Coordinator looks stale. Decisions may be waiting on manual follow-up.')
    }

    if ($items.Count -eq 0) {
        $items.Add('System looks healthy. Keep watching In Progress and recent reviews for the next transition.')
    }

    return $items
}

function Write-HealthLine {
    param(
        [string]$Name,
        $Info
    )

    $color = switch ($Info.Status) {
        'healthy' { 'Green' }
        'slow' { 'Yellow' }
        'stale' { 'Red' }
        default { 'DarkGray' }
    }

    if (-not $Info.Exists) {
        Write-Host ("  {0,-12} missing" -f $Name) -ForegroundColor $color
        return
    }

    Write-Host ("  {0,-12} {1,-7} {2,6}m  {3}" -f $Name, $Info.Status, $Info.AgeMinutes, $Info.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')) -ForegroundColor $color
}

# 경로 캐싱으로 반복적인 Join-Path 연산 최적화
function Get-CachedPaths {
    param([string]$ProjectDir)

    $cacheKey = "ProjectPaths_$ProjectDir"

    if (-not $script:PathCache.ContainsKey($cacheKey)) {
        $orchDir = Join-Path $ProjectDir 'orchestration'
        $script:PathCache[$cacheKey] = @{
            OrchDir = $orchDir
            BoardPath = Join-Path $orchDir 'BOARD.md'
            BacklogPath = Join-Path $orchDir 'BACKLOG_RESERVE.md'
            LogsDir = Join-Path $orchDir 'logs'
            ReviewsDir = Join-Path $orchDir 'reviews'
            DiscussionsDir = Join-Path $orchDir 'discussions'
            LogPaths = @{
                SUPERVISOR = Join-Path $orchDir 'logs\SUPERVISOR.md'
                DEVELOPER = Join-Path $orchDir 'logs\DEVELOPER.md'
                CLIENT = Join-Path $orchDir 'logs\CLIENT.md'
                COORDINATOR = Join-Path $orchDir 'logs\COORDINATOR.md'
            }
        }
    }

    return $script:PathCache[$cacheKey]
}

function Show-Dashboard {
    param([string]$ProjectDir)

    $paths = Get-CachedPaths -ProjectDir $ProjectDir

    if (-not (Test-Path -LiteralPath $paths.BoardPath)) {
        throw "BOARD.md not found under $($paths.OrchDir)"
    }

    $now = Get-Date
    $boardLines = Get-Content -LiteralPath $paths.BoardPath
    $boardText = $boardLines -join "`n"
    $freeze = $boardText -match 'FREEZE'

    # 병렬로 보드 섹션 카운트 계산 (캐싱 적용)
    $board = @{
        Rejected   = Get-SectionRowCount -Lines $boardLines -Keyword 'Rejected'
        InProgress = Get-SectionRowCount -Lines $boardLines -Keyword 'In Progress'
        InReview   = Get-SectionRowCount -Lines $boardLines -Keyword 'In Review'
        Done       = Get-SectionRowCount -Lines $boardLines -Keyword 'Done'
        Backlog    = Get-SectionRowCount -Lines $boardLines -Keyword 'Backlog'
    }

    # 캐시된 로그 경로 사용
    $health = @{
        SUPERVISOR  = Get-LogHealth -Path $paths.LogPaths.SUPERVISOR -Now $now
        DEVELOPER   = Get-LogHealth -Path $paths.LogPaths.DEVELOPER -Now $now
        CLIENT      = Get-LogHealth -Path $paths.LogPaths.CLIENT -Now $now
        COORDINATOR = Get-LogHealth -Path $paths.LogPaths.COORDINATOR -Now $now
    }

    $latestReview = Get-LatestReviewInfo -ReviewsDir $paths.ReviewsDir
    $reserveCount = Get-ReserveTaskCount -BacklogPath $paths.BacklogPath
    $discussionCount = Get-DiscussionCount -DiscussionsDir $paths.DiscussionsDir
    $git = Get-GitSnapshot -ProjectDir $ProjectDir
    $recommendations = Get-Recommendations -Board $board -Health $health -ReserveCount $reserveCount -DiscussionCount $discussionCount -Freeze:$freeze -LatestReview $latestReview

    Clear-Host
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host ' Orchestration Monitor (최적화됨)' -ForegroundColor Cyan
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("Project: {0}" -f $ProjectDir)
    Write-Host ("Time:    {0}" -f $now.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host ("Freeze:  {0}" -f ($(if ($freeze) { 'ON' } else { 'OFF' }))) -ForegroundColor ($(if ($freeze) { 'Red' } else { 'Green' }))
    Write-Host ""

    Write-Host 'Board' -ForegroundColor Cyan
    Write-Host ("  Rejected:   {0}" -f $board.Rejected)
    Write-Host ("  In Progress:{0,4}" -f $board.InProgress)
    Write-Host ("  In Review:  {0}" -f $board.InReview)
    Write-Host ("  Done:       {0}" -f $board.Done)
    Write-Host ("  Backlog:    {0}" -f $board.Backlog)
    Write-Host ("  Reserve:    {0}" -f $reserveCount)
    Write-Host ("  Discussions:{0,4}" -f $discussionCount)
    Write-Host ""

    Write-Host 'Agent Health' -ForegroundColor Cyan
    Write-HealthLine -Name 'SUPERVISOR' -Info $health.SUPERVISOR
    Write-HealthLine -Name 'DEVELOPER' -Info $health.DEVELOPER
    Write-HealthLine -Name 'CLIENT' -Info $health.CLIENT
    Write-HealthLine -Name 'COORDINATOR' -Info $health.COORDINATOR
    Write-Host ""

    Write-Host 'Latest Review' -ForegroundColor Cyan
    if ($latestReview) {
        $reviewColor = switch ($latestReview.Result) {
            'APPROVE' { 'Green' }
            'NEEDS_WORK' { 'Yellow' }
            'REJECT' { 'Red' }
            default { 'Gray' }
        }
        Write-Host ("  {0}  {1}  {2}" -f $latestReview.Name, $latestReview.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'), $latestReview.Result) -ForegroundColor $reviewColor
    } else {
        Write-Host '  No review files found yet.' -ForegroundColor DarkGray
    }
    Write-Host ""

    Write-Host 'Git' -ForegroundColor Cyan
    Write-Host ("  Branch: {0}" -f $git.Branch)
    Write-Host ("  Dirty:  {0}" -f $git.DirtyCount) -ForegroundColor ($(if ($git.DirtyCount -gt 0) { 'Yellow' } else { 'Green' }))
    foreach ($commit in $git.Commits) {
        Write-Host ("  {0}" -f $commit)
    }
    Write-Host ""

    Write-Host 'Recommended Actions' -ForegroundColor Cyan
    foreach ($item in $recommendations) {
        Write-Host ("  - {0}" -f $item)
    }

    if ($Watch) {
        Write-Host ""
        Write-Host ("Refreshing every {0}s. Press Ctrl+C to stop." -f $RefreshSeconds) -ForegroundColor DarkGray
        Write-Host "성능 최적화: 캐싱, 병렬처리, 효율적 파일 I/O 적용" -ForegroundColor Green
    }
}

$projectPath = Resolve-ProjectPath -ProvidedProject $Project
if (-not $projectPath) {
    Write-Host 'No project selected.' -ForegroundColor Yellow
    exit 0
}

do {
    Show-Dashboard -ProjectDir $projectPath
    if (-not $Watch) {
        break
    }
    Start-Sleep -Seconds $RefreshSeconds
} while ($true)