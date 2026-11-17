#!/usr/bin/env python3
"""Generate Riayati colors.json and typography.json (DTCG) from the logo colors.

Source of truth for hues: 01-brand/logo/riayati-symbol.svg (olive #658E3F, lime #C5E76C).
Shades are built in OKLCH (perceptually even), clipped to sRGB by lowering chroma.

Usage: python generate_tokens.py   (writes next to this file)
"""
import json
import math
from pathlib import Path

OUT = Path(__file__).resolve().parent

# ---------- OKLCH <-> sRGB ----------
def _to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def _to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055

def hex_to_oklch(h):
    r, g, b = (_to_lin(int(h[i:i + 2], 16) / 255) for i in (1, 3, 5))
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    return L, math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360

def oklch_to_rgb(L, C, H):
    a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )

def oklch_hex(L, C, H):
    while True:
        rgb = oklch_to_rgb(L, C, H)
        if all(-0.0001 <= v <= 1.0001 for v in rgb) or C <= 0:
            break
        C -= 0.002
    return "#" + "".join(f"{round(min(max(_to_srgb(max(v, 0)), 0), 1) * 255):02x}" for v in rgb)

STEPS = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900", "950"]
LIGHTNESS = [0.975, 0.945, 0.895, 0.83, 0.75, 0.66, 0.565, 0.475, 0.395, 0.315, 0.225]

def ramp(hue, chroma, scale=None):
    scale = scale or [0.25, 0.45, 0.7, 0.9, 1.0, 1.0, 1.0, 0.95, 0.85, 0.75, 0.6]
    return {s: oklch_hex(L, chroma * k, hue) for s, L, k in zip(STEPS, LIGHTNESS, scale)}

def tok(v, desc=None):
    d = {"$type": "color", "$value": v}
    if desc:
        d["$description"] = desc
    return d

def ramp_tokens(r):
    return {k: tok(v) for k, v in r.items()}

# ---------- palette from the logo ----------
_, c_olive, h_olive = hex_to_oklch("#658E3F")
_, c_lime, h_lime = hex_to_oklch("#C5E76C")

brand = ramp(h_olive, c_olive * 1.15)                       # olive, primary
lime = ramp(h_lime, c_lime * 0.95, [0.2, 0.4, 0.65, 0.85, 1, 1, 0.95, 0.85, 0.75, 0.65, 0.5])
neutral = ramp(h_olive, 0.012, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])  # faint olive-tinted grey
red = ramp(27, 0.2)       # SOS / destructive  (#DC2626 family)
green = ramp(148, 0.17)   # success (kept distinct from the olive brand)
amber = ramp(70, 0.16)    # warning
blue = ramp(250, 0.15)    # info

colors = {
    "$schema": "https://design-tokens.github.io/community-group/format/",
    "$description": "Riayati 3-tier color tokens (primitive > semantic > component), generated in OKLCH from the logo olive (#658E3F) and lime (#C5E76C). Dark mode swaps at the semantic layer. Source: 01-brand/tokens/generate_tokens.py",
    "primitive": {
        "$description": "Raw palette. Never reference directly in components.",
        "brand": ramp_tokens(brand),
        "lime": ramp_tokens(lime),
        "neutral": ramp_tokens(neutral),
        "red": ramp_tokens(red),
        "green": ramp_tokens(green),
        "amber": ramp_tokens(amber),
        "blue": ramp_tokens(blue),
        "logo": {
            "olive": tok("#658E3F", "Exact logo olive: artwork only, not a text/UI color (fails 4.5:1 on white)"),
            "lime": tok("#C5E76C", "Exact logo lime: artwork and accents on dark only")
        },
        "white": tok("#ffffff"),
        "black": tok("#000000"),
    },
    "semantic": {
        "$description": "Purpose-based tokens. Use these in designs and layouts.",
        "action": {
            "primary": tok("{primitive.brand.700}", "Olive. White text on it passes 4.5:1"),
            "primary-hover": tok("{primitive.brand.800}"),
            "primary-active": tok("{primitive.brand.900}"),
            "secondary": tok("{primitive.neutral.100}"),
            "secondary-hover": tok("{primitive.neutral.200}"),
            "secondary-active": tok("{primitive.neutral.300}"),
            "destructive": tok("{primitive.red.700}"),
            "destructive-hover": tok("{primitive.red.800}"),
        },
        "accent": {
            "default": tok("{primitive.lime.300}", "Lime highlight fills (chips, progress). Dark text only"),
            "soft": tok("{primitive.lime.100}"),
            "on-accent": tok("{primitive.neutral.900}"),
        },
        "sos": {
            "bg": tok("{primitive.red.600}", "Emergency / child-safety report entry point"),
            "bg-soft": tok("{primitive.red.100}"),
            "text-on-bg": tok("{primitive.white}"),
            "text-on-soft": tok("{primitive.red.900}"),
        },
        "feedback": {
            "success-bg": tok("{primitive.green.50}"), "success-text": tok("{primitive.green.800}"),
            "success-border": tok("{primitive.green.300}"), "success-icon": tok("{primitive.green.700}"),
            "warning-bg": tok("{primitive.amber.50}"), "warning-text": tok("{primitive.amber.900}"),
            "warning-border": tok("{primitive.amber.300}"), "warning-icon": tok("{primitive.amber.700}"),
            "error-bg": tok("{primitive.red.50}"), "error-text": tok("{primitive.red.800}"),
            "error-border": tok("{primitive.red.300}"), "error-icon": tok("{primitive.red.700}"),
            "info-bg": tok("{primitive.blue.50}"), "info-text": tok("{primitive.blue.800}"),
            "info-border": tok("{primitive.blue.300}"), "info-icon": tok("{primitive.blue.700}"),
        },
        "text": {
            "primary": tok("{primitive.neutral.900}", "Body text"),
            "secondary": tok("{primitive.neutral.700}", "Supporting text"),
            "tertiary": tok("{primitive.neutral.600}", "Hints only, never essential info"),
            "disabled": tok("{primitive.neutral.400}"),
            "on-action": tok("{primitive.white}"),
            "on-dark": tok("{primitive.neutral.50}"),
            "link": tok("{primitive.brand.700}"),
            "link-hover": tok("{primitive.brand.900}"),
        },
        "surface": {
            "page": tok("{primitive.neutral.50}"),
            "card": tok("{primitive.white}"),
            "raised": tok("{primitive.white}"),
            "sunken": tok("{primitive.neutral.100}"),
            "brand-soft": tok("{primitive.brand.50}"),
            "overlay": tok("rgba(13, 20, 10, 0.5)", "Modal/sheet backdrop"),
            "disabled": tok("{primitive.neutral.100}"),
        },
        "border": {
            "default": tok("{primitive.neutral.200}", "Decorative dividers and card edges only"),
            "strong": tok("{primitive.neutral.600}", "Essential control boundary (3:1)"),
            "focus": tok("{primitive.brand.600}"),
            "error": tok("{primitive.red.600}"),
            "disabled": tok("{primitive.neutral.200}"),
        },
        "interactive": {
            "hover-overlay": tok("rgba(13, 20, 10, 0.04)"),
            "active-overlay": tok("rgba(13, 20, 10, 0.08)"),
            "selected-bg": tok("{primitive.brand.50}"),
            "selected-border": tok("{primitive.brand.200}"),
            "focus-ring": tok("{primitive.brand.600}", "2px outline, offset 2px"),
        },
    },
    "component": {
        "$description": "Component-scoped tokens. Use in component implementations.",
        "button": {
            "primary-bg": tok("{semantic.action.primary}"),
            "primary-bg-hover": tok("{semantic.action.primary-hover}"),
            "primary-bg-active": tok("{semantic.action.primary-active}"),
            "primary-text": tok("{semantic.text.on-action}"),
            "secondary-bg": tok("{semantic.action.secondary}"),
            "secondary-bg-hover": tok("{semantic.action.secondary-hover}"),
            "secondary-text": tok("{semantic.text.primary}"),
            "ghost-bg": tok("transparent"),
            "ghost-bg-hover": tok("{semantic.interactive.hover-overlay}"),
            "ghost-text": tok("{semantic.text.primary}"),
            "destructive-bg": tok("{semantic.action.destructive}"),
            "destructive-bg-hover": tok("{semantic.action.destructive-hover}"),
            "destructive-text": tok("{semantic.text.on-action}"),
            "sos-bg": tok("{semantic.sos.bg}"),
            "sos-text": tok("{semantic.sos.text-on-bg}"),
            "disabled-bg": tok("{semantic.surface.disabled}"),
            "disabled-text": tok("{semantic.text.disabled}"),
        },
        "input": {
            "bg": tok("{semantic.surface.card}"), "bg-disabled": tok("{semantic.surface.disabled}"),
            "border": tok("{semantic.border.strong}"), "border-hover": tok("{semantic.text.secondary}"),
            "border-focus": tok("{semantic.border.focus}"), "border-error": tok("{semantic.border.error}"),
            "text": tok("{semantic.text.primary}"), "placeholder": tok("{semantic.text.tertiary}"),
        },
        "card": {"bg": tok("{semantic.surface.card}"), "border": tok("{semantic.border.default}")},
        "badge": {
            "neutral-bg": tok("{primitive.neutral.100}"), "neutral-text": tok("{primitive.neutral.800}"),
            "primary-bg": tok("{primitive.brand.100}"), "primary-text": tok("{primitive.brand.800}"),
            "success-bg": tok("{primitive.green.100}"), "success-text": tok("{primitive.green.800}"),
            "warning-bg": tok("{primitive.amber.100}"), "warning-text": tok("{primitive.amber.900}"),
            "error-bg": tok("{primitive.red.100}"), "error-text": tok("{primitive.red.800}"),
        },
        "calendar": {
            "proposed-bg": tok("{semantic.feedback.warning-bg}"),
            "accepted-bg": tok("{semantic.feedback.success-bg}"),
            "declined-bg": tok("{semantic.feedback.error-bg}"),
            "confirmed-bg": tok("{semantic.surface.brand-soft}"),
        },
    },
    "dark": {
        "$description": "Dark mode semantic overrides, swapped at :root[data-theme='dark'].",
        "text": {
            "primary": tok("{primitive.neutral.50}"),
            "secondary": tok("{primitive.neutral.300}"),
            "tertiary": tok("{primitive.neutral.400}"),
            "disabled": tok("{primitive.neutral.600}"),
            "on-action": tok("{primitive.neutral.950}"),
            "link": tok("{primitive.lime.300}"),
            "link-hover": tok("{primitive.lime.200}"),
        },
        "surface": {
            "page": tok("{primitive.neutral.950}"),
            "card": tok("{primitive.neutral.900}"),
            "raised": tok("{primitive.neutral.800}"),
            "sunken": tok("{primitive.black}"),
            "brand-soft": tok("{primitive.brand.950}"),
            "disabled": tok("{primitive.neutral.800}"),
        },
        "border": {
            "disabled": tok("{primitive.neutral.800}"),
            "default": tok("{primitive.neutral.800}"),
            "strong": tok("{primitive.neutral.500}"),
            "focus": tok("{primitive.lime.300}"),
        },
        "interactive": {
            "selected-bg": tok("{primitive.brand.950}"),
            "selected-border": tok("{primitive.brand.700}"),
        },
        "accent": {
            "soft": tok("{primitive.lime.900}", "Dark tint so the lime action color reads on it"),
        },
        "feedback": {
            "success-bg": tok("{primitive.green.950}"), "success-text": tok("{primitive.green.200}"),
            "success-border": tok("{primitive.green.700}"), "success-icon": tok("{primitive.green.400}"),
            "warning-bg": tok("{primitive.amber.950}"), "warning-text": tok("{primitive.amber.200}"),
            "warning-border": tok("{primitive.amber.700}"), "warning-icon": tok("{primitive.amber.400}"),
            "error-bg": tok("{primitive.red.950}"), "error-text": tok("{primitive.red.200}"),
            "error-border": tok("{primitive.red.700}"), "error-icon": tok("{primitive.red.400}"),
            "info-bg": tok("{primitive.blue.950}"), "info-text": tok("{primitive.blue.200}"),
            "info-border": tok("{primitive.blue.700}"), "info-icon": tok("{primitive.blue.400}"),
        },
        "action": {
            "primary": tok("{primitive.lime.300}", "Lime on dark; dark on-action text keeps contrast"),
            "primary-hover": tok("{primitive.lime.200}"),
            "primary-active": tok("{primitive.lime.400}"),
            "secondary": tok("{primitive.neutral.800}"),
            "secondary-hover": tok("{primitive.neutral.700}"),
            "destructive": tok("{primitive.red.400}", "Light red on dark; dark on-action text keeps contrast"),
            "destructive-hover": tok("{primitive.red.300}"),
        },
    },
}

# ---------- typography (Arabic first) ----------
def ts(size, weight, lh, desc, family="sans"):
    return {"$type": "typography", "$value": {
        "fontFamily": f"{{fontFamily.{family}}}", "fontSize": f"{{fontSize.{size}}}",
        "fontWeight": f"{{fontWeight.{weight}}}", "lineHeight": f"{{lineHeight.{lh}}}",
        "letterSpacing": "{letterSpacing.normal}"}, "$description": desc}

typography = {
    "$schema": "https://design-tokens.github.io/community-group/format/",
    "$description": "Arabic-first typography. Major Third (1.25) scale, px (Flutter: logical px). Arabic rules: letter-spacing is ALWAYS 0 (any tracking breaks letter joining), and leading is looser than Latin because of diacritics and tall letters.",
    "fontFamily": {
        "sans": {"$type": "fontFamily", "$value": ["thmanyah sans", "IBM Plex Sans Arabic", "Noto Sans Arabic", "system-ui", "sans-serif"],
                 "$description": "App UI: labels, buttons, fields, numbers (the 'digital' face). Local files only, see 01-brand/fonts/thmanyah/README.md"},
        "display": {"$type": "fontFamily", "$value": ["thmanyah serif display", "thmanyah sans", "IBM Plex Sans Arabic", "serif"],
                    "$description": "Large titles and the wordmark only"},
        "serif-text": {"$type": "fontFamily", "$value": ["thmanyah serif text", "thmanyah sans", "IBM Plex Sans Arabic", "serif"],
                       "$description": "Long reading text such as legal articles"},
        "mono": {"$type": "fontFamily", "$value": ["IBM Plex Mono", "Consolas", "monospace"],
                 "$description": "Reference numbers and codes only"},
    },
    "fontSize": {
        "$description": "Major Third scale. Base 16px. Minimum UI text 14px for Arabic.",
        "sm": {"$type": "dimension", "$value": "14px"}, "base": {"$type": "dimension", "$value": "16px"},
        "lg": {"$type": "dimension", "$value": "18px"}, "xl": {"$type": "dimension", "$value": "20px"},
        "2xl": {"$type": "dimension", "$value": "24px"}, "3xl": {"$type": "dimension", "$value": "30px"},
        "4xl": {"$type": "dimension", "$value": "36px"}, "5xl": {"$type": "dimension", "$value": "48px"},
    },
    "fontWeight": {
        "regular": {"$type": "number", "$value": 400}, "medium": {"$type": "number", "$value": 500},
        "semibold": {"$type": "number", "$value": 600}, "bold": {"$type": "number", "$value": 700},
    },
    "lineHeight": {
        "$description": "Arabic needs more room than Latin.",
        "tight": {"$type": "number", "$value": 1.4, "$description": "Large headings only"},
        "snug": {"$type": "number", "$value": 1.5},
        "normal": {"$type": "number", "$value": 1.65, "$description": "Body"},
        "relaxed": {"$type": "number", "$value": 1.8, "$description": "Long legal text"},
    },
    "letterSpacing": {
        "normal": {"$type": "dimension", "$value": "0em", "$description": "The only value used for Arabic"},
    },
    "textStyle": {
        "$description": "Composite styles. Use these in components.",
        "display": ts("4xl", "bold", "tight", "Splash / landing hero: 36px", "display"),
        "heading-1": ts("3xl", "bold", "tight", "Screen title: 30px", "display"),
        "heading-2": ts("2xl", "semibold", "snug", "Section title: 24px"),
        "heading-3": ts("xl", "semibold", "snug", "Card title: 20px"),
        "heading-4": ts("lg", "semibold", "snug", "Small title: 18px"),
        "body-lg": ts("lg", "regular", "normal", "Lead text: 18px"),
        "body": ts("base", "regular", "normal", "Default body: 16px"),
        "body-legal": ts("base", "regular", "relaxed", "Legal article text: 16px, loose leading", "serif-text"),
        "label": ts("sm", "medium", "snug", "Form labels, buttons: 14px"),
        "caption": ts("sm", "regular", "normal", "Captions, helper text: 14px"),
    },
}

(OUT / "colors.json").write_text(json.dumps(colors, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
(OUT / "typography.json").write_text(json.dumps(typography, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("brand.700 =", brand["700"], "| brand.600 =", brand["600"], "| lime.300 =", lime["300"])
print("written: colors.json, typography.json")
