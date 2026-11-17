"""Prepare launcher sources and preview using Pillow, without changing the logo.

Run from any directory: python assets/icon/prepare_icons.py
Then: dart run flutter_launcher_icons
Run again with --preview-only to preview the generated Android density assets.
White is semantic.surface.card / primitive.white in the brand color tokens;
it gives the pale lime more separation than neutral.50 (#f4f9f0).
"""
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
MOBILE = HERE.parents[1]
RES = MOBILE / "android/app/src/main/res"
SIZE = 1024
BACKGROUND = "#ffffff"


def prepare():
    logo = Image.open(MOBILE.parents[1] / "01-brand/logo/riayati-symbol.png").convert("RGBA")
    logo = logo.crop(logo.getchannel("A").getbbox())
    width = round(SIZE * 0.60)
    logo = logo.resize((width, round(width * logo.height / logo.width)), Image.Resampling.LANCZOS)
    foreground = Image.new("RGBA", (SIZE, SIZE))
    foreground.alpha_composite(logo, ((SIZE - logo.width) // 2, (SIZE - logo.height) // 2))
    foreground.save(HERE / "foreground.png")
    monochrome = Image.new("RGBA", foreground.size, (0, 0, 0, 0))
    monochrome.putalpha(foreground.getchannel("A"))
    monochrome.save(HERE / "monochrome.png")
    # Legacy uses the same visible 72dp viewport as adaptive launcher masks.
    legacy = Image.new("RGBA", (SIZE, SIZE), BACKGROUND)
    legacy.alpha_composite(foreground)
    edge = round(SIZE / 6)
    legacy = legacy.crop((edge, edge, SIZE - edge, SIZE - edge))
    legacy.resize((SIZE, SIZE), Image.Resampling.LANCZOS).convert("RGB").save(HERE / "legacy.png")
    # Keep the artwork within the central 66dp square and inside the visible
    # 72dp circle. This asymmetric mark needs room around the lower right loop.
    alpha = foreground.getchannel("A")
    radius = max(((x + .5 - SIZE / 2) ** 2 + (y + .5 - SIZE / 2) ** 2) ** .5
                 for y in range(SIZE) for x in range(SIZE) if alpha.getpixel((x, y)) > 127)
    assert max(logo.size) < SIZE * 66 / 108
    assert radius < SIZE * 36 / 108, f"Logo exceeds launcher circle: {radius}"
    print(f"Logo width: {width / SIZE:.1%}; radius: {radius / SIZE * 108:.2f}dp (mask: 36dp)")


def preview():
    # Read actual generated xxxhdpi drawables when present, including their 108dp
    # canvas. The launcher displays its middle 72dp, then applies its shape mask.
    color_path = RES / "drawable-xxxhdpi/ic_launcher_foreground.png"
    mono_path = RES / "drawable-xxxhdpi/ic_launcher_monochrome.png"
    layers = [Image.open(color_path if color_path.exists() else HERE / "foreground.png").convert("RGBA"),
              Image.open(mono_path if mono_path.exists() else HERE / "monochrome.png").convert("RGBA")]
    scale = 3
    tile = 220 * scale
    sheet = Image.new("RGB", (1120 * scale, 690 * scale), "#ffffff")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18 * scale)
    small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15 * scale)
    for row, dark in enumerate([False, True]):
        top = row * 345 * scale
        panel = "#1a1d17" if dark else "#f4f9f0"
        ink = "#f4f9f0" if dark else "#2f332d"
        draw.rectangle((0, top, sheet.width, top + 345 * scale), fill=panel)
        draw.text((30 * scale, top + 20 * scale),
                  "Dark launcher" if dark else "Light launcher", fill=ink, font=font)
        for col in range(4):
            themed = col >= 2
            rounded = col % 2 == 1
            fg = layers[int(themed)].resize((SIZE, SIZE), Image.Resampling.LANCZOS)
            bg = "#314923" if dark and themed else "#def6cc" if themed else BACKGROUND
            if themed:
                tint = "#c5eaa9" if dark else "#203a01"
                tinted = Image.new("RGBA", fg.size, tint)
                tinted.putalpha(fg.getchannel("A"))
                fg = tinted
            icon = Image.new("RGBA", fg.size, bg)
            icon.alpha_composite(fg)
            edge = round(SIZE / 6)
            icon = icon.crop((edge, edge, SIZE - edge, SIZE - edge)).resize((tile, tile), Image.Resampling.LANCZOS)
            mask = Image.new("L", (tile, tile))
            shape = ImageDraw.Draw(mask)
            if rounded:
                shape.rounded_rectangle((0, 0, tile - 1, tile - 1), radius=tile * .24, fill=255)
            else:
                shape.ellipse((0, 0, tile - 1, tile - 1), fill=255)
            x, y = (30 + col * 280) * scale, top + 65 * scale
            sheet.paste(icon, (x, y), mask)
            label = ("Themed" if themed else "Brand") + (" / rounded square" if rounded else " / circle")
            draw.text((x, top + 300 * scale), label, fill=ink, font=small)
    sheet.resize((1120, 690), Image.Resampling.LANCZOS).save(HERE / "preview.png")


if __name__ == "__main__":
    if "--preview-only" not in sys.argv:
        prepare()
    preview()
