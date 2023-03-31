class Alarm
{
  [int]$BeepFrequency = 200
  [int]$BeepDuration  = 1000
  [int]$BeepRepeat    = 20
  [timespan]$Timespan = [timespan]::fromMilliseconds(1800000)

  hidden [bool]$IsRunning
  hidden [bool]$IsDebug

  Alarm()
  {
    
  }
  
  [void] Start()
  {
    $this.IsRunning = $true
    do {
      for ($i = 0; $i -lt $this.Timespan.TotalSeconds; $i++) {
        $this.writeTime($this.Timespan.TotalSeconds - $i)
        Start-Sleep -s 1
      }
      for ($i = 0; $i -lt $this.BeepRepeat; $i++) {
        if ($i % 2 -eq 0) {
          [console]::Beep($this.BeepFrequency, $this.BeepDuration) 
        }
        else {
          [console]::Beep($this.BeepFrequency, $this.BeepDuration / 2)
        }
      }
    }
    until (!$this.IsRunning)
  }

  [void] StartWithDateTime([datetime]$datetime)
  {
    if ($datetime -le [datetime]::Now) {
      throw "Datetime is in past! Enter datetime in future."
    }
    $this.startWithTimespan($datetime - [datetime]::Now)
  }

  [void] StartWithTimespan([timespan]$interval) {
    $this.Timespan = $interval
    for ($i = 0; $i -lt $this.Timespan.TotalSeconds; $i++) {
      $this.writeTime($this.Timespan.TotalSeconds - $i)
      Start-Sleep -s 1
    }
    while ($true) {
      [console]::Beep(200, 1000)
    }
  }

  hidden [void] WriteTime([int64]$seconds)
  {
    if ($this.IsDebug) {
      $this.write($seconds, "DEBUG", [consolecolor]::Green)
    }
    switch ($seconds) {
      {$_ % 60 -eq 0} {
        $this.write($seconds, [console]::ForegroundColor)
      }
      {$_ -match '^(5|4|3|2)0$'} {
        $this.write($seconds, [console]::ForegroundColor)
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
  [cmdletbinding()]
  param(
      [validaterange(0,23)]
      [parameter(parametersetname="Delineate")]
    [int]$Hours,
      [validaterange(0,59)]
      [parameter(parametersetname="Delineate")]
    [int]$Minutes,
      [validaterange(0,59)]
      [parameter(parametersetname="Delineate")]
    [int]$Seconds,
      [parameter(parametersetname="Timespan")]
    [timespan]$Timespan,
      [parameter(parametersetname="DateTime")]
    [datetime]$DateTime
  )
  try {
    $Alarm = [alarm]::new()
    if ($PsCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
      $Alarm.IsDebug = $true
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
