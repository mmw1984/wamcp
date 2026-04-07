# WAMCP Non-Docker Guide

`wamcp` is a single helper script for running this project on macOS and Ubuntu without Docker.

## Scope

- Default runtime is `whatsapp-bridge + whatsapp-mcp`.
- `webhook-ui` is optional and not required for normal MCP tools.
- For full MCP tool functionality, `bridge` must be running.

## Quick Start

```bash
chmod +x scripts/wamcp
./scripts/wamcp install
./scripts/wamcp up
```

## Public Install (global command)

If you want `wamcp` available globally (without `cd` into the repo), use the public installer:

```bash
curl -fsSL <install_url> | bash
```

This installs:

- `~/.wamcp-src/<ref>` source checkout
- `~/.wamcp-src/current` symlink to selected ref
- `~/.local/bin/wamcp` symlink to `~/.wamcp-src/current/scripts/wamcp`

If `~/.local/bin` is not on your PATH, the installer prints the line to add to your shell rc.

Uninstall:

```bash
curl -fsSL <install_url> | bash -s -- --uninstall
```

Login options:

```bash
./scripts/wamcp login phone <countrycode+number>
# or
./scripts/wamcp login qr
```

Check status:

```bash
./scripts/wamcp status
./scripts/wamcp logs
```

Stop:

```bash
./scripts/wamcp stop
```

## Commands

- `wamcp install`
  - Detects OS (macOS/Ubuntu-like Linux)
  - Installs dependencies
  - Creates local runtime state dir (`.wamcp/`)
  - Generates API key env file for bridge auth
- `wamcp up [--sse]`
  - Starts bridge in background
  - Waits for bridge health endpoint
  - Starts MCP server in SSE mode (`sse-main.py`)
- `wamcp login phone <number>`
  - Calls bridge `POST /api/pair`
  - Polls `GET /api/pairing` for completion
- `wamcp login qr`
  - Uses QR printed by bridge logs
- `wamcp status`
  - Shows process state and bridge connection info
- `wamcp logs [bridge|mcp]`
  - Shows recent logs from `.wamcp/logs`
- `wamcp stop`
  - Stops background processes
- `wamcp doctor`
  - Checks command dependencies
- `wamcp mcp-config`
  - Prints JSON snippet for Cursor/Claude stdio MCP config

## MCP Integration (stdio)

`wamcp up` runs SSE mode for network access.  
For Cursor/Claude MCP over stdio, use:

```bash
./scripts/wamcp mcp-config
```

Then paste the generated JSON into your MCP client config.

## Why webhook UI is optional

- Webhook UI is used to create/manage webhook rules and inspect webhook logs.
- If you only use MCP tools (send/search/group/presence/etc.), webhook UI is not required.
- Enable webhook UI only when you need push delivery to external automation (e.g. n8n, custom endpoints).

## Troubleshooting

- If bridge is unhealthy:
  - `./scripts/wamcp logs bridge`
  - confirm `API_KEY` exists in `.wamcp/env`
- If phone pairing times out:
  - run `./scripts/wamcp status`
  - retry `./scripts/wamcp login phone <number>` or use QR flow
- If MCP cannot reach bridge:
  - verify `BRIDGE_HOST=127.0.0.1:8080` in `.wamcp/env`
  - verify bridge is up: `curl http://127.0.0.1:8080/api/health`
