using namespace System.Net;
using namespace System.IO;

class WF_WebRequest
{
  [webrequest]$Request
  [httpwebresponse]$Response
  [system.io.stream]$DataStream
  [system.io.streamreader]$Reader
  [object]$Html
  [bool]$IsClosed = $false
  [string]$Status

  hidden [string]$ResponseString

  WF_WebRequest() { }

  [string]GetWebResponse([string]$uri)
  {
    $this.create($uri)
    [void]$this.connect()
    [void]$this.read()
    [void]$this.write()
    [void]$this.close()
    return $this.ResponseString
  }

  [void] Create([string]$uri)
  {
    $this.IsClosed = $true
    $this.Request = [webrequest]::create($uri)
    $this.Request.Credentials = [credentialcache]::DefaultCredentials
  }

  [string] Connect()
  {
    $this.Response = $this.Request.getResponse()
    $this.Status = $this.Response.StatusDescription
    return $this.Response.StatusDescription
  }

  [string] Read()
  {
    $this.DataStream = $this.Response.getResponseStream()
    $this.Reader = [streamreader]::new($this.DataStream)
    $this.ResponseString = $this.Reader.readToEnd()
    return $this.ResponseString
  }

  [object] Write()
  {
    $this.Html = New-Object -com 'HtmlFile'
    $this.Html.write([ref]$this.ResponseString)
    return $this.Html
  }

  [bool] Close()
  {
    try {
      $this.Reader.close()
      $this.DataStream.close()
      $this.Response.close()
      $this.IsClosed = $true
      return $true
    }
    catch {
      return $false
    }
  }

  [void] Dispose()
  {
    if ($this.IsClosed -eq $false) {
      $this.close()
    }
    [system.runtime.interopservices.marshal]::releaseComObject($this.Html)
    $this.Html = $null
  }
}
