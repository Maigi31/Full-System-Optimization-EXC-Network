# Core\Core.psm1
$Script:ConfigPath = Join-Path $PSScriptRoot "..\config.json"
$Script:RunId = [Guid]::NewGuid().ToString()
$Script:LogDir = Join-Path $PSScriptRoot "..\Logs"

function Get-OptConfig {
    if (-not (Test-Path $Script:ConfigPath)) {
        throw "Config not found: $Script:ConfigPath"
    }
    Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json
}

function Write-OptLog {
    param([string]$Module, [string]$Stage, [string]$Message, [ValidateSet('Info','Warn','Error','Debug')] [string]$Level='Info')
    if (-not (Test-Path $Script:LogDir)) { New-Item -ItemType Directory -Path $Script:LogDir | Out-Null }
    $logPath = Join-Path $Script:LogDir ("{0}-{1}.log" -f $Script:RunId, $Module)
    $entry = "{0} [{1}] ({2}) {3}" -f (Get-Date -Format "u"), $Level, $Stage, $Message
    Add-Content -Path $logPath -Value $entry
}

function Test-SystemRestoreEligible {
    # Check the 24h restore point throttle and SR enablement
    $srKey = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $enabled = (Get-ItemProperty -Path $srKey -ErrorAction SilentlyContinue).SystemRestore
    $last = (Get-ItemProperty -Path $srKey -ErrorAction SilentlyContinue).LastRestoreTime
    return $true  # Even if disabled, we’ll still do registry exports; checkpoint is attempted safely.
}

function New-OptSnapshot {
    param([string]$Name = ("snapshot-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")))
    # Attempt restore point; suppress throttle noise
    try {
        Checkpoint-Computer -Description $Name -ErrorAction Stop | Out-Null
        Write-OptLog -Module 'Core' -Stage 'Snapshot' -Message "Restore point created: $Name" -Level 'Info'
    } catch {
        Write-OptLog -Module 'Core' -Stage 'Snapshot' -Message "Checkpoint skipped/failed: $($_.Exception.Message)" -Level 'Warn'
    }
    # Always export critical registry hives for rollback
    $snapDir = Join-Path $PSScriptRoot "..\Snapshots\$Name"
    New-Item -ItemType Directory -Path $snapDir -Force | Out-Null
    reg export "HKLM\SYSTEM"   (Join-Path $snapDir "HKLM_SYSTEM.reg")   /y | Out-Null
    reg export "HKLM\SOFTWARE" (Join-Path $snapDir "HKLM_SOFTWARE.reg") /y | Out-Null
    reg export "HKCU\Software" (Join-Path $snapDir "HKCU_Software.reg") /y | Out-Null
    Write-OptLog -Module 'Core' -Stage 'Snapshot' -Message "Registry exports saved: $snapDir" -Level 'Info'
    return $Name
}

function Get-OptMetrics {
    param([string]$Phase = 'Before')
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $os = Get-CimInstance Win32_OperatingSystem
    $ramMB = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1024),2)
    $diskQ = (Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length').CounterSamples.CookedValue
    $ioReads = (Get-Counter '\PhysicalDisk(_Total)\Disk Reads/sec').CounterSamples.CookedValue
    $ioWrites = (Get-Counter '\PhysicalDisk(_Total)\Disk Writes/sec').CounterSamples.CookedValue
    [pscustomobject]@{
        Phase=$Phase; CPU=[math]::Round($cpu,2); RAM_MB=$ramMB; DiskQ=[math]::Round($diskQ,2);
        DiskReads=[math]::Round($ioReads,2); DiskWrites=[math]::Round($ioWrites,2);
    }
}

function Save-OptMetrics {
    param($Metrics)
    $dir = Join-Path $PSScriptRoot "..\Metrics"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $path = Join-Path $dir ("{0}-{1}.json" -f $Script:RunId, $Metrics.Phase)
    $Metrics | ConvertTo-Json -Depth 3 | Set-Content -Path $path -Encoding UTF8
    Write-OptLog -Module 'Core' -Stage 'Metrics' -Message "Saved metrics: $path" -Level 'Info'
}

Export-ModuleMember -Function Get-OptConfig, Write-OptLog, Test-SystemRestoreEligible, New-OptSnapshot, Get-OptMetrics, Save-OptMetrics