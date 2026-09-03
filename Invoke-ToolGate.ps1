[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ToolId,

    [Parameter(Mandatory = $false)]
    [string]$AgentId = "agent-endpoint-reader-001"
)

$ErrorActionPreference = "Stop"
$catalogPath = Join-Path $PSScriptRoot "tools\catalog.json"
if (-not (Test-Path $catalogPath)) {
    Write-Error "Missing tools/catalog.json"
    exit 1
}

$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir "tool-gate.jsonl"

$catalog = Get-Content -Raw -Path $catalogPath | ConvertFrom-Json
$entry = $catalog.tools | Where-Object { $_.toolId -eq $ToolId } | Select-Object -First 1

$decision = "deny"
$reason = $null
$actualHash = $null

if (-not $entry) {
    $reason = "unknown_tool"
}
else {
    $toolPath = Join-Path $PSScriptRoot $entry.path
    if (-not (Test-Path $toolPath)) {
        $reason = "missing_file"
    }
    else {
        $actualHash = (Get-FileHash -Algorithm SHA256 -Path $toolPath).Hash
        if ($actualHash -ne $entry.sha256) {
            $reason = "hash_mismatch"
        }
        else {
            $decision = "allow"
            $reason = "ok"
        }
    }
}

$log = [ordered]@{
    timestamp  = (Get-Date).ToString("o")
    agentId    = $AgentId
    toolId     = $ToolId
    decision   = $decision
    reason     = $reason
    sha256     = $actualHash
}
($log | ConvertTo-Json -Compress) | Add-Content -Path $logFile

if ($decision -ne "allow") {
    Write-Output "DENY tool=$ToolId reason=$reason"
    exit 2
}

Write-Output "ALLOW tool=$ToolId sha256=$actualHash"
& (Join-Path $PSScriptRoot $entry.path)
exit $LASTEXITCODE