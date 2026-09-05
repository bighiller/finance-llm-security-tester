# finance-llm-security-tester

Public controls for securing an agentic intelligence pipeline.
Test substrate: finance and endpoint-style queries.
Runtime: local open-weight models only.

This is not a generic OWASP LLM Top 10 demo pack.

## Controls

| Control | Status | Entry point |
| --- | --- | --- |
| Local LLM caller (policy wrap, timeout, usage log) | Present | `Invoke-LocalLlm.ps1` |
| Agent identity and authorization | Present | `Invoke-AgentGate.ps1` |
| Prompt / agent supply-chain (tool hash allow-list) | Present | `Invoke-ToolGate.ps1` |
| Token metering and integrity | Present | `Invoke-UsageGate.ps1` |
| RAG / data-exfiltration defenses | Present | `Invoke-RagGate.ps1` |

## Demo

Windows PowerShell, repo root. Does not need a live model.

```powershell
.\Invoke-PipelineDemo.ps1