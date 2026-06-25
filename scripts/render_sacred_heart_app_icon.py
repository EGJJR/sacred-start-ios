#!/usr/bin/env python3
"""Render 1024x1024 Sacred Heart app icon — matches in-app SacredHeartIconMark proportions."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "DevotionLock/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

HEART_RED = (199, 46, 56)
HEART_DARK = (140, 30, 36)
GOLD = (235, 194, 97)
THORN = (107, 71, 51)
FLAME = (250, 158, 56)
BG_TOP = (245, 237, 250)
BG_BOTTOM = (250, 245, 237)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def bg_gradient(img: Image.Image) -> None:
    px = img.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        r = int(lerp(BG_TOP[0], BG_BOTTOM[0], t))
        g = int(lerp(BG_TOP[1], BG_BOTTOM[1], t))
        b = int(lerp(BG_TOP[2], BG_BOTTOM[2], t))
        for x in range(SIZE):
            px[x, y] = (r, g, b)


def heart_polygon(cx: float, cy: float, scale: float) -> list[tuple[float, float]]:
    w = 190 * scale
    h = 170 * scale
    return [
        (cx, cy + h * 0.95),
        (cx - w * 0.98, cy + h * 0.05),
        (cx - w * 0.55, cy - h * 0.75),
        (cx, cy - h * 0.35),
        (cx + w * 0.55, cy - h * 0.75),
        (cx + w * 0.98, cy + h * 0.05),
    ]


def main() -> None:
    img = Image.new("RGB", (SIZE, SIZE))
    bg_gradient(img)
    draw = ImageDraw.Draw(img, "RGBA")

    cx, cy = SIZE / 2, SIZE / 2 + 24
    scale = 1.0

    for i in range(12):
        angle = math.radians(i * 30 - 90)
        inner = 70 * scale
        outer = 360 * scale
        x1 = cx + math.cos(angle) * inner
        y1 = cy + math.sin(angle) * inner
        x2 = cx + math.cos(angle) * outer
        y2 = cy + math.sin(angle) * outer
        draw.line((x1, y1, x2, y2), fill=GOLD + (140,), width=5)

    thorn_box = [cx - 200 * scale, cy - 120 * scale, cx + 200 * scale, cy + 120 * scale]
    draw.ellipse(thorn_box, outline=THORN + (220,), width=10)

    heart = heart_polygon(cx, cy, scale)
    draw.polygon(heart, fill=HEART_RED)
    draw.line(heart + [heart[0]], fill=HEART_DARK, width=4)

    cross_w, cross_h = 22 * scale, 70 * scale
    cross_arm = 52 * scale
    cross_y = cy - 175 * scale
    draw.rectangle(
        [cx - cross_w / 2, cross_y - cross_h / 2, cx + cross_w / 2, cross_y + cross_h / 2],
        fill=GOLD,
    )
    draw.rectangle(
        [cx - cross_arm / 2, cross_y - cross_w / 2, cx + cross_arm / 2, cross_y + cross_w / 2],
        fill=GOLD,
    )

    flame_y = cross_y - cross_h / 2 - 28 * scale
    flame = [
        (cx, flame_y - 42 * scale),
        (cx + 28 * scale, flame_y + 8 * scale),
        (cx, flame_y + 22 * scale),
        (cx - 28 * scale, flame_y + 8 * scale),
    ]
    draw.polygon(flame, fill=FLAME)

    corner = int(SIZE * 0.224)
    mask = Image.new("L", (SIZE, SIZE), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=corner, fill=255)
    result = Image.new("RGB", (SIZE, SIZE), BG_TOP)
    result.paste(img, mask=mask)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    result.save(OUT, format="PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
