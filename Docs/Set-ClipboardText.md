---
external help file: ClipboardText-help.xml
Module Name: ClipboardText
online version:
schema: 2.0.0
---

# Set-ClipboardText

## SYNOPSIS
Copies text to the clipboard.

## SYNTAX

### Default (Default)
```
Set-ClipboardText [[-InputObject] <Object>] [-Width <Int32>] [<CommonParameters>]
```

### PassThru
```
Set-ClipboardText [[-InputObject] <Object>] [-Width <Int32>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Copies a text representation of the input to the system clipboard.

Input can be provided via the pipeline or via the -InputObject parameter.

If you provide no input, the empty string, or $null, the clipboard is
effectively cleared.

Non-text input is formatted the same way as it would print to the console,
which means that the console/terminal window's \[buffer\] width determines
the output line width, which may result in truncated data (indicated with
"...").
To avoid that, you can increase the max.
line width with -Width, but see 
the caveats in the parameter description.

LINUX CAVEAT: The xclip utility must be installed; on Debian-based platforms
                such as Ubuntu, install it with: sudo apt install xclip

WINDOWS CAVEAT: In MTA mode, passing an empty string is not supported; 
                a newline will be copied instead, and a warning issued.

## EXAMPLES

### EXAMPLE 1
```
Set-ClipboardText "Text to copy"
```

Copies the specified text to the clipboard.

### EXAMPLE 2
```
Get-ChildItem -File -Name | Set-ClipboardText
```

Copies the names of all files the current directory to the clipboard.

### EXAMPLE 3
```
Get-ChildItem | Set-ClipboardText -Width 500
```

Copies the text representations of the output from Get-ChildItem to the
clipboard, ensuring that output lines are 500 characters wide.

## PARAMETERS

### -InputObject
Note: The built-in PsWinV5.0+ Set-Clipboard cmdlet does NOT have mandatory input, in which case the clipbard is effectively *cleared*.
Note: The built-in PsWinV5.0+ Set-Clipboard cmdlet allows $null too.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Width
For non-text input, determines the maximum output-line length.
The default is Out-String's default, which is the current console/terminal
window's \[buffer\] width.

Be careful with high values and avoid \[int\]::MaxValue, however, because in
the case of (implicit) Format-Table output each output line is padded to 
that very width, which can require a lot of memory.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
In addition to copying the resulting string representation of the input to
the clipboard, also outputs it, as single string.

```yaml
Type: SwitchParameter
Parameter Sets: PassThru
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String

## NOTES
This function is a "polyfill" to make up for the lack of built-in clipboard
support in Windows Powershell v5.0- and in PowerShell Core as of v6.1,
albeit only with respect to text.
In Windows PowerShell v5.1+, you can use the built-in Set-Clipboard cmdlet
instead (which this function invokes, if available).

## RELATED LINKS
