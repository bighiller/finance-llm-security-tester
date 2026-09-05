[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AgentId,

    [Parameter(Mandatory = $false)]
    [string]$Query = "What is the wire cutoff?",

    [Parameter(Mandatory = $false)]
    [switch]$SkipLlm,

    [Parameter(Mandatory = $false)]
    [string]$SimulateOutput
)

$ErrorActionPreference = "Stop"
$corpusPath = Join-Path $PSScriptRoot "rag\corpus.example.json"
$storePath = Join-Path $PSScriptRoot "agents.json"
if (-not (Test-Path $storePath)) {
    $storePath = Join-Path $PSScriptRoot "agents.example.json"
}

$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir "rag-gate.jsonl"

$corpus = Get-Content -Raw -Path $corpusPath | ConvertFrom-Json
$store = Get-Content -Raw -Path $storePath | ConvertFrom-Json
$agent = $store.agents | Where-Object { $_.agentId -eq $AgentId } | Select-Object -First 1
$canary = [string]$corpus.canary

$decision = "allow"
$reason = "ok"
$retrieved = @()

if (-not $agent -or $agent.status -ne "active") {
    $decision = "deny"
    $reason = "agent_blocked"
}
elseif ($Query -match [regex]::Escape($canary)) {
    $decision = "deny"
    $reason = "ingest_canary"
}
else {
    foreach ($doc in $corpus.documents) {
        $allowed = $false
        foreach ($need in $doc.acl) {
            if ($need -eq "public") { $allowed = $true }
            if ($agent.scopes -contains $need) { $allowed = $true }
        }
        if ($allowed) { $retrieved += $doc }
    }
}

$output = $null
if ($decision -eq "allow" -and $SimulateOutput) {
    $output = $SimulateOutput
    if ($output -match [regex]::Escape($canary)) {
        $decision = "deny"
        $reason = "output_canary"
    }
}

$log = [ordered]@{
    timestamp     = (Get-Date).ToUniversalTime().ToString("o")
    agentId       = $AgentId
    decision      = $decision
    reason        = $reason
    retrievedDocs = @($retrieved | ForEach-Object { $_.docId })
}
($log | ConvertTo-Json -Compress) | Add-Content -Path $logFile

if ($decision -ne "allow") {
    Write-Output "DENY $AgentId reason=$reason docs=$($log.retrievedDocs -join ',')"
    exit 2
}

$docList = ($retrieved | ForEach-Object { $_.docId }) -join ","
Write-Output "ALLOW $AgentId docs=$docList"

if ($SkipLlm) { exit 0 }

$context = ($retrieved | ForEach-Object { $_.text }) -join "`n"
$prompt = "Use only this context:`n$context`nQuestion: $Query"
$caller = Join-Path $PSScriptRoot "Invoke-LocalLlm.ps1"
$result = & $caller -Prompt $prompt
if ($result -match [regex]::Escape($canary)) {
    Write-Output "DENY $AgentId reason=output_canary"
    exit 2
}
Write-Output $result
exit 0