# FigCraft MCP Integration Guide

This guide details how to configure FigCraft as a **Model Context Protocol (MCP)** server so AI coding assistants (Antigravity, Cursor, Claude Code, Zed, etc.) can inspect, create, and modify vector designs natively via MCP tool calls.

---

## 1. How FigCraft MCP Works

FigCraft provides a dedicated CLI tool: `figcraft-cli`.

It can run in two modes:
1. **Headless MCP Server Mode**:
   ```bash
   figcraft-cli mcp
   ```
   Runs a standalone virtual design engine in memory.
2. **Attached Live Desktop Mode (Recommended)**:
   ```bash
   figcraft-cli mcp --attach 7979
   ```
   Connects to an already-running desktop instance of FigCraft (`--control 7979`). Every change made by the AI agent appears live on your screen in real time.

---

## 2. MCP Server Configuration

### For Claude Desktop (`claude_desktop_config.json`)
```json
{
  "mcpServers": {
    "figcraft": {
      "command": "figcraft-cli",
      "args": ["mcp", "--attach", "7979"]
    }
  }
}
```

### For Cursor (`.cursor/mcp.json`)
```json
{
  "mcpServers": {
    "figcraft": {
      "command": "figcraft-cli",
      "args": ["mcp", "--attach", "7979"]
    }
  }
}
```

### For Antigravity (`~/.gemini/antigravity/mcp/`)
FigCraft is registered under `figcraft` and exposes both high-level MCP tools and direct engine execution:
```
- list_commands
- run_command
- create_node
- set_properties
- inspect_document
- get_node
- select
- export
- save_file
```

---

## 3. Comparing MCP vs Python TCP Socket

| Feature | FigCraft MCP (`figcraft-cli mcp`) | Python Socket Client (`lib/fc.py`) |
|---|---|---|
| **Best For** | Conversational tool calling, single inspections, quick edits. | Batch generation, full screen builds, complex UI automation. |
| **Speed** | 100-300ms per tool invocation overhead. | **Sub-millisecond** line-delimited TCP socket execution. |
| **Portability** | Requires agent MCP runner. | Runs anywhere Python 3 is installed with **zero dependencies**. |
| **Error Feedback** | Standard MCP tool error string. | Full Python traceback with actionable error recovery. |

> **Recommendation for Agents:**
> When building multi-element screens or full layouts, agents should write and execute a Python script using `lib/fc.py`. It is 100x faster, handles hundreds of nodes in under a second, and exports instant preview images.
