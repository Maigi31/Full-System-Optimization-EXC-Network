param(
    [ValidateSet('System','Storage','RAM','Drivers','All')]
    [string]$Scope = 'All'
)

Import-Module "$PSScriptRoot\Core\Core.psm1" -Force
Import-Module "$PSScriptRoot\System\SystemOptimize.psm1" -Force
Import-Module "$PSScriptRoot\Storage\StorageOptimize.psm1" -Force
Import-Module "$PSScriptRoot\RAM\RAMOptimize.psm1" -Force
Import-Module "$PSScriptRoot\Drivers\DriverUpdate.psm1" -Force

switch ($Scope) {
    'System'  { Invoke-SystemOptimization  | Format-List }
    'Storage' { Invoke-StorageOptimization | Format-List }
    'RAM'     { Invoke-RAMOptimization     | Format-List }
    'Drivers' { Invoke-DriverUpdate        | Format-List }
    'All'     {
        Invoke-SystemOptimization  | Format-List
        Invoke-StorageOptimization | Format-List
        Invoke-RAMOptimization     | Format-List
        Invoke-DriverUpdate        | Format-List
    }
}