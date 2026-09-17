#!/usr/bin/env python3
"""Generate every app icon Blox needs from one master render.

Draws the icon in code so it stays in version control and can be re-rendered
at any size: an indigo field, a dark rounded board, a 2x2 cluster of glossy
candy blocks and a small crown.

Run from the repo root:  python3 tools/generate_icons.py
"""

import json
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Palette kept in sync with lib/src/theme/blox_theme.dart.
BG_TOP = (61, 68, 114)
BG_BOTTOM = (42, 46, 81)
BOARD = (31, 35, 66)
GREEN = (69, 211, 84)
RED = (232, 82, 75)
BLUE = (63, 127, 228)
YELLOW = (242, 196, 55)
CROWN = (247, 188, 63)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def lighten(c, amt):
    return lerp(c, (255, 255, 255), amt)


def darken(c, amt):
    return lerp(c, (0, 0, 0), amt)


def v_gradient(size, top, bottom):
    img = Image.new("RGB", size, top)
    d = ImageDraw.Draw(img)
    w, h = size
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / max(h - 1, 1)))
    return img


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1],
                                        radius=radius, fill=255)
    return m


def draw_block(img, x, y, s, color):
    """One glossy candy block: dark shell, gradient face, top sheen."""
    # Shadow shell (slightly darker than the face, full rounded square).
    shell = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shell)
    sd.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22),
                         fill=darken(color, 0.28) + (255,))
    img.paste(shell, (x, y), shell)

    # Face with vertical gradient, inset with a deeper bottom margin.
    bw = int(s * 0.86)
    bh = int(s * 0.78)
    face = v_gradient((bw, bh), lighten(color, 0.20), darken(color, 0.10))
    face = face.convert("RGBA")
    face.putalpha(rounded_mask((bw, bh), int(bw * 0.24)))
    fx = x + int(s * 0.07)
    fy = y + int(s * 0.07)
    img.paste(face, (fx, fy), face)

    # Sheen: soft white ellipse fading out, top-left of the face.
    sheen = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    shd = ImageDraw.Draw(sheen)
    shd.ellipse([bw * 0.10, bh * 0.05, bw * 0.48, bh * 0.36],
                fill=(255, 255, 255, 90))
    sheen = sheen.filter(ImageFilter.GaussianBlur(radius=max(1, s // 40)))
    img.paste(sheen, (fx, fy), sheen)


def draw_crown(img, x, y, s):
    """Small gold crown overlapping the board's top-right."""
    crown = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(crown)
    w = h = s
    d.polygon([
        (w * 0.06, h * 0.78), (w * 0.94, h * 0.78),
        (w * 0.88, h * 0.34), (w * 0.67, h * 0.55),
        (w * 0.50, h * 0.18), (w * 0.33, h * 0.55),
        (w * 0.12, h * 0.34),
    ], fill=CROWN + (255,))
    d.rounded_rectangle([w * 0.06, h * 0.78, w * 0.94, h * 0.92],
                        radius=h * 0.06, fill=CROWN + (255,))
    for cx, cy in [(0.12, 0.30), (0.50, 0.14), (0.88, 0.30)]:
        r = w * 0.05
        d.ellipse([w * cx - r, h * cy - r, w * cx + r, h * cy + r],
                  fill=CROWN + (255,))
    img.paste(crown, (x, y), crown)


def render(size, cluster_scale=1.0, pad_bg=True):
    img = v_gradient((size, size), BG_TOP, BG_BOTTOM).convert("RGBA")

    # Board well.
    m = int(size * 0.14)
    well = Image.new("RGBA", (size - 2 * m, size - 2 * m), (0, 0, 0, 0))
    wd = ImageDraw.Draw(well)
    wd.rounded_rectangle([0, 0, well.width - 1, well.height - 1],
                         radius=int(well.width * 0.1), fill=BOARD + (255,))
    img.paste(well, (m, m), well)

    # 2x2 cluster filling most of the well.
    gap = int(well.width * 0.06)
    block = int((well.width - gap * 3) / 2 * cluster_scale)
    total = block * 2 + gap
    ox = m + (well.width - total) // 2
    oy = m + (well.height - total) // 2
    draw_block(img, ox, oy, block, GREEN)
    draw_block(img, ox + block + gap, oy, block, RED)
    draw_block(img, ox, oy + block + gap, block, BLUE)
    draw_block(img, ox + block + gap, oy + block + gap, block, YELLOW)

    # Crown peeking over the board's top-right corner.
    cs = int(size * 0.17)
    draw_crown(img, m + well.width - int(cs * 0.8), m - int(cs * 0.3), cs)
    return img


def render_foreground(size):
    """Adaptive-icon foreground: transparent bg, cluster in the safe zone."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = int(size * 0.24)
    well_size = size - 2 * m
    well = Image.new("RGBA", (well_size, well_size), (0, 0, 0, 0))
    wd = ImageDraw.Draw(well)
    wd.rounded_rectangle([0, 0, well_size - 1, well_size - 1],
                         radius=int(well_size * 0.1), fill=BOARD + (255,))
    img.paste(well, (m, m), well)
    gap = int(well_size * 0.05)
    block = (well_size - gap * 3) // 2
    total = block * 2 + gap
    ox = m + (well_size - total) // 2
    oy = m + (well_size - total) // 2
    draw_block(img, ox, oy, block, GREEN)
    draw_block(img, ox + block + gap, oy, block, RED)
    draw_block(img, ox, oy + block + gap, block, BLUE)
    draw_block(img, ox + block + gap, oy + block + gap, block, YELLOW)
    cs = int(size * 0.16)
    draw_crown(img, m + well_size - int(cs * 0.75), m - int(cs * 0.42), cs)
    return img


def write(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", rel)


def main():
    master = render(1024)
    fg = render_foreground(1024)

    # Repo-level copy for docs/README.
    write(master, "assets/icons/icon.png")

    # Android mipmaps.
    for dpi, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                    ("xxhdpi", 144), ("xxxhdpi", 192)]:
        write(master.resize((px, px), Image.LANCZOS),
              f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png")
        write(fg.resize((px, px), Image.LANCZOS),
              f"android/app/src/main/res/mipmap-{dpi}/ic_launcher_foreground.png")

    # Android adaptive icon descriptor.
    write_xml(
        "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
""",
    )
    write_xml(
        "android/app/src/main/res/values/ic_launcher_background.xml",
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#3D4472</color>
</resources>
""",
    )

    # iOS / macOS appiconsets: honor each set's Contents.json.
    for rel in ["ios/Runner/Assets.xcassets/AppIcon.appiconset",
                "macos/Runner/Assets.xcassets/AppIcon.appiconset"]:
        contents = os.path.join(ROOT, rel, "Contents.json")
        with open(contents) as f:
            spec = json.load(f)
        for img in spec["images"]:
            pt = float(img["size"].split("x")[0])
            scale = int(img["scale"].rstrip("x"))
            px = int(pt * scale)
            write(master.resize((px, px), Image.LANCZOS),
                  f"{rel}/{img['filename']}")

    # Web.
    write(master.resize((32, 32), Image.LANCZOS), "web/favicon.png")
    write(master.resize((192, 192), Image.LANCZOS), "web/icons/Icon-192.png")
    write(master.resize((512, 512), Image.LANCZOS), "web/icons/Icon-512.png")
    write(render(192, pad_bg=True), "web/icons/Icon-maskable-192.png")
    write(render(512, pad_bg=True), "web/icons/Icon-maskable-512.png")

    # Windows .ico with the usual size ladder.
    ico = master.copy()
    ico.save(
        os.path.join(ROOT, "windows/runner/resources/app_icon.ico"),
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64),
               (128, 128), (256, 256)],
    )
    print("wrote windows/runner/resources/app_icon.ico")


def write_xml(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)
    print("wrote", rel)


if __name__ == "__main__":
    main()
