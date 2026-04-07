"""WhatsApp MCP Server - Streamable HTTP transport."""

from __future__ import annotations

import logging
import os

from main import mcp  # Reuse the tool registry from stdio entrypoint

if __name__ == "__main__":
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8081"))
    mcp_path = os.environ.get("MCP_TRANSPORT_PATH", "/mcp").strip() or "/mcp"
    if not mcp_path.startswith("/"):
        mcp_path = f"/{mcp_path}"

    logging.basicConfig(level=logging.INFO)
    logging.info("Starting WhatsApp MCP server (Streamable HTTP) on %s:%s", host, port)
    logging.info("Using MCP streamable path: %s", mcp_path)

    # FastMCP reads host/port from settings for network transports.
    mcp.settings.host = host
    mcp.settings.port = port
    if hasattr(mcp.settings, "streamable_http_path"):
        mcp.settings.streamable_http_path = mcp_path

    mcp.run(transport="streamable-http")
