>Profile
#profile.ps[1|1xml|ini|m1|on]

enum Authority
{
  SYSTEM
  ADMIN
  USER
}

class TerminalColor
{
  <#
    STYLE     SEQ      RESET
    Bold      `e[1m - `e[22m
    Underline `e[4m - `e[24m
    Inverted  `e[7m - `e[27m
    ResetAll        - `e[0m
    Seq:
      `e[#A     moves cursor up # lines
      `e[#B	    moves cursor down # lines
      `e[#C	    moves cursor right # spaces
      `e[#D     moves cursor left # spaces
      `e[2J     clear screen and home cursor
      `e[K      clear to end of line
      `e[#(;#)m
      attributes
        0	normal display
        1	bold
        4	underline (mono only)
        5	blink on
        7	reverse video on
        8	nondisplayed (invisible)
      fore/back colors
        30;40	black
        31;41	red
        32;42	green
        33;43	yellow
        34;44	blue
        35;45	magenta
        36;46	cyan
        37;47	white
    Ref:
      https://duffney.io/usingansiescapesequencespowershell/
      https://bradwilson.io/blog/prompt/powershell/
      https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
  #>
  hidden [int[]]$Black   = (0  ,0  ,0  )
  hidden [int[]]$White   = (255,255,255)
  hidden [int[]]$Red     = (255,0  ,0  )
  hidden [int[]]$Lime    = (0  ,255,0  )
  hidden [int[]]$Blue    = (0  ,0  ,255)
  hidden [int[]]$Yellow  = (255,255,0  )
  hidden [int[]]$Cyan    = (0  ,255,255)
  hidden [int[]]$Magenta = (255,0  ,255)
  hidden [int[]]$Silver  = (192,192,192)
  hidden [int[]]$Gray    = (128,128,128)
  hidden [int[]]$Maroon  = (128,0  ,0  )
  hidden [int[]]$Olive   = (128,128,0  )
  hidden [int[]]$Green   = (0  ,128,0  )
  hidden [int[]]$Purple  = (128,0  ,128)
  hidden [int[]]$Teal    = (0  ,128,128)
  hidden [int[]]$Navy    = (0  ,0  ,128)
  hidden [int[]]$BaseScale16  = (0..15)
  hidden [int[]]$ColorScale24 = (16..231)
  hidden [int[]]$GrayScale24  = (232..255)
   
  TerminalColor() { }

  [void] ToConsole([int]$fgr, [int]$fgg, [int]$fgb, [int]$bgr, [int]$bgg, [int]$bgb, [string]$inputObject)
  {
    [console]::write("`e[48;2;$($fgr);$($fgg);$($fgb);38;2;$($bgr);$($bgg);$($bgb)m$($inputObject)`e[0m")
  }

  [void] ToConsole([int[]]$fgrgb, [int[]]$bgrgb, [string]$inputObject)
  {
    [console]::write("`e[48;2;$($fgrgb[0]);$($fgrgb[1]);$($fgrgb[2]);38;2;$($bgrgb[0]);$($bgrgb[1]);$($bgrgb[2])m$($inputObject)`e[0m")
  }

  [void] ToFgConsole([int]$r, [int]$g, [int]$b, [string]$inputObject)
  {
    [console]::write("`e[48;2;$($r);$($g);$($b)m$($inputObject)`e[0m")
  }

  [void] ToBgConsole([int]$r, [int]$g, [int]$b, [string]$inputObject)
  {
    [console]::write("`e[38;2;$($r);$($g);$($b)m$($inputObject)`e[0m")
  }

  [void] ToFgConsole([int[]]$rgb, [string]$inputObject)
  {
    [console]::write("`e[48;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m$($inputObject)`e[0m")
  }

  [void] ToBgConsole([int[]]$rgb, [string]$inputObject)
  {
    [console]::write("`e[38;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m$($inputObject)`e[0m")
  }

  [void] ToFgConsole([int]$color, [string]$inputObject)
  {
    [console]::write("`e[48;5;$($color)m$($inputObject)`e[0m")
  }

  [void] ToBgConsole([int]$color, [string]$inputObject)
  {
    [console]::write("`e[38;5;$($color)m$($inputObject)`e[0m")
  }

  [string] CenterString([string]$string, [int]$length)
  {
    return $string.padLeft([math]::round($length / 2 + [math]::round($string.Length / 2)))
  }

  [void] ShowColors()
  {
    [console]::writeLine("`e[1;4m    256-Color Charts    `e[0m")
    foreach ($i in 0..255) {
      [console]::write("`e[38;5;$($i)m$("$i".padLeft(4))`e[0m")
      if ((($i + 1) % 6) -eq 4) {
        [console]::writeLine("")
      }
    }
    foreach ($i in 0..255) {
      [console]::write("`e[48;5;$($i)m$("$i".padLeft(4))`e[0m")
      if ((($i + 1) % 6) -eq 4) {
        [console]::writeLine("")
      }
    }
  }
}

class Profile
{
  [object]$Configuration
  [system.collections.specialized.ordereddictionary]$Path
  [hashtable]$_ = [hashtable]::new()

  hidden [string]$Psm1Path = 'C:\_\__\profile.psm1'
  hidden [string]$PsonPath = 'C:\_\__\profile.pson'
  hidden [string]$Root = 'C:\_'
  hidden [object]$Authority
  hidden [bool]$IsDev = $false

  Profile([string]$root)
  {
    if (![string]::isNullOrEmpty($root)) {
      $this.Root = $root
    }
    $this.Authority = [system.security.principal.windowsprincipal]::new([system.security.principal.windowsidentity]::getCurrent())
    $this.Configuration = $this.importPson($this.PsonPath)
    Set-Location $this.Root
  }

  [void] SetAliases()
  {
    try {
      $Splat = @{
        'Scope' = 'Script'
        'Force' = $true
      }
      if (Get-Module -name 'Profile') {
        Set-Alias -name 'ls' -value Show-ChildItem -option 'AllScope' -scope 'Global' -force
        New-Alias @Splat -name 'exp'   -value Open-Explorer
        New-Alias @Splat -name 'pw'    -value Start-Console
        New-Alias @Splat -name 'use'   -value Use-Object
        New-Alias @Splat -name 'nap'   -value Suspend-Computer
        New-Alias @Splat -name 'touch' -value Select-Item
      }
      if (Get-Module -name 'SteamLocomotive') {
        Set-Alias -name 'sl' -value Start-SteamLocomotive -option 'AllScope' -scope 'Global' -force
      }
      if (Get-Command -name 'Micro.exe' -errorAction 'SilentlyContinue') {
        New-Alias @Splat -name 'edit' -value 'Micro.exe'
      }
      Set-Alias @Splat -name '^'   -value Select-Object
      Set-Alias @Splat -name '\'   -value Sort-Object
      Set-Alias @Splat -name 'smd' -value Show-Markdown
    }
    catch {
      throw $_
    }
  }

  [void] SetAuthority()
  { 
    try {
      if ($this.Authority.isInRole([system.security.principal.windowsbuiltinrole]::Administrator)) {
        if ($this.Authority.Identities.Name -eq 'NT AUTHORITY\SYSTEM') {
          $this.Authority = 0
        }
        else {
          $this.Authority = 1
        }
      }
      else {
        $this.Authority = 2
      }
    }
    catch {
      throw $_
    }
  }

  [void] SetConsole()
  {
    try {
      Set-PsReadlineKeyHandler -chord 'UpArrow' -scriptBlock {
        [microsoft.powershell.psconsolereadline]::historySearchBackward()
        [microsoft.powershell.psconsolereadline]::endOfLine()
        #[microsoft.powershell.psconsolereadline]::endOfLine()
      }
      Set-PsReadlineKeyHandler -chord 'Ctrl+UpArrow'    -function 'HistorySearchBackward'
      Set-PsReadLineKeyHandler -chord 'Ctrl+DownArrow'  -function 'HistorySearchForward'
      Set-PsReadlineKeyHandler -chord 'Ctrl+RightArrow' -function 'PossibleCompletions'
      Set-PsReadlineOption -colors @{
        Command  = 'Gray'
        Number   = 'Yellow'
        Variable = 'DarkGreen'
        Comment  = 'Cyan'
      }
      Set-PsReadlineOption -bellStyle 'None'
      Set-PsReadlineOption -continuationPrompt '     '
      Set-PsReadlineOption -promptText ([char]0x00A0)
      $script:Host.PrivateData.DebugForegroundColor    = [consolecolor]::Black
      $script:Host.PrivateData.DebugBackgroundColor    = [consolecolor]::DarkGreen
      $script:Host.PrivateData.ErrorForegroundColor    = [consolecolor]::DarkRed
      $script:Host.PrivateData.ErrorBackgroundColor    = [consolecolor]::Black
      $script:Host.PrivateData.ProgressForegroundColor = [consolecolor]::Black
      $script:Host.PrivateData.ProgressBackgroundColor = [consolecolor]::DarkCyan
      $script:Host.PrivateData.VerboseForegroundColor  = [consolecolor]::Black
      $script:Host.PrivateData.VerboseBackgroundColor  = [consolecolor]::DarkGray
    }
    catch {
      throw $_
    }
  }

  [void] SetEnvironment()
  {
    try {
      New-PsDrive -name 'Steam' -scope 'Global' -psProvider 'FileSystem' -root 'D:\Steam\steamapps\common\' -errorAction 'Continue'
      New-PsDrive -name 'WSL' -scope 'Global' -psProvider 'FileSystem' -root '\\wsl$\Debian\' -errorAction 'Continue'
      $env:Path = $env:Path + ';' + ($this.Configuration.Environment.Path -join ';')
      $env:PsModulePath = $env:PsModulePath + ';' + ($this.Configuration.Environment.PsModulePath -join ';')
    }
    catch {
      throw $_
    }
  }

  hidden [void] ImportModules()
  {
    try {
      Import-Module -name $this.Psm1Path -errorAction 'Continue'
      Import-Module -name 'C:\_\Projects\SteamLocomotive\SteamLocomotive.psm1' -errorAction 'Continue'
    }
    catch {
      throw $_
    }
  }

  [object] ImportPson([string]$path)
  {
    try {
      $File = [system.io.file]::readAllLines($path)
      return @($File.foreach({ if ($_.trim() -notMatch '^//') { $_ } })) -join "`n" | ConvertFrom-Json -errorAction 'Continue'
    }
    catch {
      throw $_
    }
  }

  [void] OverrideCmdlet([string]$cmdletName, [scriptblock]$begin, [scriptblock]$process, [scriptblock]$end)
  {
    try {
      $Cmdlet = Get-Command -name $cmdletName -commandType 'cmdlet'
      $Cmdlet = [system.management.automation.proxycommand]::create([system.management.automation.commandmetadata]::new($Cmdlet))
      $Cmdlet = $Cmdlet -replace 'begin\s*\{\s*try\s*\{', ("`$0`n" + ("$($begin)" -replace '\$', '$$$$'))
      $Cmdlet = $Cmdlet -replace 'process\s*\{\s*try\s*\{', ("`$0`n" + ("$($process)" -replace '\$', '$$$$'))
      $Cmdlet = $Cmdlet -replace 'end\s*\{\s*try\s*\{', ("`$0`n" + ("$($end)" -replace '\$', '$$$$'))
      Set-Item -path "Function:Global:$($Cmdlet)" -value $Cmdlet
    }
    catch {
      throw $_
    }
  }

  hidden [string] CompressPath([string]$path)
  {
    $Return = $path -replace $global:HOME.replace('\', '\\'), '~'
    $Return = $Return -replace '^[^:]+::', ''
    $Return = $Return -replace '\\(\.?)([^\\])[^\\]*(?=\\)', '\$1$2'
    return $Return
  }

  [void] StartExplorer()
  {
    [system.diagnostics.process]::start('explorer.exe', (Get-Location).Path)
  }

  [void] WriteAuthority([bool]$consoleWide)
  {
    switch ($this.Authority) {
      0 {
        [console]::BackgroundColor = [consolecolor]::Magenta
        [console]::ForegroundColor = [consolecolor]::Black
        if ($consoleWide) {
          [console]::writeLine(' //SYSTEM'.padRight([console]::BufferWidth))
        }
        else {
          [console]::write(' SYSTEM ')
        }
      }
      1 {
        [console]::BackgroundColor = [consolecolor]::DarkRed
        [console]::ForegroundColor = [consolecolor]::Black
        if ($consoleWide) {
          [console]::writeLine(' //ADMIN'.padRight([console]::BufferWidth))
        }
        else {
          [console]::write(' ADMIN ')
        }
      }
      2 {
        [console]::BackgroundColor = [consolecolor]::DarkGreen
        [console]::ForegroundColor = [consolecolor]::Black
        if ($consoleWide) {
          [console]::writeLine(' //USER'.padRight([console]::BufferWidth))
        }
        else {
          [console]::write(' USER ')
        }
      }
      default {
        [console]::BackgroundColor = [consolecolor]::DarkGray
        [console]::ForegroundColor = [consolecolor]::Black
        if ($consoleWide) {
          [console]::writeLine(' //UNK!'.padRight([console]::BufferWidth))
        }
        else {
          [console]::write(' UNK! ')
        }
      }
    }
    [console]::resetColor()
  }

  [void] WriteSystemInfo()
  {
    [console]::ForegroundColor = [consolecolor]::White
    [console]::write("psv$($global:PsVersionTable.PsVersion.toString())")
    [console]::write(" rpv$($global:PsVersionTable.PsRemotingProtocolVersion.toString())")
    [console]::write(" wsv$($global:PsVersionTable.WSManStackVersion.toString()) - ")
    [console]::ForegroundColor = [consolecolor]::Gray
    [console]::write("$([system.environment]::UserName)")
    [console]::ForegroundColor = [consolecolor]::DarkGray
    [console]::write('@')
    [console]::ForegroundColor = [consolecolor]::Gray
    try {
      [console]::writeLine("$([system.environment]::MachineName.toLower()).$($env:UserDnsDomain.toLower())")
    }
    catch {
      [console]::writeLine("$([system.environment]::MachineName.toLower())")
    }
    [console]::resetColor()
  }
}

try {
  $___ = [profile]::new($null)
  $___.importModules()
  $___.setEnvironment()
  $___.setAliases()
  $___.setAuthority()
  $___.setConsole()

  function Start-Adm { Start-Process 'c:\_\__\pwsh\pwsh.exe' -verb 'runas' }
  
  function Prompt() {
    try {
      $___.writeAuthority($false)
      if ($___.IsDev) {
        [console]::ForegroundColor = [consolecolor]::Black
        [console]::BackgroundColor = [consolecolor]::Magenta
        [console]::write(' Dev ')
        [console]::resetColor()
      }
      [console]::ForegroundColor = [consolecolor]::Blue
      [console]::write('[')
      [console]::ForegroundColor = [consolecolor]::DarkCyan
      [console]::write($___.compressPath((Get-Location).Path))
      [console]::ForegroundColor = [consolecolor]::Blue
      [console]::write(']')
      [console]::ForegroundColor = [consolecolor]::Black
      [console]::resetColor()
      return ([char]0x00A0)
    }
    catch {
      [console]::resetColor()
      return ([char]0x00A0)
    }
  }
}
finally {
  #Nothing...
}
>profileMS1
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

function Format-Code {
  [cmdletbinding()]
  param(
      [parameter(valuefrompipeline)]
    [object]$InputObject
  )
  begin {
    $Return = [system.text.stringbuilder]::new()
  }
  process {
    if ($_) {
      [void]$Return.appendLine($_.replace("`r`r", "`r").replace("`r`n`r`n", "`r`n").replace("`t", '  '))
    }
    else {
      foreach ($Object in $InputObject) {
        [void]$Return.appendLine($Object.replace("`r`r", "`r").replace("`r`n`r`n", "`r`n").replace("`t", '  '))
      }
    }
  }
  end {
    return $Return.toString()
  }
}

function Invoke-Serializer {
  [cmdletbinding()]
  param(
    [parameter(valuefrompipeline)]
    [object]$InputObject,
    [switch]$Deserialize
  )
  process {
    if ($Deserialize) {
      $Return = [system.management.automation.psserializer]::deserialize($InputObject)
    }
    else {
      $Return = [system.management.automation.psserializer]::serialize($InputObject)
    }
  }
  end {
    return $Return
  }
}

function Format-Json {
  [cmdletbinding()]
  param(
      [parameter(valuefrompipeline)]
    [object]$InputObject
  )
  $Indent = 0
  ($InputObject -split '\n' | Foreach-Object {
    if ($_ -match '[\}\]]') {
      $Indent--
    }
    $Line = (' ' * $Indent * 2) + $_.trimStart()
    if ($_ -match '[\{\[]') {
      $Indent++
    }
    $Line
  }) -join "`n"
}

function Use-Object {
  [cmdletbinding()]
  param(
    [object]$InputObject,
    [scriptblock]$ScriptBlock
  )
  process {
    try {
      . $ScriptBlock
    }
    catch {
      throw $_
    }
    finally {
      if ($InputObject -is [system.isdisposable]) {
        $InputObject.dispose()
      }
    }
  }
}

function Get-PublicIPv4 {
  [cmdletbinding()]
  param(
    [string]$SearchString = 'Current IP Address: (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
  )
  return [pscustomobject]@{"IPv4" = (curl -s 'http://checkip.dyndns.org' | Select-String $SearchString).Matches.Groups[1].Value}
}

function Open-Explorer {
  [void][system.diagnostics.process]::start("explorer.exe", (Get-Location).Path)
}

function ConvertFrom-Ini {
  [cmdletbinding()]
  param(
    [parameter(valuefrompipeline)]
    [string[]]$InputObject
  )
  begin {
    $Return = [system.collections.hashtable]::new()
    $Return['_Comment'] = [system.collections.hashtable]::new()
    $C = 0
  }
  process {
    for ($i = 0; $i -lt $InputObject.Count; $i++) {
      switch -regex ($InputObject[$i]) {
        '^\[(.+)\]$' {
          $Section = $matches[1]
          $Return[$Section] = [system.collections.hashtable]::new()
        }
        '^(;.*)$' {
          $Key = "Comment_$($C)"
          $Return['_Comment'][$Key] = $matches[1]
          $C++
        }
        '(.+?)\s*=\s*(.*)' {
          if (!$Section) {
            $Section = '_NoSection'
          }
          $Return[$Section][$matches[1]] = $matches[2]
        }
      }
    }
  }
  end {
    return $Return
  }
}

function ConvertTo-Ini {
  [cmdletbinding()]
  param(
    [parameter(valuefrompipeline)]
    [hashtable]$InputObject
  )
  $Return = [system.io.stringwriter]::new()
  foreach ($Key in $InputObject.Keys) {
    if (!($InputObject[$Key].getType() -is [hashtable])) {
      $Return.writeLine("$($Key)=$($InputObject[$Key])")
    }
    else {
      $Return.writeLine("`n[$($Key)]")
      foreach ($SubKey in ($InputObject[$Key].Keys | Sort-Object)) {
        if ($SubKey -match '^Comment[\d]+') {
          $Return.writeLine("$($InputObject[$Key][$SubKey])")
        }
        else {
          $Return.writeLine("$($SubKey)=$($InputObject[$Key][$SubKey])")
        }
      }
    }
  }
  return $Return.toString()
}

function Import-CSharp {
  [cmdletbinding()]
  param(
    [string]$TypeDefinition
  )
  Add-Type -typeDefinition $TypeDefinition -language 'CSharp'
  [regex]::matches($TypeDefinition, 'namespace\s(.*)|class\s(.*)').Value
}

function Convert-JDCode {
  param(
    [parameter(valuefrompipeline)]
    [string]$InputString
  )
  return [regex]::replace($InputString, '\/\*.*\*\/\s', '')
}

function Optimize-JDCode {
  param(
    [string]$Path
  )
  try {
    $Items = Get-ChildItem -path $Path -recurse -filter '*.java' -errorAction 'Stop'
    $Items.FullName.foreach({
      Get-Content $_ -raw | Convert-JDCode | Set-Content $_
      [console]::writeLine($_)
    })
  }
  catch {
    throw $_
  }
}

function Convert-CleanString {
  param(
    [string]$InputString
  )
  $StringBuilder = [system.text.stringbuilder]::new($InputString)
  $StringBuilder.replace("`n", ' ')
  $StringBuilder.replace("`r", ' ')
  $StringBuilder.replace("`t", ' ')
  return $StringBuilder.toString()
}

function Get-DateTimeDiff {
  [cmdletbinding()]
  param(
    [validatepattern('\d{2}:\d{2}:\d{2}')]
    [string]$From,
    [validatepattern('\d{2}:\d{2}:\d{2}')]
    [string]$To,
    [bool]$SameDay = $false
  )
  $DTStart = [datetime]$From
  $DTEnd   = [datetime]$To
  if ($SameDay) {
    $DTEnd = $DTEnd.addDays(0)
  }
  else {
    $DTEnd = $DTEnd.addDays(1)
  }
  return (New-TimeSpan -start $DTStart -end $DTEnd) -join "$($_.Hours):$($_.Minutes):$($_.Seconds)"
}

function Find-ComObjects {
  $ComObjects = (Get-ChildItem 'HKLM:\Software\Classes').where({
    $_.PsChildName -match '^\w+\.\w+$' -and (Test-Path -path "$($_.PsPath)\CLSID")
  }).PsChildName
  <#
    if ($Filter) {
      return $ComObjects.where({ $_ -like $Pattern })
    }
    if ($Pattern) {
      return $comObjects.where({ $_ -match $Filter})
    }
  #>
  return $ComObjects
}

function Suspend-Computer {
  [void][system.reflection.assembly]::loadWithPartialName('System.Windows.Forms')
  [system.windows.forms.application]::setSuspendState('Hibernate', $false, $false)
}

function Get-DisplayDimensions {
  Get-CimInstance -namespace 'root\wmi' -class WmiMonitorBasicDisplayParams `
    | Select-Object `
      @{ N="Computer"; E={$_.__SERVER} },
      InstanceName,
      @{ N="Horizonal"; E={[System.Math]::Round(($_.MaxHorizontalImageSize/2.54), 2)} },
      @{ N="Vertical"; E={[System.Math]::Round(($_.MaxVerticalImageSize/2.54), 2)} },
      @{N="Size"; E={[System.Math]::Round(([System.Math]::Sqrt([System.Math]::Pow($_.MaxHorizontalImageSize, 2) + [System.Math]::Pow($_.MaxVerticalImageSize, 2))/2.54),2)} },
      @{N="Ratio";E={[System.Math]::Round(($_.MaxHorizontalImageSize)/($_.MaxVerticalImageSize),2)}}
}

function Write-LineBreak {
  Write-Host "".padRight($host.UI.RawUI.WindowSize.Width) -background 'Yellow'
}

function Select-Item {
  [cmdletbinding()]
  param(
    [parameter(mandatory)]
    [string]$FilePath
  )
  if (Test-Path $FilePath) {
    (Get-ChildItem $FilePath).LastWriteTime = Get-Date
  }
  else {
    New-Item -path $FilePath
  }
}
>PSON
// PSON Configuration File
{
  "PsRoot": "C:\\_",
  "Environment": {
    "Path": [
      "C:\\_\\__",
      "C:\\_\\__\\micro",
      "C:\\_\\Binaries\\jd-gui-windows-1.6.6",
      "C:\\_\\Binaries\\ngrok-v3-stable-windows-amd64",
      "C:\\_\\Binaries\\ponyc-x86-64-pc-windows-msvc\\bin",
      "C:\\_\\Binaries\\ookla-speedtest-1.0.0-win64",
      "C:\\_\\Binaries\\Sandboxie-Plus",
      "C:\\Program Files\\qemu",
      "C:\\Program Files\\dotnet",
      "C:\\Windows\\System32\\OpenSSH"
    ],
    "PsModulePath": [
      "C:\\_",
      "C:\\_\\Modules",
      "C:\\PwSh\\Modules"
    ]
  },
  "Variables": {
    "ConfirmPreference": "High",
    "DebugPreference": "SilentlyContinue",
    "DOTNET_CLI_TELEMETRY_OPTOUT": true,
    "ErrorPreference": "Continue",
    "ErrorView": "NormalView",
    "ProgressPreference": "Continue",
    "VerbosePreference": "SilentlyContinue",
    "WarningPreference": "Continue",
    "WhatIfPreference": false
  },
  "Custom": [
    {
      "PlaceHolder_CustomVariable": {
        "Variable": "One",
        "Variable": "Two"
      }
    }
  ]
}
#PARALLLE
<#
  Synopsis:
    Runs scriptblock in parallel with granular control over input, output, and processing.
  Description:

  Contact:
    Caleb Worthington (Ktufuathama) https://github.com/Ktufuathama
  Version:
    v.0.A - 06OCT17 - PreRelease Testing
    v.1.0 - 12OCT17 - InitialRelease
    v.2.0 - 13OCT17 - Rework (Error handling, Runtime, Logging, Progressbar)
    v.2.1 - 01OCT17 - Fix (Time_Catch removed)
    v.2.2 - 15NOV17 - Added (Start-Time, fixed runtimekill and limit)
    v.3.0 - 27NOV18 - Rework (Threshold, new logging, Optimization)
    v.3.1 - 14DEC18 - Added decription and some code cleanup.
    v.3.2 - 18MAR19 - Grammer fixes.
    v.3.3 - 11JUN19 - More Grammer and formatting fixes.
    v.4.0 - 21NOV19 - Moved all logic to class with wrapper function.
    v.4.1 - 03DEC19 - Add RuntimeLimit (broken in implimentation), CtrlC will cancel remaining executions.
  Parameters:
    InputScript - Script to execute {scriptblock}.
    InputObject - Object to run in parallel.
    InputParam - ParameterName to assign the current InputObject. 'ComputerName'
    Parameters - Hashtable of additional parameters. @{Class = 'win32_product'}
    Throttle - Max number of simultaneous running executions.
    Threshold - Max number of staged/loaded executions at anytime.
    RuntimeLimit - One limit is hit, all remain executions are cancelled.
    Quiet - Suppress progressbar.
    Raw - Execution output is sent to pipeline instead of stored in [Parallel] instance.
  Input:
    No Pipeline support, parameters only.
  Output:
    If '-raw' is passed, will return scriptblock output.
    If '-raw' is not passed, will return [Parallel] class object.
  Examples:
    Invoke-Parallel -inputScript 'param($CN); Do-Thing -host $CN' -inputObject [array]$List -inputParam 'CN'
  ToDo:
    Reserve Threads for working operation (Suspend at timeout, run after rest of queue.)
    Emergency shutdown without shell closure. (Using Handles or Runspace distruction?)
    Allow threads to share data. (SynchronizedHashtable?)
#>
function Invoke-Parallel {
  [cmdletbinding()]
  param(
    [string]$InputScript,
    [object[]]$InputObject,
    [string]$InputParam,
    [hashtable]$Parameters = @{},
    [int]$Throttle = [int]$env:NUMBER_OF_PROCESSORS,
    [int]$Threshold = ([int]$env:NUMBER_OF_PROCESSORS * 2),
    [double]$RuntimeLimit = 10,
    [switch]$Quiet,
    [switch]$Raw
  )
  $Parallel = [parallel]::new()
  $Parallel.PassThru  = $Raw
  $Parallel.Throttle  = $Throttle
  $Parallel.Threshold = $Threshold
  $Parallel.RuntimeLimit = $RuntimeLimit
  $Parallel.CycleTime = $CycleTime
  $Parallel.Progress  = !$Quiet
  $Parallel.invokeParallel($InputScript, $InputObject, $InputParam, $Parameters)
  if ($Raw) {
    $Parallel.dispose()
    return
  }
  return $Parallel
}

class Parallel
{
  
  [system.collections.hashtable]$Results = [system.collections.hashtable]::new()
  [system.collections.arraylist]$Errors  = [system.collections.arraylist]::new()

  <#ToDo - Allow threads to share data.
    [system.collections.hashtable]$global:Sync = [system.collections.hashtable]::synchronized(
      [system.collections.hashtable]::new())
  #>

  [int]$Throttle  = 10
  [int]$Threshold = 100
  [int]$CycleTime = 200
  [double]$RuntimeLimit = 10
  [bool]$Verbose  = $false
  [bool]$Progress = $true
  [bool]$Debug    = $false
  [bool]$PassThru = $false

  hidden [datetime]$InitTime
  hidden [int]$ExecutionId
  hidden [int]$InputObjectCount
  hidden [int]$StagedCount
  hidden [int]$CompletedCount
  hidden [system.management.automation.runspaces.runspacepool]$Pool
  hidden [system.collections.arraylist]$Executions = [system.collections.arraylist]::new()
  hidden [system.collections.queue]$Queue = [system.collections.queue]::new()

  InvokeParallel(
    [object[]]$InputObject,
    [string]$InputParam,
    [hashtable]$Parameters,
    [string]$InputScript)
  {
    try {
      $this.InitTime = [datetime]::Now
      $this.writeVerbose("Operation Started!")
      [console]::TreatControlCAsInput = $true
      $this.Pool = [system.management.automation.runspaces.runspacefactory]::createRunspacePool(1, $this.Throttle)
      $this.Pool.ApartmentState = 'MTA'
      $this.Pool.open()
      $this.Results.clear()
      $this.InputObjectCount = $InputObject.Count
      $this.StagedCount = 0
      $this.CompletedCount = 0
      $this.ExecutionId = 0
      $this.writeDebug("Prestaged")
      for ($I = 0; $I -lt $InputObject.Count; $I++) {
        $this.writeVerbose("[$($I + 1)] Execution Started")
        $this.writeProgress(0)
        $this.invokeExecution($InputScript, $InputObject[$I], $InputParam, $Parameters)
        $this.StagedCount++
        $this.wait($this.Threshold, 1)
      }
      $this.writeDebug("Poststaged")
      $this.wait(0, 0)
    }
    catch {
      $this.Errors.add($_)
    }
    finally {
      $this.writeProgress(1)
      $this.writeDebug("Executions Finshed.")
      $this.Pool.close()
      $this.Pool.dispose()
      [console]::TreatControlCAsInput = $false
      $this.writeVerbose("Operation Finished!")
    }
  }

  hidden InvokeExecution(
    [string]$InputScript,
    [object]$InputObject,
    [string]$InputParam,
    [hashtable]$Parameters)
  {
    try {
      $Execution = [powershell]::create()
      $Execution.addScript($InputScript, $true)
      $Execution.addParameter($InputParam, $InputObject)
      foreach ($Key in $Parameters.Keys) {
        $Execution.addParameter($Key, $Parameters.$Key)
      }
      $Execution.RunspacePool = $this.Pool
      $Return = [system.management.automation.psdatacollection[psobject]]::new()
      $this.ExecutionId++
      $this.Executions.add([pscustomobject]@{
        Id        = $this.ExecutionId
        StartTime = [datetime]::Now
        Handle    = $Execution.beginInvoke($Return, $Return)
        Execution = $Execution
        Object    = $InputObject.toString()
        Return    = $Return
      })
    }
    catch {
      $this.Errors.add($_)
    }
  }

  Wait([int]$Threshold, [int]$Offset)
  {
    try {
      while ($this.Executions.Count -gt ($Threshold - $Offset)) {
        $this.writeProgress(0)
        $Key = $null
        if ($global:Host.UI.RawUI.KeyAvailable -and ($Key = $global:Host.UI.RawUI.readKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
          if ([int]$Key.Character -eq 3) {
            for ($I = 0; $I -lt $this.Executions.Count; $I++) {
              $this.Executions[$I].Return = "Cancelled:UserAction"
              $this.Executions[$I].Execution = $null
              $this.returnResults($I)
              $this.Queue.enqueue($this.Executions[$I])
              $this.CompletedCount++
            }
          }
          $global:Host.UI.RawUI.flushInputBuffer()
        }
        for ($I = 0; $I -lt $this.Executions.Count; $I++) {
          if ($this.Executions[$I].StartTime.addMinutes($this.RuntimeLimit) -lt $([datetime]::Now)) {
            $this.Executions[$I].Return = "Cancelled:ExceededRuntime"
            $this.Executions[$I].Execution = $null
            $this.returnResults($I)
            $this.Queue.enqueue($this.Executions[$I])
            $this.CompletedCount++
          }
          if ($this.Executions[$I].Handle.IsCompleted -eq $true) {
            $this.writeVerbose("[$($this.Executions[$I].Id)] Execution Completed")
            $this.Executions[$I].Execution.endInvoke($this.Executions[$I].Handle)
            $this.Executions[$I].Execution.dispose()
            $this.returnResults($I)
            $this.Queue.enqueue($this.Executions[$I])
            $this.CompletedCount++
          }
        }
        while ($this.Queue.Count -gt 0) {
          $this.Executions.remove($this.Queue.dequeue())
        }
        Start-Sleep -milliseconds $this.CycleTime
      }
    }
    catch {
      $this.Errors.add($_)
    }
  }

  ReturnResults([int]$I)
  {
    if ($this.PassThru) {
      Out-Host -inputObject @{
        $this.Executions[$I].Object = $this.Executions[$I].Return
      }
    }
    else {
      if ($this.Debug) {
        $this.Results.add($this.Executions[$I].Object, $this.Executions[$I])
      }
      else {
        $this.Results.add($this.Executions[$I].Object, $this.Executions[$I].Return)
      }
    }
  }

  WriteVerbose([string]$Message)
  {
    $Splat = @{
      #Message = "$(([datetime]::Now - $this.InitTime).toString().subString(0, 11)) $($Message)"
      Message = "$($Message)"
      Verbose = $this.Verbose
    }
    Write-Verbose @Splat
  }

  WriteDebug([string]$Message)
  {
    $Splat = @{
      #Message = "$(([datetime]::Now - $this.InitTime).toString().subString(0, 11)) $($Message)"
      Message = "$($Message)"
      Debug = $this.Debug
    }
    Write-Debug @Splat
  }

  WriteProgress([int]$Code)
  {
    if ($this.Progress) {
      switch ($Code) {
        0 {
          $1 = $([datetime]::Now - $this.InitTime).toString().split('.')[0]
          $2 = "$($this.CompletedCount)/$($this.StagedCount)/$($this.InputObjectCount)"
          $3 = (($this.Throttle - $this.Pool.getAvailableRunspaces()) / $this.Throttle * 100)
          $4 = "/$($this.Throttle)/$($this.Threshold)/$($this.CycleTime)ms"
          Write-Progress -activity "$($1) - $($2) [$($3)%$($4)]"
        }
        1 {
          $1 = $([datetime]::Now - $this.InitTime).toString().split('.')[0]
          Write-Progress -activity "$($1) - Disposing Executions..."
        }
      }
    }
  }

  [bool] Dispose() {
    $this.Errors.clear()
    $this.Results.clear()
    $this.Pool = $null
    return $true
  }
}
