"""WhatsApp MCP Server - SSE transport without Gradio dependency.

This file exists so `wamcp up` can run an SSE MCP server without importing Gradio.
"""

from __future__ import annotations

import logging
import os

from main import mcp  # Reuse the tool registry from stdio entrypoint

if __name__ == "__main__":
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8081"))

    logging.basicConfig(level=logging.INFO)
    logging.info("Starting WhatsApp MCP server (SSE) on %s:%s", host, port)

    # FastMCP reads host/port from settings for network transports.
    mcp.settings.host = host
    mcp.settings.port = port
    mcp.run(transport="sse")
