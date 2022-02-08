  
<#
  Class:
    using module '<pathtomodule.psm1>'
  LogPath and LogName are required -> ToStream()
#>

using namespace System.IO;

enum LogLevel
{
  ERR = 0
  WRN = 1
  INF = 2
  DBG = 3
}

class Logging : System.IDisposable
{
  [loglevel]$LogLevel = [loglevel]::DBG
  [string]$LogPath
  [string]$LogName = '_Default_.log'

  hidden [string]$FormatDateTime = " ] {0:yyyy-MM-ddTHHmmss.ffff} {1}: {2}"
  hidden [string]$FormatTimeSpan = " ] {0} {1}: {2}"
  hidden [datetime]$InitTime
  hidden [bool]$UseInitTime
  hidden [streamwriter]$LogStream

  Logging() { }

  Logging([string]$logPath)
  {
    $this.newLogStream($logPath)
  }

  [object] Initialize()
  {
    $this.InitTime = [datetime]::Now
    $this.UseInitTime = $true
    return $this
  }

  [object] Initialize([string]$logPath)
  {
    $this.newLogStream($logPath)
    return $this.initialize()
  }

  [void] NewLogStream([string]$logPath)
  {
    $this.LogPath = $logPath
    try {
      if (!$this.LogStream -or !$this.LogStream.BaseStream.Handle) {
         if (![directory]::exists($this.LogPath)) {
           [directory]::createDirectory($this.LogPath)
         }
         if (![file]::exists("$($this.LogPath)$($this.LogName)")) {
           $this.LogStream = [file]::create("$($this.LogPath)$($this.LogName)")
         }
         else {
           $this.LogStream = [streamwriter]::new("$($this.LogPath)$($this.LogName)", $true)
         }
       }
    }
    catch {
      if ($this.LogStream) {
        $this.LogStream.dispose()
      }
    }
  }

  [void] ToErr([string]$msg, [string]$src)
  {
    if ($this.LogLevel -ge 0) {
      $this.toConsole([loglevel]::ERR, $msg, $src)
    }
    $this.toStream([loglevel]::ERR, $msg, $src)
  }
  
  [void] ToWrn([string]$msg, [string]$src)
  {
    if ($this.LogLevel -ge 1) {
      $this.toConsole([loglevel]::WRN, $msg, $src)
    }
    $this.toStream([loglevel]::WRN, $msg, $src)
  }
  
  [void] ToInf([string]$msg, [string]$src)
  {
    if ($this.LogLevel -ge 2) {
      $this.toConsole([loglevel]::INF, $msg, $src)
    }
    $this.toStream([loglevel]::INF, $msg, $src)
  }
  
  [void] ToDbg([string]$msg, [string]$src)
  {
    if ($this.LogLevel -ge 3) {
      $this.toConsole([loglevel]::DBG, $msg, $src)
    }
    $this.toStream([loglevel]::DBG, $msg, $src)
  }

  hidden [void] ToConsole([loglevel]$lvl, [string]$msg, [string]$src)
  {
    [console]::write("[ ")
    [console]::ForegroundColor = $this.toColor($lvl)
    [console]::write($lvl.toString())
    [console]::resetColor()
    if ($this.useInitTime) {
      [console]::writeLine($this.FormatTimeSpan, ([datetime]::Now - $this.InitTime).toString(), $src, $msg)
    }
    else {
      [console]::writeLine($this.FormatDateTime, [datetime]::Now.toLocalTime(), $src, $msg)      
    }
  }

  hidden [void] ToStream([loglevel]$lvl, [string]$msg, [string]$src)
  {
    if (![string]::isNullOrWhiteSpace($this.LogPath)) {
      $this.LogStream.writeLine("[ $($lvl.toString())$($this.FormatDateTime)", [datetime]::Now.toLocalTime(), $src, $msg)
      $this.LogStream.flush()
      <# Removed to organize log files.
        if ($this.useInitTime) {
          $this.LogStream.writeLine("[ $($lvl.toString())$($this.FormatTimeSpan)", ([datetime]::Now - $this.InitTime).toString(), $src, $msg)
        }
        else {
          $this.LogStream.writeLine("[ $($lvl.toString())$($this.FormatDateTime)", [datetime]::Now.toLocalTime(), $src, $msg)
        }
      #>
    }
  }

  hidden [string] ToColor([loglevel]$lvl)
  {
    switch ($lvl) {
      ([loglevel]::ERR) { return [consolecolor]::Red    }
      ([loglevel]::WRN) { return [consolecolor]::Yellow }
      ([loglevel]::INF) { return [consolecolor]::Cyan   }
      ([loglevel]::DBG) { return [consolecolor]::Green  }
    }
    return [console]::ForegroundColor
  }

  [void] Dispose()
  {
    try {
      $this.LogPath = [string]::Empty
      if ($this.LogStream) {
        $this.LogStream.close()
        $this.LogStream.dispose()
      }
      [gc]::collect()
    }
    finally {
      [gc]::suppressFinalize($this)
    }
  }
}
