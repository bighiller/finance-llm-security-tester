[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AgentId,

    [Parameter(Mandatory = $false)]
    [string]$Prompt = "Reply with the single word OK.",

    [Parameter(Mandatory = $false)]
    [switch]$SkipLlm
)

$ErrorActionPreference = "Stop"
$quotaPath = Join-Path $PSScriptRoot "quotas.json"
if (-not (Test-Path $quotaPath)) {
    $quotaPath = Join-Path $PSScriptRoot "quotas.example.json"
}
if (-not (Test-Path $quotaPath)) {
    Write-Error "No quota file found."
    exit 1
}

$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir "usage-gate.jsonl"

$quotas = Get-Content -Raw -Path $quotaPath | ConvertFrom-Json
$windowMinutes = [int]$quotas.windowMinutes
$limits = $quotas.default
if ($quotas.agents.$AgentId) {
    $limits = $quotas.agents.$AgentId
}
$maxCalls = [int]$limits.maxCalls
$maxPromptChars = [int]$limits.maxPromptChars

$cutoff = (Get-Date).ToUniversalTime().AddMinutes(-1 * $windowMinutes)
$priorCalls = 0
$priorChars = 0
$replay = $false
$promptHash = [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($Prompt)
    )
).Replace("-", "")

if (Test-Path $logFile) {
    Get-Content $logFile | ForEach-Object {
        $row = $_ | ConvertFrom-Json
        if ($row.agentId -ne $AgentId) { return }
        if ($row.decision -ne "allow") { return }
        $ts = [datetime]$row.timestamp
        if ($ts.ToUniversalTime() -lt $cutoff) { return }
        $priorCalls++
        $priorChars += [int]$row.promptChars
        if ($row.promptHash -eq $promptHash) { $replay = $true }
    }
}

$decision = "allow"
$reason = "ok"
if ($priorCalls -ge $maxCalls) {
    $decision = "deny"
    $reason = "call_quota"
}
elseif (($priorChars + $Prompt.Length) -gt $maxPromptChars) {
    $decision = "deny"
    $reason = "char_quota"
}
elseif ($replay) {
    $decision = "deny"
    $reason = "replay"
}

$log = [ordered]@{
    timestamp    = (Get-Date).ToUniversalTime().ToString("o")
    agentId      = $AgentId
    decision     = $decision
    reason       = $reason
    promptChars  = $Prompt.Length
    promptHash   = $promptHash
    priorCalls   = $priorCalls
    maxCalls     = $maxCalls
}
($log | ConvertTo-Json -Compress) | Add-Content -Path $logFile

if ($decision -ne "allow") {
    Write-Output "DENY $AgentId reason=$reason priorCalls=$priorCalls maxCalls=$maxCalls"
    exit 2
}

Write-Output "ALLOW $AgentId calls=$($priorCalls + 1)/$maxCalls"

if ($SkipLlm) {
    exit 0
}

$caller = Join-Path $PSScriptRoot "Invoke-LocalLlm.ps1"
& $caller -Prompt $Prompt
exit $LASTEXITCODE