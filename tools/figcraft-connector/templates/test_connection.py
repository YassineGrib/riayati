"""
Test FigCraft Control Socket Connection.
Usage:
    python test_connection.py
"""

import sys
import os

# Add lib directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))
import fc

def main():
    print("========================================")
    print(" FigCraft Agent Connector - Diagnostic ")
    print("========================================")
    
    if not fc.is_running():
        print("\n[FAIL] Cannot connect to FigCraft on port 7979.")
        print("\nPlease start FigCraft with the control port:")
        print("  Windows:")
        print("    & 'C:\\Program Files\\ArtCraft\\FigCraft\\figcraft.exe' --control 7979")
        print("  macOS:")
        print("    /Applications/FigCraft.app/Contents/MacOS/FigCraft --control 7979")
        sys.exit(1)
        
    print("\n[OK] Connected to FigCraft control port 7979!")
    
    # Check open windows and documents
    windows = fc.call("window.list")
    print(f"[OK] Open windows: {windows.get('result')}")
    
    # Query engine commands
    cmds = fc.call("engine.commands").get("result", [])
    print(f"[OK] FigCraft engine responded with {len(cmds)} available commands.")
    
    # Query current pages
    pages = fc.ex("page.list").get("result", [])
    print(f"[OK] Document has {len(pages)} page(s):")
    for p in pages:
        print(f"     - Page ID: {p.get('id')}, Name: '{p.get('name')}'")
        
    print("\n[SUCCESS] FigCraft is completely ready for automated agent control!")

if __name__ == "__main__":
    main()
