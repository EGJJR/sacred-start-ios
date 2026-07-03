#!/usr/bin/env python3
"""Render 1024x1024 Sacred Start app icon — quatrefoil satellite on white (variant 5d)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

SIZE = 1024
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "DevotionLock/Assets.xcassets/AppIcon.appiconset/sacred-start-5d-quatrefoil-satellite-gradient-source.png"
OUT = ROOT / "DevotionLock/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
PREVIEW = ROOT / ".comparison-screenshots/sacred-start-quatrefoil-satellite-app-icon.png"


def render_icon(size: int = SIZE) -> Image.Image:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing source icon: {SOURCE}")
    return Image.open(SOURCE).convert("RGB").resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    icon = render_icon()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUT, format="PNG")
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    icon.save(PREVIEW, format="PNG")
    print(f"Wrote {OUT}")
    print(f"Wrote {PREVIEW}")


if __name__ == "__main__":
    main()
