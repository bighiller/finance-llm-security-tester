# Endpoint mapping — tool supply-chain

| Tool control | Endpoint equivalent |
| --- | --- |
| tools/catalog.json | AppLocker / WDAC allow-list |
| sha256 in catalog | Known-good file hash |
| unknown_tool | Unsigned / not-allow-listed binary |
| hash_mismatch | Tampered binary after inventory |
| ALLOW then execute | Trusted publisher / allowed path |
| logs/tool-gate.jsonl | ASR / block event telemetry |

This is integrity allow-listing, not a CA-backed signature. A later pass can wrap the same catalog with a signing key. The decision point stays identical.