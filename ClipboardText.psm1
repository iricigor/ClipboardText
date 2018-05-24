<#

IMPORTANT: THIS MODULE MUST REMAIN PSv2-COMPATIBLE.

#>

# Module-wide defaults.

# !! PSv2: We dectivate even the check for accessing nonexistent variables, because
# !!       of a pitfall where parameter variables belonging to a parameter set
# !!       other than the one selected by a given invocation are considered undefined.
if ($PSVersionTable.PSVersion.Major -gt 2) {
  Set-StrictMode -Version 1
}


$ModName = 'ClipboardText'
Get-Module $ModName | Remove-Module -Force

Write-Host "`n`n$ModName module import starting`n" -ForegroundColor Cyan


#
# Import main functions
#

$Public = @(Get-ChildItem (Join-Path $PSScriptRoot 'Public') -Filter *.ps1)
$Private = @(Get-ChildItem (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -ErrorAction SilentlyContinue)

foreach ($F in ($Private+$Public) ) {

    Write-Host ("Importing $($F.Name)... ") -NoNewline
    
    try {
        . ($F.FullName)
        Write-Host '  OK  ' -ForegroundColor Green
    } catch {
        Write-Host 'FAILED' -ForegroundColor Red
    }
}

Export-ModuleMember -Function $Public.BaseName
Write-Host "Exported $($Public.Count) member(s)"
Export-ModuleMember -Alias *


Write-Host "`nType 'Get-Command -Module $ModName' for list of commands, 'Get-Help <CommandName>' for help, or"
Write-Host "'Get-Command -Module $ModName | Get-Help | Select Name, Synopsis' for explanation on all commands`n"