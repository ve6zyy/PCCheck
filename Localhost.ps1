# Localhost.ps1 - small HTTP file server serving C:\Temp\Dump
param(
    [int]$Port = 8080,
    [string]$WebRoot = "C:\Temp\Dump",
    [int]$TimeoutHours = 2
)

Add-Type -AssemblyName System.Net.HttpListener
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    Write-Error "Failed to start HTTP listener on $prefix. Try running as Administrator or pick another port."
    exit 1
}
$startTime = Get-Date
Write-Host "Local HTTP server started at $prefix serving $WebRoot"

while ($listener.IsListening) {
    if ((Get-Date) -gt $startTime.AddHours($TimeoutHours)) { break }
    try {
        $context = $listener.GetContext()
    } catch {
        break
    }
    $request = $context.Request
    $response = $context.Response

    $relativePath = ($request.Url.AbsolutePath.TrimStart('/'))
    if ($relativePath -eq "") { $relativePath = "Viewer.html" }
    $localPath = Join-Path $WebRoot $relativePath

    if (Test-Path $localPath) {
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
        switch ($ext) {
            '.html' { $response.ContentType = "text/html" }
            '.css'  { $response.ContentType = "text/css" }
            '.js'   { $response.ContentType = "application/javascript" }
            '.csv'  { $response.ContentType = "text/csv" }
            default { $response.ContentType = "application/octet-stream" }
        }
        $buf = [System.IO.File]::ReadAllBytes($localPath)
        $response.ContentLength64 = $buf.Length
        $response.OutputStream.Write($buf, 0, $buf.Length)
    } else {
        $response.StatusCode = 404
        $err = "File not found: $relativePath"
        $data = [System.Text.Encoding]::UTF8.GetBytes($err)
        $response.OutputStream.Write($data, 0, $data.Length)
    }
    $response.Close()
}

$listener.Stop()
Write-Host "Local HTTP server stopped."
