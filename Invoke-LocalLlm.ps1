[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Prompt = "Reply with the single word OK.",

    [Parameter(Mandatory = $false)]
    [string]$Endpoint = $(if ($env:LLM_ENDPOINT) { $env:LLM_ENDPOINT } else { "http://172.22.1.59:11434" }),

    [Parameter(Mandatory = $false)]
    [string]$Model = $(if ($env:LLM_MODEL) { $env:LLM_MODEL } else { "llama3.2:1b" }),

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSec = 60,

    [Parameter(Mandatory = $false)]
    [int]$MaxOutputChars = 2000
)

$ErrorActionPreference = "Stop"
$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir "caller.jsonl"

$systemPolicy = "You are a constrained local test agent. Follow the user prompt. Do not request additional tools. Do not invent credentials."

$bodyObject = @{
    model  = $Model
    prompt = $Prompt
    system = $systemPolicy
    stream = $false
}
$body = $bodyObject | ConvertTo-Json -Compress

$started = Get-Date
$ok = $false
$errorText = $null
$responseText = $null

try {
    $response = Invoke-RestMethod -Uri "$Endpoint/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSec
    $responseText = [string]$response.response
    if ([string]::IsNullOrWhiteSpace($responseText)) {
        throw "Empty model response"
    }
    if ($responseText.Length -gt $MaxOutputChars) {
        $responseText = $responseText.Substring(0, $MaxOutputChars)
    }
    $ok = $true
}
catch {
    $errorText = $_.Exception.Message
}

$ended = Get-Date
$durationMs = [int]($ended - $started).TotalMilliseconds

$log = [ordered]@{
    timestamp     = $started.ToString("o")
    endpoint      = $Endpoint
    model         = $Model
    prompt_chars  = $Prompt.Length
    output_chars  = $(if ($responseText) { $responseText.Length } else { 0 })
    duration_ms   = $durationMs
    success       = $ok
    error         = $errorText
}
($log | ConvertTo-Json -Compress) | Add-Content -Path $logFile

if (-not $ok) {
    Write-Error "LLM call failed: $errorText"
    exit 1
}

Write-Output $responseText
exit 0