Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

function Invoke-StorageOptimization {
    $snap = New-OptSnapshot
    $before = Get-OptMetrics -Phase 'StorageBefore'; Save-OptMetrics $before

    # Try Storage module, fall back to defrag.exe (handles SSD retrim with /L)
    $optimized = $false
    try {
        Import-Module Storage -ErrorAction Stop
        Optimize-Volume -DriveLetter C -Verbose -ErrorAction Stop | Out-Null
        $optimized = $true
        Write-OptLog -Module 'Storage' -Stage 'Optimize' -Message "Optimize-Volume succeeded" -Level 'Info'
    } catch {
        Write-OptLog -Module 'Storage' -Stage 'Optimize' -Message "Optimize-Volume unavailable: $($_.Exception.Message). Falling back to defrag.exe" -Level 'Warn'
        try {
            # /O = perform the appropriate optimize operation; /L = retrim (SSD), both safe
            Start-Process -FilePath "$env:SystemRoot\System32\defrag.exe" -ArgumentList "C: /O" -Wait -NoNewWindow
            Start-Process -FilePath "$env:SystemRoot\System32\defrag.exe" -ArgumentList "C: /L" -Wait -NoNewWindow
            $optimized = $true
            Write-OptLog -Module 'Storage' -Stage 'Optimize' -Message "defrag.exe optimization executed" -Level 'Info'
        } catch {
            Write-OptLog -Module 'Storage' -Stage 'Optimize' -Message "defrag.exe failed: $($_.Exception.Message)" -Level 'Error'
        }
    }

    # Foreground CPU/I/O scheduling bias
    try {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26
        Write-OptLog -Module 'Storage' -Stage 'Priority' -Message "Foreground scheduling bias applied" -Level 'Info'
    } catch { Write-OptLog -Module 'Storage' -Stage 'Priority' -Message $_.Exception.Message -Level 'Warn' }

    $after = Get-OptMetrics -Phase 'StorageAfter'; Save-OptMetrics $after
    [pscustomobject]@{ Snapshot=$snap; Before=$before; After=$after; Optimized=$optimized }
}

Export-ModuleMember -Function Invoke-StorageOptimization