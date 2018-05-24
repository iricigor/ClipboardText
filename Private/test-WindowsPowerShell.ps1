
function test-WindowsPowerShell {
    # !! $IsCoreCLR is not available in Windows PowerShell and, if
    # !! Set-StrictMode is set, trying to access it would fail.
    $null, 'Desktop' -contains $PSVersionTable.PSEdition 
}