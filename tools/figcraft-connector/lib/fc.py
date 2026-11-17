"""
FigCraft TCP Control Socket Client.
Zero-dependency, pure Python standard library.

Connects to FigCraft's internal control server on port 7979
and sends line-delimited JSON commands over TCP.
"""

import socket
import json
import sys
import os

DEFAULT_PORT = 7979
DEFAULT_HOST = "127.0.0.1"

# --- Headless mode -----------------------------------------------------------------------------
# Set FIGCRAFT_HEADLESS=1 to drive FigCraft without its window: the same ex()/call() API runs on an
# in-process engine started with `figcraft-cli mcp` (stdio). Nothing to open, no GUI timeouts.
HEADLESS = os.environ.get("FIGCRAFT_HEADLESS") == "1"
CLI_PATH = os.environ.get("FIGCRAFT_CLI", r"C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe")
# Files the headless session may read and write (default: the project root, three folders above lib/).
HEADLESS_ROOT = os.environ.get(
    "FIGCRAFT_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..")))
_session = None


class _HeadlessSession:
    def __init__(self):
        import atexit
        import queue
        import subprocess
        import threading

        self._n = 0
        self._q = queue.Queue()
        self._p = subprocess.Popen(
            [CLI_PATH, "mcp", "--automation-read-root", HEADLESS_ROOT, "--automation-write-root", HEADLESS_ROOT],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            text=True, encoding="utf-8", bufsize=1)
        threading.Thread(target=lambda: [self._q.put(line) for line in self._p.stdout], daemon=True).start()
        atexit.register(self.close)
        self._rpc("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                 "clientInfo": {"name": "riayati-build", "version": "1"}})
        self._send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    def _send(self, obj):
        self._p.stdin.write(json.dumps(obj) + "\n")
        self._p.stdin.flush()

    def _rpc(self, method, params, timeout=600):
        import queue
        self._n += 1
        i = self._n
        self._send({"jsonrpc": "2.0", "id": i, "method": method, "params": params})
        while True:
            try:
                msg = json.loads(self._q.get(timeout=timeout))
            except queue.Empty:
                raise FigCraftConnectionError("Headless FigCraft did not answer in time.")
            if msg.get("id") == i:
                return msg

    def command(self, command, params):
        msg = self._rpc("tools/call", {"name": "run_command", "arguments": {"command": command, "params": params or {}}})
        if "error" in msg:
            return {"id": 1, "ok": False, "error": msg["error"].get("message", str(msg["error"]))}
        res = msg["result"]
        text = "".join(c.get("text", "") for c in res.get("content", []))
        try:
            data = json.loads(text)
        except ValueError:
            data = text
        if res.get("isError"):
            return {"id": 1, "ok": False, "error": text}
        return {"id": 1, "ok": True, "result": data}

    def close(self):
        try:
            self._p.terminate()
        except Exception:
            pass


def _headless():
    global _session
    if _session is None:
        _session = _HeadlessSession()
    return _session


class FigCraftConnectionError(Exception):
    """Raised when FigCraft control port cannot be reached."""
    pass


def is_running(host: str = DEFAULT_HOST, port: int = DEFAULT_PORT, timeout: float = 1.0) -> bool:
    """Check if FigCraft control server is reachable (always true in headless mode)."""
    if HEADLESS:
        return os.path.exists(CLI_PATH)
    try:
        s = socket.create_connection((host, port), timeout=timeout)
        s.close()
        return True
    except (socket.error, OSError):
        return False


def call(method: str, params: dict = None, host: str = DEFAULT_HOST, port: int = DEFAULT_PORT, timeout: float = 300.0) -> dict:
    """
    Send a raw RPC call to FigCraft.
    
    Format:
        {"id": 1, "method": method, "params": params}
    Returns:
        JSON response dict: {"id": 1, "ok": True, "result": {...}}
    """
    if HEADLESS:
        if method == "engine.execute":
            return _headless().command(params["command"], params.get("params"))
        if method == "engine.commands":
            return _headless().command("engine.commands", {})
        return _headless().command(method, params)
    try:
        s = socket.create_connection((host, port), timeout=timeout)
    except (socket.error, ConnectionRefusedError, OSError) as e:
        raise FigCraftConnectionError(
            f"Cannot connect to FigCraft on {host}:{port}.\n"
            f"Make sure FigCraft is running with the '--control {port}' flag:\n"
            f"  - Windows: 'C:\\Program Files\\ArtCraft\\FigCraft\\figcraft.exe --control {port}'\n"
            f"  - macOS:   '/Applications/FigCraft.app/Contents/MacOS/FigCraft --control {port}'"
        ) from e

    try:
        payload = json.dumps({"id": 1, "method": method, "params": params or {}}) + "\n"
        s.sendall(payload.encode("utf-8"))
        
        buf = b""
        while b"\n" not in buf:
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
            
        if not buf:
            raise FigCraftConnectionError("FigCraft closed connection without returning data.")
            
        return json.loads(buf.decode("utf-8").strip())
    finally:
        s.close()


def ex(command: str, host: str = DEFAULT_HOST, port: int = DEFAULT_PORT, **params) -> dict:
    """
    Execute a FigCraft engine command via engine.execute.
    
    Example:
        fc.ex("shape.rectangle", x=0, y=0, width=100, height=50, parent=frame_id)
    """
    return call("engine.execute", {"command": command, "params": params}, host=host, port=port)


def get_commands(filter_keyword: str = None) -> list:
    """List all available FigCraft commands, optionally filtered by keyword."""
    res = call("engine.commands")
    if not res.get("ok"):
        return []
    cmds = res.get("result", [])
    if filter_keyword:
        cmds = [c for c in cmds if filter_keyword.lower() in c.get("id", "").lower()]
    return cmds


if __name__ == "__main__":
    if not is_running():
        print(f"[!] FigCraft control server is NOT running on port {DEFAULT_PORT}.")
        print("Please start FigCraft with '--control 7979' first.")
        sys.exit(1)
        
    print("[+] Successfully connected to FigCraft control server!")
    cmds = get_commands()
    print(f"[+] Total available engine commands: {len(cmds)}")
    if len(sys.argv) > 1:
        keyword = sys.argv[1]
        matches = get_commands(keyword)
        print(f"[+] Commands matching '{keyword}':")
        for m in matches:
            print(f"    - {m.get('id')}: {m.get('params', '')}")
