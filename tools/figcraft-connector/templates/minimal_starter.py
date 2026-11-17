"""
Minimal Agnostic FigCraft Starter Template.
Demonstrates how an AI Agent creates frames, shapes, text, shadows, and exports.

Zero app branding, zero project dependencies.
Usage:
    python minimal_starter.py
"""

import sys
import os

# Add lib directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))
import fc

def create_element(cmd, **params):
    res = fc.ex(cmd, **params)
    if not res.get("ok"):
        raise RuntimeError(f"Command '{cmd}' failed: {res}")
    return res["result"]["id"]

def main():
    if not fc.is_running():
        print("[!] FigCraft is not listening on port 7979. Start with '--control 7979'.")
        sys.exit(1)
        
    print("[1] Setting up active page...")
    pages = fc.ex("page.list")["result"]
    active_page_id = pages[0]["id"]
    fc.ex("page.select", id=active_page_id)
    fc.ex("page.setBackground", id=active_page_id, color="#F8FAFC")
    
    # Clean previous demo frames if present
    existing = fc.ex("node.find", name="Demo Screen", type="FRAME")["result"]["ids"]
    if existing:
        fc.ex("edit.delete", ids=existing)
        
    print("[2] Creating screen frame (393 x 852)...")
    frame_id = create_element(
        "frame.create",
        x=100,
        y=100,
        width=393,
        height=852,
        name="Demo Screen",
        select=False,
        props={
            "fill": "#FFFFFF",
            "cornerRadius": 32,
            "clip": True
        }
    )
    
    print("[3] Adding UI layers...")
    # 1. Header bar
    create_element(
        "shape.rectangle",
        x=24,
        y=48,
        width=345,
        height=56,
        parent=frame_id,
        name="Header Bar",
        select=False,
        props={
            "fill": "#F1F5F9",
            "cornerRadius": 16
        }
    )
    
    # 2. Header title text
    create_element(
        "text.create",
        text="My New App",
        x=44,
        y=66,
        parent=frame_id,
        name="Header Title",
        select=False,
        props={
            "fontSize": 18,
            "fontFamily": "Inter",
            "fontWeight": 600,
            "fill": "#0F172A"
        }
    )
    
    # 3. Card with drop shadow (NOTE: offset is a 2-element list [x, y])
    card_id = create_element(
        "shape.rectangle",
        x=24,
        y=128,
        width=345,
        height=200,
        parent=frame_id,
        name="Content Card",
        select=False,
        props={
            "fill": "#FFFFFF",
            "stroke": "#E2E8F0",
            "strokeWeight": 1,
            "strokeAlign": "inside",
            "cornerRadius": 20,
            "effects": [
                {
                    "type": "dropShadow",
                    "offset": [0, 8],
                    "radius": 24,
                    "color": "#00000012"
                }
            ]
        }
    )
    
    # 4. Card body text
    create_element(
        "text.create",
        text="Automated by AI Agent",
        x=48,
        y=160,
        parent=frame_id,
        name="Card Subtitle",
        select=False,
        props={
            "fontSize": 14,
            "fontFamily": "Inter",
            "fontWeight": 500,
            "fill": "#64748B"
        }
    )
    
    create_element(
        "text.create",
        text="Connected to FigCraft via TCP Socket",
        x=48,
        y=190,
        width=290,
        parent=frame_id,
        name="Card Title",
        select=False,
        props={
            "fontSize": 20,
            "fontFamily": "Inter",
            "fontWeight": 700,
            "fill": "#0F172A"
        }
    )
    
    # 5. Primary Action Button
    create_element(
        "shape.rectangle",
        x=48,
        y=246,
        width=180,
        height=48,
        parent=frame_id,
        name="Action Button",
        select=False,
        props={
            "fill": "#2563EB",
            "cornerRadius": 14
        }
    )
    
    create_element(
        "text.create",
        text="Get Started",
        x=95,
        y=261,
        parent=frame_id,
        name="Button Label",
        select=False,
        props={
            "fontSize": 15,
            "fontFamily": "Inter",
            "fontWeight": 600,
            "fill": "#FFFFFF"
        }
    )
    
    print("[4] Exporting preview PNG...")
    out_dir = os.path.join(os.path.dirname(__file__), "..", "output")
    os.makedirs(out_dir, exist_ok=True)
    preview_path = os.path.abspath(os.path.join(out_dir, "demo_preview.png"))
    
    export_res = fc.ex("file.export", ids=[frame_id], format="png", scale=1.5, path=preview_path)
    if export_res.get("ok"):
        print(f"[+] Preview PNG exported to: {preview_path}")
    else:
        print(f"[-] Export notice: {export_res}")
        
    print("[5] Saving document...")
    doc_path = os.path.abspath(os.path.join(out_dir, "demo_project.figcraft"))
    fc.call("file.saveAs", {"path": doc_path})
    print(f"[+] Project saved to: {doc_path}")
    print("\n[SUCCESS] Demo completed successfully!")

if __name__ == "__main__":
    main()
