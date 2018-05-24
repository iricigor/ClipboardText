function Set-ClipboardText {

    [CmdletBinding(DefaultParameterSetName='Default')] # !! PSv2 doesn't support PositionalBinding=$False
    [OutputType([string], ParameterSetName='PassThru')]
    param(
        [Parameter(Position=0, ValueFromPipeline = $True)] # Note: The built-in PsWinV5.0+ Set-Clipboard cmdlet does NOT have mandatory input, in which case the clipbard is effectively *cleared*.
        [AllowNull()] # Note: The built-in PsWinV5.0+ Set-Clipboard cmdlet allows $null too.
        $InputObject
        ,
        [int] $Width # max. output-line width for non-string input
        ,
        [Parameter(ParameterSetName='PassThru')]
        [switch] $PassThru
    )

    begin {
    # Initialize an array to collect all input objects in.
    # !! Incredibly, in PSv2 using either System.Collections.Generic.List[object] or
    # !! System.Collections.ArrayList ultimately results in different ... | Out-String
    # !! output, with the group header ('Directory:') for input `GetItem / | Out-String`
    # !! inexplicably missing - even .ToArray() conversion or an [object[]] cast
    # !! before piping to Out-String doesn't help.
    # !! Given that we don't expect large collections to be sent to the clipboard,
    # !! we make do with inefficiently "growing" an *array* ([object[]]), i.e.
    # !! cloning the old array for each input object.
    $inputObjs = @()
    }

    process {
    # Collect the input objects.
    $inputObjs += $InputObject
    }
    
    end {

    # * The input as a whole is converted to a a single string with
    #   Out-String, which formats objects the same way you would see on the
    #   console.
    # * Since Out-String invariably appends a trailing newline, we must remove it.
    #   (The PS Core v6 -NoNewline switch is NOT an option, as it also doesn't
    #   place newlines *between* objects.)
    $widthParamIfAny = if ($PSBoundParameters.ContainsKey('Width')) { @{ Width = $Width } } else { @{} }
    $allText = ($inputObjs | Out-String @widthParamIfAny) -replace '\r?\n\z'

    if (test-WindowsPowerShell) { # *Windows PowerShell*
        
        if ($PSVersionTable.PSVersion -ge [version] '5.1.0') { # Ps*Win* v5.1+ now has Get-Clipboard / Set-Clipboard cmdlets.
            
            # !! As of PsWinV5.1, `Set-Clipboard ''` reports a spurious error (but still manages to effectively) clear the clipboard.
            # !! By contrast, using `Set-Clipboard $null` succeeds.
            Set-Clipboard -Value ($allText, $null)[$allText.Length -eq 0]
            
        } else { # PSv5.0-
            
            Add-Type -AssemblyName System.Windows.Forms
            if ([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'STA') {
                # -- STA mode: we can use [Windows.Forms.Clipboard] directly.
                Write-Verbose "STA mode: Using [Windows.Forms.Clipboard] directly."
                if ($allText.Length -eq 0) { $AllText = "`0" } # Strangely, SetText() breaks with an empty string, claiming $null was passed -> use a null char.
                # To be safe, we explicitly specify that Unicode (UTF-16) be used - older platforms may default to ANSI.
                [System.Windows.Forms.Clipboard]::SetText($allText, [System.Windows.Forms.TextDataFormat]::UnicodeText)

            } else {
                # -- MTA mode: Since the clipboard must be accessed in STA mode, we use a [System.Windows.Forms.TextBox] instance to mediate.
                Write-Verbose "MTA mode: Using a [System.Windows.Forms.TextBox] instance for clipboard access."
                if ($allText.Length -eq 0) {
                    # !! This approach cannot set the clipboard to an empty string: the text box must
                    # !! must be *non-empty* in order to copy something. A null character doesn't work.
                    # !! We use the least obtrusive alternative - a newline - and issue a warning.
                    $allText = "`r`n"
                    Write-Warning "Setting clipboard to empty string not supported in MTA mode; using newline instead."
                }
                $tb = New-Object System.Windows.Forms.TextBox
                $tb.Multiline = $True
                $tb.Text = $allText
                $tb.SelectAll()
                $tb.Copy()
            }

        }
        
    } else { # PowerShell *Core*
        
        # No native PS support for writing to the clipboard ->
        # external utilities must be used.

        # To prevent adding a trailing \n, which PS inevitably adds when sending
        # a string through the pipeline to an external command, use a temp. file,
        # whose content can be provided via native input redirection (<)
        $tmpFile = [io.path]::GetTempFileName()

        if ($IsWindows) {
        # The clip.exe utility requires *BOM-less* UTF16-LE for full Unicode support.
        [IO.File]::WriteAllText($tmpFile, $allText, (New-Object System.Text.UnicodeEncoding $False, $False))
        } else { # $IsUnix -> use BOM-less UTF8
        # PowerShell's UTF8 encoding invariably creates a file WITH BOM
        # so we use the .NET Framework, whose default is BOM-*less* UTF8.
        [IO.File]::WriteAllText($tmpFile, $allText)
        }
        
        # Feed the contents of the temporary file via stdin to the 
        # platform-appropriate clipboard utility.
        try {

        if ($IsWindows) {
            Write-Verbose "Windows: using clip.exe"
            cmd.exe /c clip.exe '<' $tmpFile  # !! Invoke `cmd` as `cmd.exe` so as to support Pester-based `Mock`s - at least as of v4.3.1, that's a requirement; see https://github.com/pester/Pester/issues/1043
        } elseif ($IsMacOS) {
            Write-Verbose "macOS: Using pbcopy"
            sh -c "pbcopy < '$tmpFile'"
        } else { # $IsLinux
            Write-Verbose "Linux: using xclip"
            sh -c "xclip -selection clipboard -in < '$tmpFile' >&-" # !! >&- (i.e., closing stdout) is necessary, because xclip hangs if you try to redirect its - nonexistent output with `-in`, which also happens impliclity via `$null = ...` in the context of Pester tests.
            if ($LASTEXITCODE -eq 127) { new-StatementTerminatingError "xclip is not installed; please install it via your platform's package manager; e.g., on Debian-based distros such as Ubuntu: sudo apt install xclip" }
        }
        
        if ($LASTEXITCODE) { new-StatementTerminatingError "Invoking the platform-specific clipboard utility failed unexpectedly." }

        } finally {
        Remove-Item $tmpFile
        }

    }

    if ($PassThru) {
        $allText
    }

    }

}


Set-Alias scbt Set-ClipboardText