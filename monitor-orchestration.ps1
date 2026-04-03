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

function Get-SectionRowCount {
    param(
        [string[]]$Lines,
        [string]$Keyword
    )

    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^## ' -and $Lines[$i] -match [regex]::Escape($Keyword)) {
            $start = $i + 1
            break
        }
    }

    if ($start -lt 0) {
        return 0
    }

    $count = 0
    for ($j = $start; $j -lt $Lines.Count; $j++) {
        $line = $Lines[$j]
        if ($line -match '^## ') {
            break
        }
        if ($line -notmatch '^\|') {
            continue
        }
        if ($line -match '^\|\s*-') {
            continue
        }
        if ($line -match '^\|\s*#\s*\|') {
            continue
        }
        if ($line -match '^\|\s*Task\s*\|') {
            continue
        }
        if ($line -match '^\|\s*$') {
            continue
        }
        $count++
    }

    return $count
}

function Get-LogHealth {
    param(
        [string]$Path,
        [datetime]$Now
    )

    if (-not (Test-Path -LiteralPath $Path)) {
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

    $file = Get-ChildItem -LiteralPath $ReviewsDir -File -Filter '*.md' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $file) {
        return $null
    }

    $content = Get-Content -LiteralPath $file.FullName -Raw
    $result = 'UNKNOWN'
    if ($content -match 'FINAL[^\r\n]*APPROVE|APPROVE') {
        $result = 'APPROVE'
    }
    if ($content -match 'NEEDS_WORK') {
        $result = 'NEEDS_WORK'
    }
    if ($content -match 'REJECT') {
        $result = 'REJECT'
    }

    return [pscustomobject]@{
        Name = $file.Name
        LastWriteTime = $file.LastWriteTime
        Result = $result
    }
}

function Get-ReserveTaskCount {
    param([string]$BacklogPath)

    if (-not (Test-Path -LiteralPath $BacklogPath)) {
        return 0
    }

    $matches = Select-String -Path $BacklogPath -Pattern '^### ' -AllMatches
    return @($matches).Count
}

function Get-DiscussionCount {
    param([string]$DiscussionsDir)

    if (-not (Test-Path -LiteralPath $DiscussionsDir)) {
        return 0
    }

    return @(Get-ChildItem -LiteralPath $DiscussionsDir -File -Filter '*.md').Count
}

function Get-GitSnapshot {
    param([string]$ProjectDir)

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectDir '.git'))) {
        return [pscustomobject]@{
            Branch = 'n/a'
            DirtyCount = 0
            Commits = @()
        }
    }

    $branch = (git -C $ProjectDir branch --show-current 2>$null)
    if (-not $branch) {
        $branch = 'detached'
    }

    $statusLines = @(git -C $ProjectDir status --short 2>$null)
    $commits = @(git -C $ProjectDir log --oneline -5 2>$null)

    return [pscustomobject]@{
        Branch = $branch.Trim()
        DirtyCount = $statusLines.Count
        Commits = $commits
    }
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

    $items = New-Object System.Collections.Generic.List[string]

    if ($Freeze) {
        $items.Add('FREEZE is active. Unfreeze BOARD.md before expecting more progress.')
        return $items
    }

    if ($Health.Values.Where({ $_.Status -eq 'stale' }).Count -gt 0) {
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

function Show-Dashboard {
    param([string]$ProjectDir)

    $orchDir = Join-Path $ProjectDir 'orchestration'
    $boardPath = Join-Path $orchDir 'BOARD.md'
    $backlogPath = Join-Path $orchDir 'BACKLOG_RESERVE.md'
    $logsDir = Join-Path $orchDir 'logs'
    $reviewsDir = Join-Path $orchDir 'reviews'
    $discussionsDir = Join-Path $orchDir 'discussions'

    if (-not (Test-Path -LiteralPath $boardPath)) {
        throw "BOARD.md not found under $orchDir"
    }

    $now = Get-Date
    $boardLines = Get-Content -LiteralPath $boardPath
    $boardText = $boardLines -join "`n"
    $freeze = $boardText -match 'FREEZE'

    $board = @{
        Rejected   = Get-SectionRowCount -Lines $boardLines -Keyword 'Rejected'
        InProgress = Get-SectionRowCount -Lines $boardLines -Keyword 'In Progress'
        InReview   = Get-SectionRowCount -Lines $boardLines -Keyword 'In Review'
        Done       = Get-SectionRowCount -Lines $boardLines -Keyword 'Done'
        Backlog    = Get-SectionRowCount -Lines $boardLines -Keyword 'Backlog'
    }

    $health = @{
        SUPERVISOR  = Get-LogHealth -Path (Join-Path $logsDir 'SUPERVISOR.md') -Now $now
        DEVELOPER   = Get-LogHealth -Path (Join-Path $logsDir 'DEVELOPER.md') -Now $now
        CLIENT      = Get-LogHealth -Path (Join-Path $logsDir 'CLIENT.md') -Now $now
        COORDINATOR = Get-LogHealth -Path (Join-Path $logsDir 'COORDINATOR.md') -Now $now
    }

    $latestReview = Get-LatestReviewInfo -ReviewsDir $reviewsDir
    $reserveCount = Get-ReserveTaskCount -BacklogPath $backlogPath
    $discussionCount = Get-DiscussionCount -DiscussionsDir $discussionsDir
    $git = Get-GitSnapshot -ProjectDir $ProjectDir
    $recommendations = Get-Recommendations -Board $board -Health $health -ReserveCount $reserveCount -DiscussionCount $discussionCount -Freeze:$freeze -LatestReview $latestReview

    Clear-Host
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host ' Orchestration Monitor' -ForegroundColor Cyan
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
