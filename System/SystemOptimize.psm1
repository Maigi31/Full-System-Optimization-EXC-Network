Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

function Invoke-SystemOptimization {
    $snap = New-OptSnapshot
    $before = Get-OptMetrics -Phase 'SystemBefore'; Save-OptMetrics $before

    # Cleanup
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-OptLog -Module 'System' -Stage 'Cleanup' -Message "Temp & recycle bin cleared" -Level 'Info'
    } catch { Write-OptLog -Module 'System' -Stage 'Cleanup' -Message $_.Exception.Message -Level 'Warn' }

    # Bloat removal (example patterns; extend via config as needed)
    try {
        Get-AppxPackage -AllUsers |
            Where-Object { $_.Name -like "*xbox*" -or $_.Name -like "*clipchamp*" -or $_.Name -like "*bing*" } |
            Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-OptLog -Module 'System' -Stage 'Bloat' -Message "Selected Appx packages removed" -Level 'Info'
    } catch { Write-OptLog -Module 'System' -Stage 'Bloat' -Message $_.Exception.Message -Level 'Warn' }

    # Service tuning: disable heavy disk users cautiously
    foreach ($svc in "DiagTrack","SysMain","WSearch") {
        try {
            if (Get-Service $svc -ErrorAction SilentlyContinue) {
                Stop-Service $svc -Force -ErrorAction SilentlyContinue
                Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
                Write-OptLog -Module 'System' -Stage 'Service' -Message "Disabled $svc" -Level 'Info'
            }
        } catch { Write-OptLog -Module 'System' -Stage 'Service' -Message $_.Exception.Message -Level 'Warn' }
    }

    $after = Get-OptMetrics -Phase 'SystemAfter'; Save-OptMetrics $after
    [pscustomobject]@{ Snapshot=$snap; Before=$before; After=$after }
}

Export-ModuleMember -Function Invoke-SystemOptimization