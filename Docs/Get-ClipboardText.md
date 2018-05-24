---
external help file: ClipboardText-help.xml
Module Name: ClipboardText
online version:
schema: 2.0.0
---

# Get-ClipboardText

## SYNOPSIS
Gets text from the clipboard.

## SYNTAX

```
Get-ClipboardText [-Raw] [<CommonParameters>]
```

## DESCRIPTION
Retrieves text from the system clipboard as an arry of lines (by default)
or as-is (with -Raw).

If the clipboard is empty or contains no text, $null is returned.

LINUX CAVEAT: The xclip utility must be installed; on Debian-based platforms
              such as Ubuntu, install it with: sudo apt install xclip

## EXAMPLES

### EXAMPLE 1
```
Get-ClipboardText | ForEach-Object { $i=0 } { '#{0}: {1}' -f (++$i), $_ }
```

Retrieves text from the clipboard and sends its lines individually through
the pipeline, using a ForEach-Object command to prefix each line with its
line number.

### EXAMPLE 2
```
out.txt
```

Retrieves text from the clipboard as-is and saves it to file out.txt
(with a newline appended).

## PARAMETERS

### -Raw
Output the retrieved text as-is, even if it spans multiple lines.
By default, if the retrieved text is a multi-line string, each line is 
output individually.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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
In Windows PowerShell v5.1+, you can use the built-in Get-Clipboard cmdlet
instead (which this function invokes, if available).

## RELATED LINKS
