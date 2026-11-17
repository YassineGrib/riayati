# Guide for AI Agents: Connecting to & Driving FigCraft

This guide teaches any AI Agent (Claude, Cursor, Antigravity, OpenAI Codex, etc.) how to connect to **FigCraft** and programmatically generate, inspect, modify, and export vector UI layouts.

---

## 1. What FigCraft Is

- **FigCraft** is a native, clean-room vector design application built in Rust (a Figma-style editor).
- It runs locally as a desktop app (`figcraft.exe` on Windows, `FigCraft.app` on macOS).
- It exposes a native **TCP control socket server** when launched with the `--control <port>` argument (default: `7979`).
- It saves native `.figcraft` document files and can export frames to standard PNGs/SVGs.

> **Note:** FigCraft is NOT a web browser app or a Figma web plugin. It is driven directly through its local TCP socket protocol or via its MCP server.

---

## 2. Launching & Connecting

### Step 1: Start FigCraft with the control port
Before running scripts or sending commands, ensure FigCraft is started with `--control 7979`:

- **Windows:**
  ```powershell
  & "C:\Program Files\ArtCraft\FigCraft\figcraft.exe" --control 7979
  ```
- **macOS:**
  ```bash
  /Applications/FigCraft.app/Contents/MacOS/FigCraft --control 7979 &
  ```

Once started, FigCraft logs:
```
FigCraft control server listening on 127.0.0.1:7979
```

### Step 2: Use the standard client (`lib/fc.py`)
In Python, import `fc` from `lib/fc.py`:

```python
import fc

# 1. Check if running
if not fc.is_running():
    raise SystemExit("FigCraft is not running on port 7979!")

# 2. Call an RPC method
res = fc.call("window.list")

# 3. Execute an engine command
res = fc.ex("shape.rectangle", x=0, y=0, width=200, height=100)
node_id = res["result"]["id"]
```

---

## 3. Wire Protocol Reference

If implementing in another language (Node.js/TypeScript, Go, Rust):
- **Transport:** Plain TCP localhost (`127.0.0.1:7979`).
- **Framing:** Line-delimited JSON (`\n` at the end of each message).
- **Request Format:**
  ```json
  {"id": 1, "method": "engine.execute", "params": {"command": "<command_name>", "params": { ... }}}
  ```
- **Response Format:**
  ```json
  {"id": 1, "ok": true, "result": { ... }}
  ```
  Or on error:
  ```json
  {"id": 1, "ok": false, "error": "Command failed description"}
  ```

---

## 4. How to Discover Commands (Never Guess!)

FigCraft has over 640 native commands. **Never guess parameter names.** Ask the engine:

```python
import fc

# List all commands
all_cmds = fc.call("engine.commands")["result"]

# Search for specific features (e.g., text, effect, export, page)
text_cmds = [c for c in all_cmds if "text" in c["id"]]
for c in text_cmds:
    print(c["id"], "->", c.get("params"))
```

---

## 5. Core Engine Commands Cheat Sheet

| Task | Command | Accepted Parameters | Return Value |
|---|---|---|---|
| **Create Frame (Screen/Container)** | `frame.create` | `{x, y, width, height, name, parent?, props?, select?}` | `{"id": <int>}` |
| **Create Rectangle** | `shape.rectangle` | `{x, y, width, height, parent?, name?, props?, select?}` | `{"id": <int>}` |
| **Create Ellipse / Circle** | `shape.ellipse` | `{x, y, width, height, parent?, name?, props?, select?}` | `{"id": <int>}` |
| **Create Text** | `text.create` | `{text, x, y, width?, parent?, name?, props?, select?}` | `{"id": <int>}` |
| **Create Vector (SVG Path)** | `vector.create` | `{path, x, y, width?, height?, parent?, name?, props?, select?}` | `{"id": <int>}` |
| **Place Image File** | `image.place` | `{path, x, y, width, height, parent?, name?, mode?}` | `{"id": <int>}` |
| **Place Image as Fill** | `image.place` | `{path, target: <node_id>, mode: "fill"}` | `{"ok": true}` |
| **Set Node Properties** | `node.set` | `{id: <node_id>, ...props}` | `{"ok": true}` |
| **Get Node Data** | `node.get` | `{id: <node_id>}` | `{"result": {x, y, width, height, ...}}` |
| **Find Nodes by Query** | `node.find` | `{name?, type?, text?, limit?}` | `{"result": {"ids": [...], "total": N}}` |
| **Delete Nodes** | `edit.delete` | `{ids: [<node_id>, ...]}` | `{"ok": true}` |
| **Page Operations** | `page.list`, `page.select`, `page.add`, `page.rename`, `page.setBackground` | `{id?, name?, color?}` | Result object |
| **Export PNG/SVG** | `file.export` | `{ids?: [...], format: "png"|"svg", scale: 1.5, path: "<filepath>"}` | `{"ok": true}` |
| **Save Document** | `file.saveAs` / `file.save` | `{path: "<filepath>.figcraft"}` | `{"ok": true}` |
| **Wrap in Section** | `object.wrapInSection` | `{ids: [...], name: "<section_name>"}` | `{"result": {"id": <int>}}` |

---

## 6. Rules Learned the Hard Way (Critical Gotchas)

1. **Drop Shadows Syntax:**
   - The `offset` property **MUST BE A 2-ITEM LIST `[x, y]`**, NOT an object:
     ```python
     # CORRECT:
     "effects": [{"type": "dropShadow", "offset": [0, 8], "radius": 24, "color": "#00000018"}]
     
     # WRONG (will throw an error):
     "effects": [{"type": "dropShadow", "offset": {"x": 0, "y": 8}, "blur": 24}]
     ```
2. **Relative Coordinates:**
   - Coordinates (`x`, `y`) are always relative to the `parent` container frame.
3. **Keep Selection Stable:**
   - Always pass `select=False` when creating elements so FigCraft doesn't trigger UI focus changes that disrupt coordinates.
4. **Text Measuring & Centering:**
   - When text does NOT have a fixed `width`, it hugs its content.
   - To center dynamic text, create it, call `fc.ex("node.get", id=text_id)["result"]["width"]`, and calculate:
     `x = (parent_width - text_width) / 2`.
5. **Fast Previews vs Slow Screenshots:**
   - **ALWAYS** use `file.export` to preview work. It renders in under **0.5 seconds**:
     ```python
     fc.ex("file.export", ids=[frame_id], format="png", scale=1.5, path="output/preview.png")
     ```
   - **NEVER** use `ui.screenshot` unless you specifically want the entire OS window chrome. `ui.screenshot` takes 40-60 seconds.
6. **Make Scripts Idempotent:**
   - Before building frames or sections, always delete old frames with the same name:
     ```python
     old_ids = fc.ex("node.find", name="My Screen", type="FRAME")["result"]["ids"]
     if old_ids:
         fc.ex("edit.delete", ids=old_ids)
     ```
7. **RTL (Arabic/Hebrew) Support:**
   - FigCraft natively supports RTL! Set text direction using:
     ```python
     fc.ex("text.direction", direction="rtl", ids=[text_node_id])
     ```
   - For RTL mirroring, flip coordinates: `x_rtl = frame_width - x_ltr - element_width`.

---

## 7. Minimal Workflow Example

```python
import fc

# 1. Connect and verify
assert fc.is_running(), "FigCraft is not listening on 7979"

# 2. Create frame
frame_id = fc.ex("frame.create", x=0, y=0, width=393, height=852, 
                 name="Main Screen", props={"fill": "#FFFFFF"})["result"]["id"]

# 3. Add text
fc.ex("text.create", text="Hello FigCraft", x=32, y=64, parent=frame_id, 
      props={"fontSize": 24, "fontWeight": 700, "fill": "#111827"})

# 4. Export PNG
fc.ex("file.export", ids=[frame_id], format="png", scale=1.5, path="./preview.png")

# 5. Save document
fc.call("file.saveAs", {"path": "./project.figcraft"})
```
