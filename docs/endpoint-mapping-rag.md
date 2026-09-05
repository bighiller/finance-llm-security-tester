# Endpoint mapping — RAG / exfil

| RAG control | Endpoint equivalent |
| --- | --- |
| document acl | File classification / AIP label |
| public vs finance.secret | All-users vs finance-only share |
| retrieval filter | Access check before file open |
| ingest_canary | Block secret paste into an unsanctioned channel |
| output_canary | DLP on egress |
| logs/rag-gate.jsonl | DLP / file-access event |

Same decision as device DLP at fleet scale: classify, check identity, block on the way out. This module is the decision function, not the 50k-device collector.