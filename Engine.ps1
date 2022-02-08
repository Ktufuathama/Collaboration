
<#
  ToDo:
    Append Pass option as [hashtable] to Output?
    Key Collision???
    Dynamic TaskLists? Basically returns can include a call to load another module with specified parameters.
    Tasklist is a queue?
    Remote validation happens outside of engine and $this.IsRemote is set. Speed?
    That way we can validate if the object is local via DNS, ETC.
  ToDo:
    Overhaul the verbose system. ($DebugMessage)
    Better implimentation of Options.
    Logging Option that exports to local machine.
    Way of storing RemotingErrors for later diag.
#>

using module ".\Engine\Logging.psm1"

using namespace System.Collections;
using namespace System.Management.Automation.Runspaces;
using namespace System.Net.NetworkInformation;
using namespace System.Net.Sockets;
<#
param(
  [string]$InputObject,
  [psobject]$TaskList
)
try {
  $Engine = [engine]::new($InputObject)
  $Engine.LogLevel = 3
  $Engine.LogPath = 'C:\_\Sandbox\TLE_WorkInProgress\Logs'
  $Engine.InitTime = [datetime]::Now
  $Engine.UseInitTime = $true
  [void]$Engine.initialize()
  if ($Engine.Ready) {
    $Engine.executeTaskList($TaskList)
  }
  else {
    $Engine.returnEmpty()
  }
}
finally {
  $Engine.dispose()
}
return #$Engine
#>

class Engine : Logging
{
  [string]$ObjectValue
  [object]$ExternalRunspace
  [object]$InternalRunspace
  [powershell]$Powershell
  [bool]$Ready = $false
  [bool]$HadException

  hidden [bool]$Remote = $false
  hidden [int]$Port = 5985
  hidden [string]$Protocol = 'http'
  hidden [string]$ObjectName = 'ComputerName'
  hidden [string]$ObjectPattern = "^$([environment]::MachineName.toLower())$"
  hidden [hashtable]$SyncHash = [hashtable]::new()
  hidden [object]$SkipResults
  hidden [bool]$LastState

  Engine([object]$inputObject)
  {
    $this.ObjectValue = $inputObject.toLower()
    $this.Remote = $this.ObjectValue -notMatch $this.ObjectPattern
  }

  Engine([object]$inputObject, [bool]$isRemote)
  {
    $this.ObjectValue = $inputObject.toLower()
    $this.Remote = $isRemote
  }

  [engine] Initialize()
  {
    try {
      $this.toInf("$($this.ObjectValue)", " `t")
      $this.toDbg('Initializing...', 'Session')
      if ($this.ping()) {
        $this.toInf('Online', 'Session')
        if ($this.Remote) {
          $this.toDbg('WSMan Connecting...', 'Session')
          $Uri = [uri]::new("$($this.Protocol)://$($this.ObjectValue):$($this.Port)/WSMAN")
          $Connection = [wsmanconnectioninfo]::new($Uri)
          $Connection.OpenTimeout = 5000
          $Connection.OperationTimeout = 60000
          $this.InternalRunspace = [runspacefactory]::createRunspace($Connection)
          $this.InternalRunspace.open()
          $this.toDbg('WSMan Connected', 'Session')
        }
        $this.toDbg('Creating...', 'Session')
        $this.Powershell = [powershell]::create([initialsessionstate]::createDefault())
        $this.ExternalRunspace = $this.Powershell.Runspace
        $this.Ready = $true
        $this.toDbg('Created', 'Session')
      }
      else {
        $this.toInf('Offline', 'Session')
      }
    }
    catch {
      $this.toErr("$($_.Exception.Message)_$($_.Exception.HResult)", "Session")
      $this.HadException = $true
    }
    return $this
  }

  [arraylist] ExecuteTaskList([psobject]$tasklist)
  {
    $Return = [arraylist]::new()
    if ($this.Ready) {
      $this.toDbg('IsReady', 'ExecuteTaskList')
      for ($i = 0; $i -lt $tasklist.Tasks.Count; $i++) {
        $Return.add($this.executeTask($tasklist.Tasks[$i]))
        <#ToDo: "Do we need this." [gc]::collect() #>
      }
    }
    else {
      $this.toWrn('IsNotReady', 'ExecuteTaskList')
      $Return.add([results]::new($null, $false, 'Exception_TaskListNotReady', $null))
    }
    return $Return
  }

  [object] ExecuteTask([psobject]$task)
  {
    try {
      $this.toInf("Name $($task.ClassName), Args $($task.Arguments.Count)", 'ExecuteTask')
      if (!$this.checkSkip($task)) {
        return $this.SkipResults
      }
      if (!$task.Arguments.containsKey($this.ObjectName) -and $task.Arguments -is [hashtable]) {
        $task.Arguments.add($this.ObjectName, $this.ObjectValue)
      }
      if ($this.Remote -and $task.IsInternal) {
        $this.Powershell.Runspace = $this.InternalRunspace
      }
      else {
        $this.Powershell.Runspace = $this.ExternalRunspace
      }
      if (!$this.checkVeto($task)) {
        return [results]::new($task.ClassName, $false, '!_Exception_CheckVeto', '')
      }
      $this.Powershell.Commands.clear()
      $this.Powershell.addScript($task.ClassCode)
      $this.Powershell.addStatement()
      $this.Powershell.addCommand('New-Object')
      $this.Powershell.addParameter('TypeName', $task.ClassName)
      $this.Powershell.addParameter('ArgumentList', $task.Arguments)
      $InnerReturn = $this.Powershell.invoke()
      if ($this.Powershell.HadErrors) {
        $this.toErr("Inner_$($this.Powershell.Streams.Error[-1].Message)_$($this.Powershell.Streams.Error[-1].HResult)", 'ExecuteTask')
        $this.LastState = $false
        return [results]::new($task.ClassName, $false, '!_ExceptionInner', $this.Powershell.Streams.Error[-1])
      }
      if (!$this.checkPass($task, $InnerReturn)) {
        return [results]::new($task.ClassName, $false, '!_Exception_CheckPass', '')
      }
      $this.toInf('Task Complete.', 'ExecuteTask')
      $Return = [results]::new($task.ClassName, $InnerReturn)
      $this.LastState = $Return.State
      return $Return
    }
    catch {
      $this.HadException = $true
      return [results]::new($task.ClassName, $false, '!_ExceptionOuter', ($error[0].Exception.Message + $_.toString() + $error[0]))
    }
  }

  [bool] CheckSkip([psobject]$task)
  {
    try {
      if ($task.Options.Keys -contains 'Skip') {
        if ($task.Options.Skip -and $this.LastState) {
          $this.toInf("`tSkip_True", 'ExecuteTask')
          $this.LastState = $false
          $this.SkipResults = [results]::new($task.ClassName, $false, '!_ReturnSkipped_True', '')
          return $false
        }
        elseif (!$task.Options.Skip -and !$this.LastState) {
          $this.toInf("`tSkip_False", 'ExecuteTask')
          $this.LastState = $false
          $this.SkipResults = [results]::new($task.ClassName, $false, '!_ReturnSkipped_False', '')
          return $false
        }
      }
      return $true
    }
    catch {
      return $false
    }
  }

  [bool] CheckVeto([psobject]$task)
  {
    try {
      if ($this.SyncHash.Count -gt 0 -and $task.Options.Keys -contains 'Veto') {
        foreach ($Option in $task.Options.Veto) {
          $this.toInf("`tVeto > $($Option)", 'ExecuteTask')
          if ($task.Arguments.contains($Option) -and $this.SyncHash.containsKey($Option)) {
            $task.Arguments.$($Option) = $this.SyncHash[$Option]
          }
        }
      }
      return $true
    }
    catch {
      return $false
    }
  }

  [bool] CheckPass([psobject]$task, [object]$innerReturn)
  {
    try {
      if ($task.Options.Keys -contains 'Pass') {
        foreach ($Pass in $task.Options.Pass) {
          $this.toInf("`tPass: $($Pass)", 'ExecuteTask')
          $this.toInf("$($task.ClassName): $($InnerReturn.Output)", 'ExecuteTask')
          $this.toInf("$($InnerReturn.Output.Arg_1) $($InnerReturn.Output.Arg_2) $($InnerReturn.Output.Arg_3)", 'ExecuteTask')
          if ($this.SyncHash.Keys -contains $Pass) {
            $this.SyncHash.$($Pass) = [results]::new($task.ClassName, $innerReturn).Output.$($Pass)
          }
          else {
            $this.SyncHash.add($Pass, [results]::new($task.ClassName, $innerReturn).Output.$($Pass))
          }
        }
      }
      return $true
    }
    catch {
      return $false
    }
  }

  [object] ReturnEmpty()
  {
    return [results]::new('!', $false, '!Empty', $null)
  }

  [bool] Ping()
  {
    #ToDo: Return Network info for diag.
    try {
      $NetworkStatus = [ping]::new().send($this.ObjectValue).Status
      if ($NetworkStatus -eq [ipstatus]::Success) {
        return $true
      }
      return $false
    }
    catch {
      if ($_.Exception.InnerException.InnerException -is [socketexception]) {
        [void]$_.Exception.InnerException.InnerException.Message.toString()
        return $false
      }
      [void]$_.Exception.Message.toString()
      return $false
    }
  }

  [void] Dispose()
  {
    $this.toDbg('Disposing...', 'Session')
    try {
      if ($this.LogStream) {
        $this.LogPath = [string]::Empty
        $this.LogStream.close()
        $this.LogStream.dispose()
      }
      if ($this.InternalRunspace -and $this.Remote) {
        $this.InternalRunspace.dispose()
      }
      if ($this.ExternalRunspace) {
        $this.ExternalRunspace.dispose()
      }
      $this.Ready = $false
      [gc]::collect()
    }
    finally {
      [gc]::suppressFinalize($this)
    }
  }
}

class Results
{
  [string]$Module
  [bool]$State
  [string]$Status
  [object[]]$Output

  Results([string]$module, [object]$results)
  {
    $this.Module = $module
    $this.State  = $results.State
    $this.Status = $results.Status
    $this.Output = $results.Output
  }

  Results([string]$module, [bool]$state, [string]$status, [object]$output)
  {
    $this.Module = $module
    $this.State  = $state
    $this.Status = $status
    $this.Output = $output
  }
}
