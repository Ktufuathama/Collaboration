<#
  == McAfee Endpoint Security ==
  Usage:
    $ES = [endpointsecurity]::new()
    $ES.invoke('Quick', 'Status')
    > "Quick scan never run"
    $ES.invoke('Quick', 'Start')
    > "Quick scan started"
    $ES.invoke('Quick', 'Status')
    > "Quick scan running"
    $ES.invoke('Quick', 'Status')
    > "Quick scan finished"
#>

using namespace System.Diagnostics;

enum SecurityTask
{
  Quick
  Full
}

enum SecurityAction
{
  Cancel
  Pause
  Resume
  Start
  Status
}

class EndpointSecurity
{
  [string]$Message
  [securitytask]$Task = [securitytask]::Quick

  hidden [system.diagnostics.process]$Process
  hidden [string]$Executable = 'C:\Program Files (x86)\McAfee\Endpoint Security\Threat Prevention\amcfg.exe'

  EndpointSecurity()
  {
    if (![system.io.file]::exists($this.Executable)) {
      throw "Executable Missing: $($this.Executable)"
    }
  }

  [object] Invoke([securitytask]$task, [securityaction]$action)
  {
    $StartInfo = [system.diagnostics.processstartinfo]::new($this.Executable)
    $StartInfo.Arguments = "/scan /task $($task) /action $($action)"
    $StartInfo.CreateNoWindow = $true
    $StartInfo.RedirectStandardOutput = $true
    $this.Process = [system.diagnostics.process]::start($StartInfo)
    while (!$this.Process.HasExited) {
      Start-Sleep -s 1
    }
    if ($this.Process.ExitCode -ne 0) {
      #ExitCode
    }
    $this.Message = $this.Process.StandardOutput.readToEnd().replace("`n", '').replace("`0", '')
    return $this.Message
  }

  [object] GetStatus()
  {
    return $this.invoke($this.Task, [securityaction]::Status)
  }
}

<#
  using namespace System.Management.Automation
  using namespace System.Management.Automation.Language

  Register-ArgumentCompleter -native -commandName 'amcfg' -scriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $CommandElements = $commandAst.CommandElements
    $Command = @(
      'amcfg'
      for ($i = 1; $i -lt $commandAst.Count, $i++) {
        $element = $CommandElements[$i]
        if ($element -isnot [stringconstantexpressionast] -or $element.StringConstantType -ne [stringconstanttype]::BareWord -or $element.Value.StartWith('-')) {
          break
        }
        $element.Value
      }
    ) -join ';'
    $Completions = @(switch ($Command) {
      'amcfg' {
        [completionresult]::new('/scan', '/scan', [completionresulttype]::ParameterName,  'Perform scan operations')
        [completionresult]::new('/task', '/task', [completionresulttype]::ParameterName,  'Task to perform')
        [completionresult]::new('quick', 'quick', [completionresulttype]::ParameterValue, 'A1')
        [completionresult]::new('full',  'full',  [completionresulttype]::ParameterValue, 'A2')
        [completionresult]::new('/task', '/task', [completionresulttype]::ParameterName,  'Task to perform')
      }
    })
    $Completions.where({$_.CompletionText -like "$($WordToComplete)"}) | Sort-Object -property 'ListItemText'
  }
#>
