function Show-ChildItem {
  [cmdletbinding()]
  param(
    [switch]$Full
  )
  $ChildItem = [childitem]::new()
  $ChildItem.write($Full)
}

class ChildItem
{
  [object]$Host

  <#
    Recurse by depth?
    GitHub?
    FileChange?
    Rights and Access?
    FileCount?
  #>

  ChildItem() {
    $this.Host = Get-Host
  }

  [object] Write([bool]$full)
  {
    switch ((Get-Location).Provider.Name) {
      'FileSystem' {
        return $this.writeFileSystem($full)
      }
      default {
        return (Get-ChildItem -force)
      }
    }
    return 0
  }

  [string] WriteFileSystem([bool]$full)
  {
    $Items = Get-ChildItem -force | Sort-Object -property `
    @{
      Expression = 'PSIsContainer'
      Descending = $true
    },
    @{
      Expression = 'Name'
      Descending = $false
    }
    [console]::ForegroundColor = [consolecolor]::Gray
    if ($full) {
      [console]::write("`r Mode     Creation         LastWrite`n")
    }
    else {
      [console]::write("`r Mode`n")
    }
    [console]::resetColor()
    for ($i = 0; $i -lt $Items.Count; $i++) {
      [console]::ForegroundColor = [consolecolor]::Black
      [console]::BackgroundColor = [consolecolor]::DarkGray
      [console]::write("$($Items[$i].Mode)-")

      #CheckFileAccess
      #ToDo
      
      [console]::resetColor()
      if ($full) {
        [console]::write(" ")
        [console]::ForegroundColor = [consolecolor]::Black
        [console]::BackgroundColor = [consolecolor]::DarkGray
        [console]::write("$($Items[$i].CreationTime.toString('ddMMMyy HH:mm:ss'))")
        [console]::resetColor()
        [console]::write(" ")
        [console]::ForegroundColor = [consolecolor]::Black
        [console]::BackgroundColor = [consolecolor]::DarkGray
        [console]::write("$($Items[$i].LastWriteTime.toString('ddMMMyy HH:mm:ss'))")
        [console]::resetColor()
      }
      if ($Items[$i].Attributes -match [system.io.fileattributes]::Directory) {
        [console]::ForegroundColor = [consolecolor]::Gray
        [console]::write(" $($Items[$i].Name)`n")
        [console]::resetColor()
      }
      else {
        [void]$this.writeSizeData($this.convertBytes($Items[$i].Length))
        [console]::ForegroundColor = $this.getColor($Items[$i].Extension)
        [console]::write("$($Items[$i].Name)`n")
        [console]::resetColor()
      }
    }
    if ((Get-Location).Path -match 'Microsoft\.PowerShell\.Core\\FileSystem::') {
      return "  $((Get-Location).Path.split(':')[2])`n"
    }
    else {
      return "  $((Get-Location).Path)`n"
    }
  }

  [int] WriteSizeData([string]$string)
  {
    switch ($string.Length) {
      2 { [console]::write("      $($string)  ") }
      3 { [console]::write("     $($string)  ")  }
      4 { [console]::write("    $($string)  ")   }
      5 { [console]::write("   $($string)  ")    }
      6 { [console]::write("  $($string)  ")     }
      7 { [console]::write(" $($string)  ")      }
      8 { [console]::write("$($string)  ")       }
      default {
        [console]::ForegroundColor = [consolecolor]::Red
        [console]::write(" SIZE_ERR ")
        [console]::resetColor()
      }
    }
    return 0
  }

  [string] ConvertBytes([int64]$length)
  {
    switch ($length) {
      {$_ -ge 1TB} { return "$([math]::round(($($_) / 1TB), 2))T" }
      {$_ -ge 1GB} { return "$([math]::round(($($_) / 1GB), 2))G" }
      {$_ -ge 1MB} { return "$([math]::round(($($_) / 1MB), 2))M" }
      {$_ -ge 1KB} { return "$([math]::round(($($_) / 1KB), 2))K" }
    }
    return "$([math]::round($length, 2))B"
  }

  [consolecolor] GetColor([string]$extension)
  {
    switch -regex ($extension) {
      ".(cs|csproj|sln|vbs)"                    { return [consolecolor]::Green     }
      ".(msi|msu|msp|zip)"                      { return [consolecolor]::DarkGreen }
      ".(dll|reg|xml|xaml|cfg)"                 { return [consolecolor]::DarkCyan  }
      ".(cmd|sh|exe|ini|dat|msc)"               { return [consolecolor]::Yellow    }
      ".(pdf|html|hta|docx|doc|md)"             { return [consolecolor]::Magenta   }
      ".(ps1|psm1|psd1|pson|ps1xml)"            { return [consolecolor]::Cyan      }
      ".(csv|json|log|toml|xlsx|xslt|yml|yaml)" { return [consolecolor]::Blue      }
    }
    return $this.Host.UI.RawUI.ForegroundColor
  }

  [bool] Dispose()
  {
    $this.Host = $null
    return $true
  }
}
