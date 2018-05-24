if ($PSVersionTable.PSVersion.Major -gt 2) {
    Set-StrictMode -Version 1
}

Set-Alias gcbt Get-ClipboardText


function Get-ClipboardText {
      
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch] $Raw
    )
    
    $rawText = $lines = $null
    if (test-WindowsPowerShell) {
        # *Windows PowerShell*
    
        if ($PSVersionTable.PSVersion -ge [version] '5.0.0') {
            # Ps*Win* v5+ has Get-Clipboard / Set-Clipboard cmdlets.
          
            if ($Raw) {
                $rawText = Get-Clipboard -Format Text -Raw
            }
            else {
                $lines = Get-Clipboard -Format Text
            }
    
        }
        else {
            # PSWin v4-
            Add-Type -AssemblyName System.Windows.Forms
            if ([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'STA') {
                # -- STA mode:
                Write-Verbose "STA mode: Using [Windows.Forms.Clipboard] directly."
                # To be safe, we explicitly specify that Unicode (UTF-16) be used - older platforms may default to ANSI.
                $rawText = [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::UnicodeText)
            }
            else {
                # -- MTA mode: Since the clipboard must be accessed in STA mode, we use a [System.Windows.Forms.TextBox] instance to mediate.
                Write-Verbose "MTA mode: Using a [System.Windows.Forms.TextBox] instance for clipboard access."
                $tb = New-Object System.Windows.Forms.TextBox
                $tb.Multiline = $True
                $tb.Paste()
                $rawText = $tb.Text
            }
        }
    
    }
    else {
        # PowerShell *Core*
    
        # No native PS support for writing to the clipboard -> external utilities
        # must be used.
        # Since PS automatically splits external-program output into individual
        # lines and trailing empty lines can get lost in the process, we 
        # must, unfortunately, send the text to a temporary *file* and read
        # that.
    
        $tempFile = [io.path]::GetTempFileName()
    
        try {
          
            if ($IsWindows) {
                # Use an ad-hoc JScript to access the clipboard.
                # Gratefully adapted from http://stackoverflow.com/a/15747067/45375
                # Note that trying the following directly from PowerShell Core does NOT work,
                #   (New-Object -ComObject htmlfile).parentWindow.clipboardData.getData('text')
                # because .parentWindow is always $null in *older* PS versions, e.g. in v2.
                # Passing true as the last argument to .CreateTextFile() creates a UTF16-LE file (with BOM).
                $tempScript = [io.path]::GetTempFileName()
                @"
var txt = WSH.CreateObject('htmlfile').parentWindow.clipboardData.getData('text'); 
var f = WSH.CreateObject('Scripting.FileSystemObject').CreateTextFile('$($tempFile -replace "\\", "\\")', true, true);
f.Write(txt); f.Close();
"@ | Set-content -Encoding ASCII -LiteralPath $tempScript
            cscript /nologo /e:JScript $tempScript
            Remove-Item $tempScript
          } elseif ($IsMacOS) {
    
            # Note: For full robustness, using the full path to sh, '/bin/sh' is preferable, but then 
            #       we couldn't use mock functions to override the command for testing.
            sh -c "pbpaste > '$tempFile'"
    
          } else { # $IsLinux
    
            # Note: Requires xclip, which is not installed by default on most Linux distros
            #       and works with freedesktop.org-compliant, X11 desktops.
            sh -c "xclip -selection clipboard -out > '$tempFile'"
            if ($LASTEXITCODE -eq 127) { new-StatementTerminatingError "xclip is not installed; please install it via your platform's package manager; e.g., on Debian-based distros such as Ubuntu: sudo apt install xclip" }
    
          }
          
          if ($LASTEXITCODE) { new-StatementTerminatingError "Invoking the native clipboard utility failed unexpectedly." }
    
          # Read the contents of the temp. file into a string variable.
          if ($IsWindows) { # temp. file is UTF16-LE 
            $rawText = [IO.File]::ReadAllText($tempFile, [Text.Encoding]::Unicode)
          } else { # temp. file is UTF8, which is the default encoding
            $rawText = [IO.File]::ReadAllText($tempFile)
          }
    
        } finally {
          Remove-Item $tempFile
        }
    
      }
    
      # Output the retrieved text
      if ($Raw) {  # as-is (potentially multi-line)
        $result = $rawText
      } else {     # as an array of lines (as the PsWinV5+ Get-Clipboard cmdlet does)
        if ($null -eq $lines) {
          # Note: This returns [string[]] rather than [object[]], but that should be fine.
          $lines = $rawText -split '\r?\n'
        }
        $result = $lines
      }
    
      # If the effective result is the *empty string* [wrapped in a single-element array], we output 
      # $null, because that's what the PsWinV5+ Get-Clipboard cmdlet does.
      if (-not $result) {
        # !! To be consistent with Get-Clipboard, we output $null even in the absence of -Raw,
        # !! even though you could argue that *nothing* should be output (i.e., implicitly, the "null collection", 
        # !! [System.Management.Automation.Internal.AutomationNull]::Value)
        # !! so that trying to *enumerate* the result sends nothing through the pipeline.
        # !! (A similar, but opposite inconsistency is that Get-Content with a zero-byte file outputs the "null collection"
        # !!  both with and withour -Raw).
        $null
      } else {
        $result
      }
    
}