# Common Orchestration Functions
# 모든 PowerShell 스크립트에서 공통으로 사용되는 함수들

function Resolve-ProjectPath {
    <#
    .SYNOPSIS
    프로젝트 경로를 해결합니다.

    .DESCRIPTION
    제공된 프로젝트 경로가 있으면 그것을 사용하고, 없으면 폴더 선택 다이얼로그를 표시합니다.

    .PARAMETER ProvidedProject
    제공된 프로젝트 경로 (선택사항)

    .RETURNS
    해결된 프로젝트 경로 또는 $null (취소된 경우)
    #>
    param([string]$ProvidedProject)

    if ($ProvidedProject) {
        if (Test-Path -LiteralPath $ProvidedProject) {
            return (Resolve-Path -LiteralPath $ProvidedProject).Path
        } else {
            Write-Host "경로를 찾을 수 없습니다: $ProvidedProject" -ForegroundColor Red
            return $null
        }
    }

    try {
        $picker = Join-Path $PSScriptRoot 'pick-folder.ps1'
        if (Test-Path -LiteralPath $picker) {
            $selected = & powershell -NoProfile -ExecutionPolicy Bypass -File $picker
            if (-not $selected -or $selected -eq 'CANCELLED') {
                return $null
            }
            return (Resolve-Path -LiteralPath $selected).Path
        } else {
            Write-Host "폴더 선택 스크립트를 찾을 수 없습니다: $picker" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "프로젝트 경로 해결 중 오류 발생: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Test-OrchestrationStructure {
    <#
    .SYNOPSIS
    오케스트레이션 디렉토리 구조가 올바른지 확인합니다.

    .PARAMETER ProjectDir
    프로젝트 디렉토리 경로

    .RETURNS
    구조가 올바르면 $true, 아니면 $false
    #>
    param([string]$ProjectDir)

    if (-not (Test-Path -LiteralPath $ProjectDir)) {
        return $false
    }

    $orchestrationDir = Join-Path $ProjectDir 'orchestration'
    if (-not (Test-Path -LiteralPath $orchestrationDir)) {
        return $false
    }

    $boardPath = Join-Path $orchestrationDir 'BOARD.md'
    return Test-Path -LiteralPath $boardPath
}

function Get-SafePath {
    <#
    .SYNOPSIS
    안전한 파일 경로를 반환합니다 (경로가 존재하지 않아도 안전).

    .PARAMETER Path
    확인할 경로

    .RETURNS
    경로가 유효하면 해당 경로, 아니면 $null
    #>
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        return [System.IO.Path]::GetFullPath($Path)
    } catch {
        return $null
    }
}

function Write-LogMessage {
    <#
    .SYNOPSIS
    로그 메시지를 일관된 형식으로 출력합니다.

    .PARAMETER Message
    출력할 메시지

    .PARAMETER Type
    메시지 타입 (INFO, WARNING, ERROR, SUCCESS)
    #>
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Type = 'INFO'
    )

    $color = switch ($Type) {
        'INFO' { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR' { 'Red' }
        'SUCCESS' { 'Green' }
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

function Backup-File {
    <#
    .SYNOPSIS
    파일의 백업 복사본을 생성합니다.

    .PARAMETER FilePath
    백업할 파일 경로

    .RETURNS
    백업 파일 경로 또는 $null (실패 시)
    #>
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $null
    }

    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $directory = Split-Path $FilePath
        $filename = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $extension = [System.IO.Path]::GetExtension($FilePath)

        $backupPath = Join-Path $directory "${filename}_backup_${timestamp}${extension}"
        Copy-Item -LiteralPath $FilePath -Destination $backupPath -Force

        return $backupPath
    } catch {
        Write-LogMessage "파일 백업 실패: $($_.Exception.Message)" -Type ERROR
        return $null
    }
}

function Test-GitRepository {
    <#
    .SYNOPSIS
    디렉토리가 Git 리포지토리인지 확인합니다.

    .PARAMETER Path
    확인할 디렉토리 경로

    .RETURNS
    Git 리포지토리이면 $true, 아니면 $false
    #>
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $gitDir = Join-Path $Path '.git'
    return Test-Path -LiteralPath $gitDir
}

function Get-FileAge {
    <#
    .SYNOPSIS
    파일의 수정된 지 경과 시간을 분 단위로 반환합니다.

    .PARAMETER FilePath
    파일 경로

    .RETURNS
    경과 시간 (분) 또는 $null (파일이 없는 경우)
    #>
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $null
    }

    try {
        $file = Get-Item -LiteralPath $FilePath
        $now = Get-Date
        return [math]::Round(($now - $file.LastWriteTime).TotalMinutes, 1)
    } catch {
        return $null
    }
}

# PowerShell 모듈 호환성을 위한 Export
Export-ModuleMember -Function @(
    'Resolve-ProjectPath',
    'Test-OrchestrationStructure',
    'Get-SafePath',
    'Write-LogMessage',
    'Backup-File',
    'Test-GitRepository',
    'Get-FileAge'
)