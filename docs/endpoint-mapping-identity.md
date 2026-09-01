# Endpoint mapping — agent identity

Non-human agent identity in this repo maps to fleet device identity.

| Agent control | Endpoint equivalent |
| --- | --- |
| agentId | Intune deviceId / Entra device object |
| scopes | Assigned policy / role (what the device is allowed to do) |
| status=active | Compliant and enrolled |
| status=revoked | Retire / wipe / disable |
| expiresAt | Cert or compliance validity window |
| DENY before Invoke-LocalLlm | ASR / AppLocker: block the workload before execution |
| logs/agent-gate.jsonl | Device telemetry: who, what decision, when |

Scale claim: the same decision record can be emitted per agent the way endpoint events are emitted per device at 50k+ fleet size. This module is the decision function, not the fleet collector.