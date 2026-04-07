## WhatsApp MCP Extended (41 tools) + `wamcp` one-line installer

Run a local WhatsApp MCP server (non-Docker) with **reactions**, **edit/delete**, **groups**, **polls**, **presence**, **newsletters**, **webhooks**, and more.

### Install (macOS / Ubuntu)

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
```

### Start

```bash
wamcp doctor
wamcp install
wamcp start
wamcp login qr   # or: wamcp login phone <countrycode+number>
```

### Stop / Restart / Logs

```bash
wamcp stop
wamcp start
wamcp logs
```

### Update / Upgrade

Re-run the installer (it updates `~/.wamcp-src/<ref>` and repoints `~/.wamcp-src/current`):

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash
```

Pin / switch version:

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash -s -- --ref vX.Y.Z
```

### Ports

- **Bridge API**: `127.0.0.1:8080`
- **MCP SSE**: `127.0.0.1:8081` (SSE endpoint: `/sse`)

### Start with different ports (avoid port conflicts)

If 8080/8081 are already used, you can start with different ports:

```bash
wamcp stop
BRIDGE_PORT=8180 MCP_PORT=8181 wamcp start --force
```

If you also use stdio MCP config, regenerate after changing ports:

```bash
BRIDGE_PORT=8180 wamcp mcp-config
```

If you want the port change to be permanent, edit the env file and restart:

```bash
vim ~/.wamcp-src/current/.wamcp/env
wamcp stop
wamcp up
```

### What runs (minimum required)

- **`whatsapp-bridge` (Go)**: connects to WhatsApp (QR/phone pairing) + exposes REST API
- **`whatsapp-mcp-server` (Python)**: exposes MCP tools and calls the bridge API

`webhook-ui` is optional (only needed if you want to manage webhook rules from a browser).

### Cursor / Claude Desktop MCP config (stdio)

Run this and paste the JSON:

```bash
wamcp mcp-config
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash -s -- --uninstall
rm -rf ~/.wamcp-src   # optional: remove downloaded source
rm -rf ~/.wamcp       # optional: remove runtime state
```

### 廣東話 Quickstart

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
wamcp install
wamcp up
wamcp login qr
```

### 繁體中文（Quickstart）

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
wamcp install
wamcp up
wamcp login qr
```

### 简体中文（Quickstart）

```bash
curl -fsSL https://raw.githubusercontent.com/mmw1984/wamcp/main/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
wamcp install
wamcp up
wamcp login qr
```

## Troubleshooting

### `wamcp` command not found

- Ensure `~/.local/bin` is on PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Ports already in use (8080/8081)

`wamcp` uses:

- Bridge: `127.0.0.1:8080`
- MCP SSE: `127.0.0.1:8081`

Check what is using the ports:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
lsof -nP -iTCP:8081 -sTCP:LISTEN
```

Stop `wamcp` services (recommended):

```bash
wamcp stop
```

Or force start (kills processes that are holding the ports):

```bash
wamcp start --force
```

## Poke integration (optional)

Forward your local MCP SSE server to Poke and receive notifications when new WhatsApp messages arrive.

**Requirements:** Node.js 18+, `npx`, and `npm`. The first `wamcp poke setup` or `wamcp poke watch` runs `npm install poke` once under your wamcp state directory (default: `<repo>/.wamcp/poke/`, or `$WAMCP_HOME/poke/` if set) so the ESM watcher can import the SDK reliably.

### Setup (login + tunnel)

```bash
wamcp start
wamcp poke setup
```

`wamcp poke setup` runs the tunnel **in the background** (same as `poke tunnel http://localhost:8081/sse -n wamcp`); the colourful CLI text is in **`wamcp poke logs tunnel`**, not in your terminal.

### Start watcher (background)

```bash
wamcp poke watch
wamcp poke status
```

Modes:

- **DM**: always notify
- **Group**:
  - `group_all`: notify every group message
  - `group_tag_only`: notify only when you are mentioned (fallback: message text contains your phone number)

### Stop / logs

```bash
wamcp poke logs              # tunnel + watch (last 120 lines each)
wamcp poke logs watch        # watcher only (recommended when debugging notify)
wamcp poke logs tunnel
wamcp poke stop              # stop tunnel + watcher
wamcp poke stop watch        # stop watcher only (keep tunnel for Poke)
wamcp poke stop tunnel
```

Each successful `wamcp poke watch` **clears** `poke-watch.log` first so old `ERR_MODULE_NOT_FOUND …/scripts/...` lines from earlier installs do not appear mixed with the new run.

If you must kill a stuck process, use the PID from `lsof`:

```bash
kill <PID>
kill -9 <PID>   # only if it refuses to stop
```

### Bridge/MCP started but not working

Check status + logs:

```bash
wamcp status
wamcp logs bridge
wamcp logs mcp
```

Hard reset local runtime state (will require login again):

```bash
wamcp stop
rm -rf ~/.wamcp
```

### WhatsApp login / QR issues

- Re-run:

```bash
wamcp login qr
wamcp logs bridge
```

If you see a timeout waiting for QR scan, just run `wamcp login qr` again and scan the latest QR.

### `Client outdated (405)` errors

WhatsApp Web protocol changes. Update the Go dependency and restart:

```bash
cd ~/.wamcp-src/current/whatsapp-bridge
go get -u go.mau.fi/whatsmeow@latest
go mod tidy
wamcp stop
wamcp start --force
```

## MCP Tools (41 Total)

### Messaging
| Tool | Description |
|------|-------------|
| `send_message` | Send text message |
| `send_file` | Send image/video/document |
| `send_audio_message` | Send voice message |
| `download_media` | Download received media |
| `send_reaction` | React to message with emoji |
| `edit_message` | Edit sent message |
| `delete_message` | Delete/revoke message |
| `mark_read` | Mark messages as read (blue ticks) |

### Chats & Messages
| Tool | Description |
|------|-------------|
| `list_chats` | List all chats |
| `get_chat` | Get chat by JID |
| `list_messages` | Search messages with filters |
| `get_message_context` | Get messages around a specific message |
| `get_direct_chat_by_contact` | Find DM with contact |
| `get_contact_chats` | All chats involving contact |
| `get_last_interaction` | Most recent message with contact |
| `request_history` | Request older message history |

### Contacts
| Tool | Description |
|------|-------------|
| `search_contacts` | Search by name/phone |
| `list_all_contacts` | List all contacts |
| `get_contact_details` | Full contact info |
| `set_nickname` | Set custom nickname |
| `get_nickname` | Get custom nickname |
| `remove_nickname` | Remove nickname |
| `list_nicknames` | List all nicknames |

### Groups
| Tool | Description |
|------|-------------|
| `get_group_info` | Group metadata & participants |
| `create_group` | Create new group |
| `add_group_members` | Add members |
| `remove_group_members` | Remove members |
| `promote_to_admin` | Promote to admin |
| `demote_admin` | Demote admin |
| `leave_group` | Leave group |
| `update_group` | Update name/topic |
| `create_poll` | Create poll in chat |

### Presence & Profile
| Tool | Description |
|------|-------------|
| `set_presence` | Set online/offline status |
| `subscribe_presence` | Subscribe to contact's presence |
| `get_profile_picture` | Get profile picture URL |
| `get_blocklist` | List blocked users |
| `block_user` | Block user |
| `unblock_user` | Unblock user |

### Newsletters (Channels)
| Tool | Description |
|------|-------------|
| `follow_newsletter` | Follow channel |
| `unfollow_newsletter` | Unfollow channel |
| `create_newsletter` | Create new channel |

## Webhook System

Real-time HTTP webhooks for incoming messages with:
- **Triggers**: all, chat_jid, sender, keyword, media_type
- **Matching**: exact, contains, regex
- **Security**: HMAC-SHA256 signatures
- **Retry**: Exponential backoff

Access webhook UI at `http://localhost:8089`

## Development

### Manual Setup

```bash
# Bridge (Go 1.24+)
cd whatsapp-bridge && go run main.go

# MCP Server (Python 3.11+)
cd whatsapp-mcp-server && uv sync && uv run python main.py

# Webhook UI
cd whatsapp-webhook-ui && python3 -m http.server 8089
```

### Pre-build Checks

```bash
cd whatsapp-mcp-server
uv run python check.py  # Catches errors before docker build
```

### Updating whatsmeow

When you see `Client outdated (405)` errors:

```bash
cd whatsapp-bridge
go get -u go.mau.fi/whatsmeow@latest
go mod tidy
wamcp stop
wamcp start --force
```

## Credits

**Fork chain:**
- [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) - Original MCP server (12 tools)
- [AdamRussak/whatsapp-mcp](https://github.com/AdamRussak/whatsapp-mcp) - Added webhooks, container split, webhook UI
- Upstream base: [`FelixIsaac/whatsapp-mcp-extended`](https://github.com/FelixIsaac/whatsapp-mcp-extended)

**Libraries:**
- [whatsmeow](https://github.com/tulir/whatsmeow) - Go WhatsApp Web API
- [FastMCP](https://github.com/jlowin/fastmcp) - Python MCP SDK

## License

MIT License - see [LICENSE](LICENSE) file.
