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
    Write-Host $this.connect()
    [void]$this.read()
    $this.close()
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
    $this.Html = New-Object -com 'HtmlFile'
    $this.DataStream = $this.Response.getResponseStream()
    $this.Reader = [streamreader]::new($this.DataStream)
    $this.ResponseString = $this.Reader.readToEnd()
    $this.Html.write([ref]$this.ResponseString)
    return $this.ResponseString
  }

  [void] Close()
  {
    $this.Reader.close()
    $this.DataStream.close()
    $this.Response.close()
    $this.IsClosed = $true    
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
