"""
Vector & SVG path helper for FigCraft.
Zero-dependency, pure Python standard library.
"""

import re
import os
import fc


def extract_svg_path(svg_file_path: str) -> str:
    """Extract SVG path d-attributes from an SVG file."""
    if not os.path.exists(svg_file_path):
        raise FileNotFoundError(f"SVG file not found: {svg_file_path}")
    with open(svg_file_path, "r", encoding="utf-8") as f:
        svg_content = f.read()
    return extract_svg_path_from_string(svg_content)


def extract_svg_path_from_string(svg_content: str) -> str:
    """Extract path 'd' attributes from raw SVG string content."""
    paths = re.findall(r'<path[^>]*\s+d="([^"]+)"', svg_content)
    if not paths:
        # Fallback check without strict regex ordering
        paths = re.findall(r'd="([^"]+)"', svg_content)
    return " ".join(paths)


def place_vector_icon(parent_id: int, path_d: str, x: int, y: int, size: int, fill: str, name: str = "Vector Icon", base_viewbox: float = 256.0) -> int:
    """
    Create a vector layer from an SVG path string and scale it to the requested square size.
    
    Args:
        parent_id: ID of the parent frame
        path_d: SVG path 'd' attribute string
        x: X coordinate relative to parent
        y: Y coordinate relative to parent
        size: Desired square width/height in pixels
        fill: Hex color code (e.g. '#111111')
        name: Name for the FigCraft layer
        base_viewbox: Default coordinate space of the source vector (e.g., 256.0 or 24.0)
    """
    res = fc.ex("vector.create", path=path_d, x=x, y=y, parent=parent_id, name=name, select=False, props={"fill": fill})
    if not res.get("ok"):
        raise RuntimeError(f"Failed to create vector: {res}")
    
    node_id = res["result"]["id"]
    node_data = fc.ex("node.get", id=node_id)["result"]
    
    # Scale proportional to base viewbox
    scale = size / float(base_viewbox)
    orig_w = node_data.get("width", base_viewbox)
    orig_h = node_data.get("height", base_viewbox)
    offset_x = node_data.get("x", x) - x
    offset_y = node_data.get("y", y) - y
    
    fc.ex("node.set", id=node_id,
          width=orig_w * scale,
          height=orig_h * scale,
          x=x + offset_x * scale,
          y=y + offset_y * scale)
    return node_id
