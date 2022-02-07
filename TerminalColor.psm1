<#
  STYLE     SEQ      RESET
  Bold      `e[1m - `e[22m
  Underline `e[4  - `e[24m
  Inverted  `e[7m - `e[27m
  ResetAll        - `e[0m
  Ref:
    https://duffney.io/usingansiescapesequencespowershell/
    https://bradwilson.io/blog/prompt/powershell/
#>

class TerminalColor
{
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

  [hashtable]$Colors = @{
    'Black'   = (0  ,0  ,0  )
    'White'   = (255,255,255)
    'Red'     = (255,0  ,0  )
    'Lime'    = (0  ,255,0  )
    'Blue'    = (0  ,0  ,255)
    'Yellow'  = (255,255,0  )
    'Cyan'    = (0  ,255,255)
    'Magenta' = (255,0  ,255)
    'Silver'  = (192,192,192)
    'Gray'    = (128,128,128)
    'Maroon'  = (128,0  ,0  )
    'Olive'   = (128,128,0  )
    'Green'   = (0  ,128,0  )
    'Purple'  = (128,0  ,128)
    'Teal'    = (0  ,128,128)
    'Navy'    = (0  ,0  ,128)
  }
  [int[]]$BaseScale16  = (0..15)
  [int[]]$ColorScale24 = (16..231)
  [int[]]$GraysScale24 = (232..255)
   

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
