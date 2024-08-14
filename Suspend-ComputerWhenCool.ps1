#function Suspend-ComputerWhenCool {
  [cmdletbinding()]
  param(
    [int]$TempThreshold=55 # In Celsius (122F).
  )
  ### Main
  while ($true) {
    $TempCurrent=$((nvidia-smi.exe -q -a) -match "GPU Current Temp.*:(.*)").split(" ")[-2]
    if ($TempCurrent -gt $TempThreshold) {
      [console]::writeLine("GPU Current Temp ($($TempCurrent)) above $($TempThreshold) threshold. Waiting 5 seconds...")
      Start-Sleep -seconds 5
    }
    else {
      [console]::writeLine("GPU Current Temp below $($TempThreshold) threshold. Suspending computer...")
      Start-Sleep -seconds 1
      [void][system.reflection.assembly]::loadWithPartialName('System.Windows.Forms')
      [system.windows.forms.application]::setSuspendState('Hibernate', $false, $false)
      return
    }
  }
#}
