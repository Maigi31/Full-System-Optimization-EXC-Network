Import-Module "$PSScriptRoot\..\Core\Core.psm1" -Force

function Invoke-RAMOptimization {
    $snap = New-OptSnapshot
    $before = Get-OptMetrics -Phase 'RAMBefore'; Save-OptMetrics $before

    # Elevate foreground app slightly (not too aggressive)
    try {
        $fg = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | Sort-Object CPU -Descending | Select-Object -First 1
        if ($fg) { $fg.PriorityClass = 'AboveNormal' }
        Write-OptLog -Module 'RAM' -Stage 'Priority' -Message ("Foreground prioritized: {0}" -f ($fg?.Name)) -Level 'Info'
    } catch { Write-OptLog -Module 'RAM' -Stage 'Priority' -Message $_.Exception.Message -Level 'Warn' }

    # Safe working set trim: exclude essential processes; cap count; stagger
    $sig = @"
using System;
using System.Runtime.InteropServices;
public static class WS {
    [DllImport("psapi.dll")]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@
    Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue

    $exclude = @('System','Idle','wininit','services','lsass','csrss','smss','svchost','dwm','explorer','Registry')
    $candidates = Get-Process | Where-Object {
        $_.MainWindowHandle -eq 0 -and $_.CPU -lt 1 -and ($exclude -notcontains $_.Name)
    } | Sort-Object WorkingSet -Descending | Select-Object -First 25

    $trimmed = 0
    foreach ($p in $candidates) {
        try {
            [WS]::EmptyWorkingSet($p.Handle) | Out-Null
            $trimmed++
            Start-Sleep -Milliseconds 50  # dampen spikes
        } catch {}
    }
    Write-OptLog -Module 'RAM' -Stage 'Trim' -Message "Trimmed $trimmed working sets (capped at 25, exclusions applied)" -Level 'Info'

    $after = Get-OptMetrics -Phase 'RAMAfter'; Save-OptMetrics $after
    [pscustomobject]@{ Snapshot=$snap; Before=$before; After=$after; Trimmed=$trimmed }
}

Export-ModuleMember -Function Invoke-RAMOptimization