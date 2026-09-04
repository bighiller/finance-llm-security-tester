# Endpoint mapping — token metering

| Meter control | Endpoint equivalent |
| --- | --- |
| agentId + window | Device / user in a telemetry window |
| maxCalls | Rate limit / burst threshold |
| maxPromptChars | Volume / bandwidth cap |
| promptHash replay | Duplicate / repeated command detection |
| call_quota deny | Throttle after threshold |
| logs/usage-gate.jsonl | EDR process-event count per identity |

This is usage integrity, not billing software. The same counters can feed a SIEM the way SentinelOne/Intune events feed a 50k-device dashboard.