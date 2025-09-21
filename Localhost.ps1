param([int]$Port=8080,[string]$Root="C:\Temp\Dump")

Add-Type -AssemblyName System.Net.HttpListener
$listener = New-Object Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root on http://localhost:$Port/"

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $file = Join-Path $Root ($ctx.Request.Url.AbsolutePath.TrimStart('/') -replace '/','\')
    if (-not $file -or -not (Test-Path $file)) { $file = Join-Path $Root "Viewer.html" }
    $bytes = [IO.File]::ReadAllBytes($file)
    $ctx.Response.ContentType = "text/html"
    $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    $ctx.Response.Close()
}
