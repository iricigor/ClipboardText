function new-StatementTerminatingError([string] $Message, [System.Management.Automation.ErrorCategory] $Category = 'InvalidOperation') {
    $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord `
      $Message,
      $null, # a custom error ID (string)
      $Category, # the PS error category - do NOT use NotSpecified - see below.
      $null # the target object (what object the error relates to)
    )) 
}