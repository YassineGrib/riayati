# FigCraft Agent Connector Kit

A clean, portable, zero-dependency bridge that enables **any AI Coding Agent** (Claude, Antigravity, Cursor, Codex, etc.) to connect to **FigCraft** and programmatically generate, inspect, and export vector UI layouts.

---

## What is Inside This Folder?

```
figcraft-connector/
├── AGENTS.md                  # Complete instructions and command reference for AI Agents
├── MCP_INTEGRATION.md         # How to configure FigCraft MCP in Claude / Cursor / Antigravity
├── README.md                  # This overview guide
├── lib/
│   ├── fc.py                  # Pure Python TCP client for the FigCraft control port (7979)
│   └── vector_utils.py        # Clean SVG path extraction and vector placement helper
└── templates/
    ├── test_connection.py     # Diagnostic script to verify FigCraft connection
    └── minimal_starter.py     # Agnostic starter script: creates a screen, card, button, and exports PNG
```

---

## How to Use in a New Project

1. **Copy this folder** (`figcraft-connector/`) into your new project repository.
2. **Start FigCraft** with the `--control 7979` flag:
   - **Windows:** `& "C:\Program Files\ArtCraft\FigCraft\figcraft.exe" --control 7979`
   - **macOS:** `/Applications/FigCraft.app/Contents/MacOS/FigCraft --control 7979`
3. **Run the diagnostic:**
   ```bash
   python figcraft-connector/templates/test_connection.py
   ```
4. **Prompt your AI Agent:**
   > *"Read `figcraft-connector/AGENTS.md`. Connect to FigCraft and design the dashboard screen for my app."*

Your AI Agent will read the instructions, understand the protocol and commands, and build your UI directly inside FigCraft!
