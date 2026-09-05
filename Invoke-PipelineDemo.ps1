[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$failed = 0

function Invoke-Step {
    param($Name, $Expected, $Script)
    Write-Output "--- $Name ---"
    $out = & $Script 2>&1 | Out-String
    $out = $out.Trim()
    Write-Output $out
    if ($out -notmatch [regex]::Escape($Expected)) {
        Write-Output "FAIL expected to contain: $Expected"
        $script:failed++
    }
    else {
        Write-Output "PASS"
    }
    Write-Output ""
}

Invoke-Step "1 identity deny revoked" "DENY agent-revoked-001" {
    & "$PSScriptRoot\Invoke-AgentGate.ps1" -AgentId "agent-revoked-001" -SkipLlm
}

Invoke-Step "2 identity allow" "ALLOW agent-endpoint-reader-001" {
    & "$PSScriptRoot\Invoke-AgentGate.ps1" -AgentId "agent-endpoint-reader-001" -SkipLlm
}

Invoke-Step "3 tool unknown" "DENY tool=not-a-real-tool" {
    & "$PSScriptRoot\Invoke-ToolGate.ps1" -ToolId "not-a-real-tool"
}

Invoke-Step "4 tool allow" "ALLOW tool=endpoint-inventory" {
    & "$PSScriptRoot\Invoke-ToolGate.ps1" -ToolId "endpoint-inventory"
}

if (Test-Path "$PSScriptRoot\logs\usage-gate.jsonl") {
    Remove-Item "$PSScriptRoot\logs\usage-gate.jsonl"
}

Invoke-Step "5 usage allow" "ALLOW agent-endpoint-reader-001" {
    & "$PSScriptRoot\Invoke-UsageGate.ps1" -AgentId "agent-endpoint-reader-001" -Prompt "demo-one" -SkipLlm
}

Invoke-Step "6 usage replay deny" "reason=replay" {
    & "$PSScriptRoot\Invoke-UsageGate.ps1" -AgentId "agent-endpoint-reader-001" -Prompt "demo-one" -SkipLlm
}

Invoke-Step "7 rag public only" "docs=pub-policy-001" {
    & "$PSScriptRoot\Invoke-RagGate.ps1" -AgentId "agent-endpoint-reader-001" -SkipLlm
}

Invoke-Step "8 rag canary output deny" "reason=output_canary" {
    & "$PSScriptRoot\Invoke-RagGate.ps1" -AgentId "agent-finance-reader-001" -SimulateOutput "leak CANARY-FIN-7741"
}

if ($failed -gt 0) {
    Write-Output "DEMO FAILED steps=$failed"
    exit 1
}

Write-Output "DEMO PASSED"
exit 0