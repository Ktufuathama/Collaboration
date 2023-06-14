class Alarm
{
  [int]$BeepFrequency = 200
  [int]$BeepDuration  = 1000
  [int]$BeepRepeat    = 3
  [timespan]$Timespan = [timespan]::fromMilliseconds(1800000)
  
  [bool]$IsDebug
  [bool]$IsQuiet
  [bool]$IsOnce

  hidden [bool]$AlarmToggle = $true
  hidden [array]$AlarmString = @(
    "     _    _        _    ____  __  __  "
    "    / \  | |      / \  |  _ \|  \/  | "
    "   / _ \ | |     / _ \ | |_) | |\/| | "
    "  / ___ \| |___ / ___ \|  _ <| |  | | "
    " /_/   \_\_____/_/   \_\_| \_\_|  |_| "
    "                                      "
  )

  Alarm()
  {
    
  }

  [void] Start()
  {
    try {
      for ($i = 0; $i -lt $this.Timespan.TotalSeconds; $i++) {
        $this.writeTime($this.Timespan.TotalSeconds - $i)
        Start-Sleep -s 1
      }
      if ($this.IsOnce) {
        $this.writeAlarm()
        if (!$this.IsQuiet) {
          for ($i = $this.BeepRepeat; $i -gt 0; $i--) {
            [console]::Beep(200, 1000)
          }
        }
        return
      }
      while ($true) {
        $this.writeAlarm()
        if ($this.IsQuiet) {
          Start-Sleep -m 500
        }
        else {
          [console]::Beep(200, 1000)
        }
      }
    }
    catch {
      throw $_
    }
    finally {
      [console]::resetColor()
      [console]::setCursorPosition(0, [console]::CursorTop + $this.AlarmString.Count)
    }
  }

  [void] StartWithDateTime([datetime]$datetime)
  {
    if ($datetime -le [datetime]::Now) {
      throw "Datetime is in past! Enter datetime in future."
    }
    $this.startWithTimespan($datetime - [datetime]::Now)
  }

  [void] StartWithTimespan([timespan]$interval)
  {
    $this.Timespan = $interval
    $this.start()
  }

  [void] WriteAlarm()
  {
    if ($this.AlarmToggle) {
      [console]::ForegroundColor = [console]::BackgroundColor
      [console]::BackgroundColor = [consolecolor]::Red
      [console]::write("$($this.AlarmString.padRight([console]::BufferWidth) -join "`n")")
      [console]::resetColor()
      if ($this.IsOnce) {
        return
      }
      [console]::setCursorPosition(0, [console]::CursorTop - ($this.AlarmString.Count - 1))
      $this.AlarmToggle = $false
    }
    else {
      [console]::ForegroundColor = [consolecolor]::Red
      [console]::write("$($this.AlarmString.padRight([console]::BufferWidth) -join "`n")")
      [console]::resetColor()
      [console]::setCursorPosition(0, [console]::CursorTop - ($this.AlarmString.Count - 1))
      $this.AlarmToggle = $true
    }
  }

  [void] WriteTime([int64]$seconds)
  {
    if ($this.IsDebug) {
      $this.write($seconds, "DEBUG", [consolecolor]::Green)
    }
    switch ($seconds) {
      {$_ % 60 -eq 0} {
        $this.write($seconds, [console]::ForegroundColor)
      }
      {$_ -match '^(5|4|3|2)0$'} {
        $this.write($seconds, [consolecolor]::Yellow)
      }
      {$_ -le 10} {
        $this.write($seconds, [consolecolor]::Red)
      }
    }
  }
  
  hidden [void] Write([int64]$seconds, [string]$message, [consolecolor]$color)
  {
    [console]::ForegroundColor = $color
    [console]::writeLine("TimeRemaining: {0} {1}", [timespan]::fromSeconds($seconds).toString(), $message)
    [console]::resetColor()
  }
  
  hidden [void] Write([int64]$seconds, [consolecolor]$color)
  {
    [console]::ForegroundColor = $color
    [console]::writeLine("TimeRemaining: {0}", [timespan]::fromSeconds($seconds).toString())
    [console]::resetColor()
  }
}

function Start-Alarm {
  [cmdletbinding(defaultparametersetname="Timespan")]
  param(
      [parameter(parametersetname="Timespan", position=0)]
    [timespan]$Timespan = "00:30:00",
      [validaterange(0,23)]
      [parameter(parametersetname="Delineate")]
    [int]$Hours,
      [validaterange(0,59)]
      [parameter(parametersetname="Delineate")]
    [int]$Minutes,
      [validaterange(0,59)]
      [parameter(parametersetname="Delineate")]
    [int]$Seconds,
      [parameter(parametersetname="DateTime")]
    [datetime]$DateTime,
      [alias("IsNotQuiet")]
    [switch]$PlayAlarm,
      [alias("Once")]
    [switch]$RunOnce
  )
  try {
    $Alarm = [alarm]::new()
    if ($PsCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
      $Alarm.IsDebug = $true
    }
    if (!$PsCmdlet.MyInvocation.BoundParameters["PlayAlarm"].IsPresent) {
      $Alarm.IsQuiet = $true
    }
    if ($PsCmdlet.MyInvocation.BoundParameters["RunOnce"].IsPresent) {
      $Alarm.IsOnce = $true
    }
    switch ($PsCmdlet.ParameterSetName) {
      "Delineate" {
        $Alarm.startWithTimespan("$($Hours):$($Minutes):$($Seconds)")
      }
      "Timespan" {
        $Alarm.startWithTimespan($Timespan)
      }
      "DateTime" {
        $Alarm.startWithDateTime($DateTime)
      }
      "__AllParameterSets" {
        # Nothing.
      }
    }
  }
  catch {
    throw $_
  }
}
