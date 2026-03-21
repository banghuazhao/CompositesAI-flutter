#!/usr/bin/env python3
"""Generate a 1024×1024 splash image: smaller centered app icon on white (for flutter_native_splash)."""
from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as e:
    print("Requires Pillow: pip install Pillow", file=sys.stderr)
    raise SystemExit(1) from e

# Logo size as fraction of canvas width (1024). 0.38 ≈ 40% — smaller than full-bleed splash.
LOGO_SCALE = 0.38
CANVAS = 1024
BACKGROUND = (255, 255, 255, 255)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    icon_path = root / "images" / "app_icon.png"
    out_path = root / "images" / "splash_logo.png"

    if not icon_path.is_file():
        print(f"Missing {icon_path}", file=sys.stderr)
        raise SystemExit(1)

    icon = Image.open(icon_path).convert("RGBA")
    logo_w = max(1, int(CANVAS * LOGO_SCALE))
    icon = icon.resize((logo_w, logo_w), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), BACKGROUND)
    x = (CANVAS - logo_w) // 2
    y = (CANVAS - logo_w) // 2
    canvas.paste(icon, (x, y), icon)
    canvas.save(out_path, "PNG")
    print(f"Wrote {out_path} ({CANVAS}×{CANVAS}, logo {logo_w}×{logo_w})")


if __name__ == "__main__":
    main()
