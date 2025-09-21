param([int]$Port=8080,[string]$WebRoot="C:\Temp\Dump",[int]$TimeoutHours=2)
Add-Type -AssemblyName System.Net.HttpListener
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
try { $listener.Start() } catch { Write-Error "Cannot start listener on $prefix: $_"; exit 1 }
$start = Get-Date
Write-Host "Serving $WebRoot on $prefix"
while ($listener.IsListening) {
    if ((Get-Date) -gt $start.AddHours($TimeoutHours)) { break }
    try { $context = $listener.GetContext() } catch { break }
    $req = $context.Request; $res = $context.Response
    $path = $req.Url.AbsolutePath.TrimStart('/')
    if ($path -eq "") { $path = "Viewer.html" }
    $file = Join-Path $WebRoot $path
    if (Test-Path $file) {
        $res.Headers.Add("Access-Control-Allow-Origin","*")
        $ext = [IO.Path]::GetExtension($file).ToLower()
        switch ($ext) { '.html'{$res.ContentType='text/html'} '.css'{$res.ContentType='text/css'} '.js'{$res.ContentType='application/javascript'} '.csv'{$res.ContentType='text/csv'} default{$res.ContentType='application/octet-stream'} }
        $bytes = [IO.File]::ReadAllBytes($file)
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
        $res.StatusCode = 404
        $msg = "Not found: $path"
        $b = [Text.Encoding]::UTF8.GetBytes($msg)
        $res.OutputStream.Write($b,0,$b.Length)
    }
    $res.Close()
}
$listener.Stop()
Write-Host "Server stopped"
