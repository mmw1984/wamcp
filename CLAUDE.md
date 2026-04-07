# CLAUDE.md

This file provides guidance for AI-assisted development in this repository.

## Project Overview

WhatsApp MCP — Model Context Protocol integration with personal WhatsApp accounts. **Primary deployment is non-Docker** via the `wamcp` helper (macOS / Ubuntu): Go bridge + Python MCP server (+ optional webhook UI).

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   whatsapp-bridge   │     │   whatsapp-mcp      │     │    webhook-ui       │
│   (Go + whatsmeow)  │◄────│   (Python + MCP)    │     │   (HTML/JS SPA)     │
│   Port: 8080        │     │   Ports: 8081,8082  │     │   Port: 8089        │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
         │                           │
         ▼                           ▼
    ┌─────────────────────────────────────┐
    │           SQLite (store/)         │
    │  messages.db │ whatsapp.db        │
    └─────────────────────────────────────┘
```

**whatsapp-bridge/** (Go): WhatsApp connection via whatsmeow, REST API, webhooks  
**whatsapp-mcp-server/** (Python): MCP tools, stdio or SSE transport  
**whatsapp-webhook-ui/**: Optional browser UI for webhook configuration  

## Commands (recommended: `wamcp`)

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
wamcp doctor
wamcp install
wamcp start
wamcp login qr   # or: wamcp login phone <number>
```

After code changes, restart services (`wamcp stop` then `wamcp start`); there is no hot-reload for the Go binary.

### Development (without global `wamcp`)

```bash
# Bridge (Go 1.25+)
cd whatsapp-bridge && go run main.go
cd whatsapp-bridge && go test ./...

# MCP Server (Python 3.11+, uv)
cd whatsapp-mcp-server && uv sync
cd whatsapp-mcp-server && uv run python main.py

# Webhook UI
cd whatsapp-webhook-ui && python3 -m http.server 8089
```

### Pre-commit checks (Python)

```bash
cd whatsapp-mcp-server
uv sync --all-extras
uv run python check.py --quick
uv run python check.py
```

### Updating whatsmeow (when 405 errors appear)

```bash
cd whatsapp-bridge
go get -u go.mau.fi/whatsmeow@latest
go mod tidy
```

## Key Patterns

### Go Bridge
- `internal/api/` — HTTP handlers, CORS, JSON
- `internal/whatsapp/` — Client, messages, media
- `internal/webhook/` — Webhook delivery
- `internal/database/` — SQLite stores
- `internal/types/` — Shared structs

### Python MCP
- `whatsapp.py` — Core library and bridge HTTP client
- `main.py` — MCP stdio (Cursor / Claude Desktop)
- `sse-main.py` — MCP SSE without Gradio
- `gradio-main.py` — SSE + Gradio UI (optional)
- `BRIDGE_HOST` — Where to reach the Go bridge (e.g. `127.0.0.1:8080`)

### Webhooks
Trigger types: `all`, `chat_jid`, `sender`, `keyword`, `media_type`  
Match: `exact`, `contains`, `regex`  
Delivery: async with backoff, HMAC-SHA256 signatures  

### JIDs
- DM: `{phone}@s.whatsapp.net`
- Group: `{id}@g.us`

## Ports
- 8080: Bridge REST API  
- 8081: MCP SSE (when using `sse-main.py` / Gradio SSE path)  
- 8082: Gradio UI (if enabled)  
- 8089: Webhook UI (static server)  

## Environment
- `BRIDGE_HOST`, `API_KEY` — MCP → bridge  
- `GRADIO`, `DEBUG`, `HOST`, `PORT` — MCP server  

## Security (summary)
- Production: set `API_KEY` on the bridge; dev can use `DISABLE_AUTH_CHECK=true`  
- Webhooks: SSRF checks on URLs; `DISABLE_SSRF_CHECK` for local testing  
- Media paths: restricted; `DISABLE_PATH_CHECK` for dev  
- Rate limit: 100 req/min per IP on bridge API  

## Code Standards
- Go: structured logging, godoc on exports, table tests, `fmt.Errorf("...: %w", err)`  
- Python: `logger` from `lib.utils`, type hints, tests in `tests/`  

## Testing

```bash
cd whatsapp-mcp-server && uv run pytest --cov=lib -v
cd whatsapp-bridge && go test -v -race ./...
```

## CI (GitHub Actions)
- `go-test.yml` — Go tests + build  
- `python-test.yml` — Python tests / typing  
- `lint.yml` — golangci-lint, ruff  
- `security.yml` — govulncheck, pip-audit, gitleaks  
- `bridge-binaries-linux.yml` — optional prebuilt Linux bridge on `v*` tags  
