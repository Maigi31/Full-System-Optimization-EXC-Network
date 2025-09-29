Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

function Invoke-DriverUpdate {
    $snap = New-OptSnapshot
    $before = Get-OptMetrics -Phase 'DriversBefore'; Save-OptMetrics $before

    # Staged install from local folder; OEM-first workflow (you maintain packages)
    $stage = "C:\Drivers\Staging"
    if (Test-Path $stage) {
        Get-ChildItem $stage -Recurse -Include *.inf -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                pnputil /add-driver $_.FullName /install | Out-Null
                Write-OptLog -Module 'Drivers' -Stage 'Install' -Message "Installed: $($_.FullName)" -Level 'Info'
            } catch { Write-OptLog -Module 'Drivers' -Stage 'Install' -Message $_.Exception.Message -Level 'Warn' }
        }
    } else {
        Write-OptLog -Module 'Drivers' -Stage 'Install' -Message "Staging path not found: $stage" -Level 'Warn'
    }

    $after = Get-OptMetrics -Phase 'DriversAfter'; Save-OptMetrics $after
    [pscustomobject]@{ Snapshot=$snap; Before=$before; After=$after }
}

Export-ModuleMember -Function Invoke-DriverUpdate