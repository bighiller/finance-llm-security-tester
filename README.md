# finance-llm-security-tester

Public controls for securing an agentic intelligence pipeline.
Test substrate: finance and endpoint-style queries.
Runtime: local open-weight models only.

This is not a generic OWASP LLM Top 10 demo pack.

## Controls

| Control | Status |
| --- | --- |
| Local LLM caller (policy wrap, timeout, usage log) | Present |
| Agent identity and authorization | Present |
| Prompt / agent supply-chain (MCP, signing, injection resistance) | Present |
| Token metering and integrity | Present |
| RAG / data-exfiltration defenses | Present |

## Run the caller

Windows PowerShell, repo root, local Ollama reachable on the LAN:

```powershell
$env:LLM_ENDPOINT = "http://127.0.0.1:11434"
$env:LLM_MODEL = "llama3.2:1b"
.\Invoke-LocalLlm.ps1