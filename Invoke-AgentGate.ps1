[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AgentId,

    [Parameter(Mandatory = $false)]
    [string]$Prompt = "Reply with the single word OK.",

    [Parameter(Mandatory = $false)]
    [string]$RequiredScope = "llm.prompt",

    [Parameter(Mandatory = $false)]
    [switch]$SkipLlm
)

$ErrorActionPreference = "Stop"
$storePath = Join-Path $PSScriptRoot "agents.json"
if (-not (Test-Path $storePath)) {
    $storePath = Join-Path $PSScriptRoot "agents.example.json"
}
if (-not (Test-Path $storePath)) {
    Write-Error "No agent store found."
    exit 1
}

$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir "agent-gate.jsonl"

$store = Get-Content -Raw -Path $storePath | ConvertFrom-Json
$agent = $store.agents | Where-Object { $_.agentId -eq $AgentId } | Select-Object -First 1

$now = Get-Date
$decision = "deny"
$reason = $null

if (-not $agent) {
    $reason = "unknown_agent"
}
elseif ($agent.status -ne "active") {
    $reason = "revoked"
}
elseif ([datetime]$agent.expiresAt -le $now.ToUniversalTime()) {
    $reason = "expired"
}
elseif ($agent.scopes -notcontains $RequiredScope) {
    $reason = "missing_scope"
}
else {
    $decision = "allow"
    $reason = "ok"
}

$log = [ordered]@{
    timestamp      = $now.ToString("o")
    agentId        = $AgentId
    requiredScope  = $RequiredScope
    decision       = $decision
    reason         = $reason
    store          = Split-Path $storePath -Leaf
}
($log | ConvertTo-Json -Compress) | Add-Content -Path $logFile

if ($decision -ne "allow") {
    Write-Output "DENY $AgentId reason=$reason"
    exit 2
}

Write-Output "ALLOW $AgentId scope=$RequiredScope"

if ($SkipLlm) {
    exit 0
}

$caller = Join-Path $PSScriptRoot "Invoke-LocalLlm.ps1"
& $caller -Prompt $Prompt
exit $LASTEXITCODE