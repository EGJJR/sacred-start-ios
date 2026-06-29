#!/usr/bin/env python3
"""Render 1024x1024 Sacred Start app icon — glossy navy squircle with twin ribbon S monogram."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "DevotionLock/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
PREVIEW = Path(__file__).resolve().parents[1] / ".comparison-screenshots/sacred-start-app-icon.png"

NAVY_TOP = (30, 36, 78)
NAVY_BOTTOM = (10, 12, 32)
RIBBON_HI = (242, 238, 255)
RIBBON_MID = (204, 198, 240)
RIBBON_LO = (150, 142, 198)
PREVIEW_BG = (198, 194, 232)

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
    "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
    "/System/Library/Fonts/NewYork.ttf",
    "/Library/Fonts/Georgia Bold.ttf",
]


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(c1: tuple[int, ...], c2: tuple[int, ...], t: float) -> tuple[int, int, int]:
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))  # type: ignore[misc]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def squircle_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def glossy_base(size: int, radius: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x / (size - 1) * 0.3 + y / (size - 1) * 0.7)
            base = lerp_color(NAVY_TOP, NAVY_BOTTOM, t)
            dx = (x - size * 0.16) / size
            dy = (y - size * 0.12) / size
            gloss = max(0.0, 1.0 - math.hypot(dx, dy) * 2.0) * 0.24
            r = min(255, int(base[0] + gloss * 85))
            g = min(255, int(base[1] + gloss * 90))
            b = min(255, int(base[2] + gloss * 115))
            px[x, y] = (r, g, b, 255)
    img.putalpha(squircle_mask(size, radius))
    return img


def embossed_text_layer(size: int, text: str, font: ImageFont.ImageFont) -> Image.Image:
    """Layered SS with ribbon-like depth."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] - size * 0.01

    # Drop shadow
    draw.text((x + 8, y + 14), text, font=font, fill=RIBBON_LO + (170,))
    # Depth body
    draw.text((x + 3, y + 6), text, font=font, fill=RIBBON_LO)
    draw.text((x, y), text, font=font, fill=RIBBON_MID)
    # Highlight ridge
    draw.text((x - 3, y - 5), text, font=font, fill=RIBBON_HI + (220,))

    # Clip to text alpha for clean highlight
    alpha = layer.split()[-1]
    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(highlight).text((x - 4, y - 7), text, font=font, fill=(255, 255, 255, 140))
    highlight.putalpha(ImageChops.multiply(highlight.split()[-1], alpha))
    layer = Image.alpha_composite(layer, highlight)
    return layer


def add_gloss_overlay(img: Image.Image, radius: int) -> Image.Image:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = img.size
    draw.rounded_rectangle([10, 10, w - 11, h - 11], radius=radius - 6, outline=(130, 150, 230, 55), width=3)
    draw.arc([16, 12, w * 0.58, h * 0.46], start=205, end=320, fill=(255, 255, 255, 70), width=16)
    return Image.alpha_composite(img, overlay)


def render_icon(size: int = SIZE) -> Image.Image:
    radius = int(size * 0.224)
    base = glossy_base(size, radius)

    font = load_font(int(size * 0.46))
    monogram = embossed_text_layer(size, "SS", font)

    composed = Image.alpha_composite(base, monogram)
    return add_gloss_overlay(composed, radius)


def render_preview(icon: Image.Image) -> Image.Image:
    pad = int(SIZE * 0.12)
    canvas = Image.new("RGB", (SIZE + pad * 2, SIZE + pad * 2), PREVIEW_BG)
    shadow = icon.copy().convert("RGBA")
    shadow_layer = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow_layer).rounded_rectangle(
        [40, 48, SIZE - 40, SIZE - 24],
        radius=int(SIZE * 0.18),
        fill=(0, 0, 0, 55),
    )
    shadow = Image.alpha_composite(shadow, shadow_layer).filter(ImageFilter.GaussianBlur(18))
    canvas.paste(shadow, (pad, pad + 12), shadow)
    canvas.paste(icon, (pad, pad), icon)
    return canvas


def main() -> None:
    icon = render_icon()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB").save(OUT, format="PNG")
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    render_preview(icon).save(PREVIEW, format="PNG")
    print(f"Wrote {OUT}")
    print(f"Wrote {PREVIEW}")


if __name__ == "__main__":
    main()
