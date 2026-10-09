#!/usr/bin/env python3
"""Renders docs/reel.gif: an animated illustration of the TypoFix flow.

It is a scripted animation, NOT a screen recording. Needs Pillow and macOS system fonts.

    python3 docs/make_reel.py                 # writes docs/reel.gif
    python3 docs/make_reel.py --stills DIR    # also writes a few PNG stills to DIR for checking
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W, H, S = 880, 440, 2          # design size and supersampling factor
FRAME_MS = 70
TOTAL = 20.0
SCENES = [(0.0, 7.0), (7.0, 10.8), (10.8, 20.0)]
FADE = 0.25
FONT_DIR = "/System/Library/Fonts/"

BG = (11, 18, 32)
CARD = (248, 250, 252)
INK = (15, 23, 42)
MUTED = (100, 116, 139)
MUTED_LIGHT = (148, 163, 184)
BORDER = (203, 213, 225)
BUBBLE = (226, 232, 240)
BLUE = (59, 130, 246)
GREEN = (34, 197, 94)
DARK_GREEN = (22, 163, 74)

_fonts = {}


def font(name, size, variation=None):
    key = (name, size, variation)
    if key not in _fonts:
        f = ImageFont.truetype(FONT_DIR + name, int(size * S))
        if variation:
            try:
                f.set_variation_by_name(variation)
            except Exception:
                pass
        _fonts[key] = f
    return _fonts[key]


def ui(size, bold=False):
    return font("SFNS.ttf", size, "Bold" if bold else None)


def mono(size):
    return font("SFNSMono.ttf", size)


def sym(size):
    return font("Apple Symbols.ttf", size)


def sc(v):
    return int(round(v * S))


def clamp(x):
    return max(0.0, min(1.0, x))


def ease(x):
    return 1 - (1 - clamp(x)) ** 3


def prog(t, a, b):
    return ease((t - a) / (b - a))


def lin(t, a, b):
    return clamp((t - a) / (b - a))


def mix(c1, c2, k):
    return tuple(int(round(a + (b - a) * k)) for a, b in zip(c1, c2))


def rgba(c, a):
    return (c[0], c[1], c[2], int(255 * clamp(a)))


def canvas():
    img = Image.new("RGB", (W * S, H * S), BG)
    return img, ImageDraw.Draw(img, "RGBA")


def rrect(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle([sc(v) for v in box], radius=sc(r), fill=fill,
                        outline=outline, width=sc(width) if outline else 0)


def circle(d, cx, cy, r, fill):
    d.ellipse([sc(cx - r), sc(cy - r), sc(cx + r), sc(cy + r)], fill=fill)


def text(d, xy, s, f, fill, anchor="la"):
    """Draws text; honours an RGBA fill's alpha (Pillow ignores it for text on an RGB canvas)."""
    alpha = fill[3] if len(fill) == 4 else 255
    pos = (sc(xy[0]), sc(xy[1]))
    if alpha >= 255:
        d.text(pos, s, font=f, fill=fill[:3], anchor=anchor)
    elif alpha > 0:
        img = d._image
        mask = Image.new("L", img.size, 0)
        ImageDraw.Draw(mask).text(pos, s, font=f, fill=alpha, anchor=anchor)
        img.paste(Image.new("RGB", img.size, fill[:3]), (0, 0), mask)


def line(d, pts, fill, width):
    d.line([(sc(x), sc(y)) for x, y in pts], fill=fill, width=sc(width), joint="curve")


def check(d, cx, cy, fill, a=1.0):
    circle(d, cx, cy, 9, rgba(fill, a))
    line(d, [(cx - 4, cy), (cx - 1, cy + 3.5), (cx + 5, cy - 3.5)], rgba((255, 255, 255), a), 2.2)


def header(d, n, title, sub):
    circle(d, 56, 44, 19, BLUE)
    text(d, (56, 44), str(n), ui(22, True), (255, 255, 255), "mm")
    text(d, (92, 36), title, ui(25, True), (255, 255, 255), "lm")
    text(d, (92, 64), sub, ui(14), MUTED_LIGHT, "lm")


def window(d, box, title):
    x0, y0, x1, y1 = box
    rrect(d, box, 14, fill=CARD)
    for i, col in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        circle(d, x0 + 22 + i * 18, y0 + 20, 6, col)
    text(d, ((x0 + x1) / 2, y0 + 20), title, ui(13), MUTED, "mm")
    line(d, [(x0, y0 + 40), (x1, y0 + 40)], (226, 232, 240), 1)


def cursor(d, x, y):
    pts = [(0, 0), (0, 17), (4.5, 13), (8, 21), (11, 19.5), (7.5, 12), (13, 12)]
    poly = [(sc(x + px), sc(y + py)) for px, py in pts]
    d.polygon(poly, fill=(15, 23, 42), outline=(255, 255, 255))


def sparkle(d, cx, cy, r, fill):
    pts = []
    for i in range(8):
        ang = math.pi / 4 * i - math.pi / 2
        rad = r if i % 2 == 0 else r * 0.32
        pts.append((sc(cx + rad * math.cos(ang)), sc(cy + rad * math.sin(ang))))
    d.polygon(pts, fill=fill)


# ---------------------------------------------------------------- scenes

def scene1(t):
    img, d = canvas()
    header(d, 1, "Paste the setup prompt into your AI agent",
           "Claude Code, Codex, or any agent that can run shell commands on your Mac")
    window(d, (60, 100, 820, 400), "AI agent")

    full = "Set up TypoFix on this Mac: github.com/QasimTalkin/QuickAiTypoFix"
    n = int(len(full) * lin(t, 0.4, 2.6))
    rrect(d, (84, 138, 796, 190), 12, fill=BUBBLE)
    shown = full[:n]
    text(d, (102, 164), shown, mono(15), INK, "lm")
    if t < 3.0 and int(t * 2.5) % 2 == 0:
        cx = 102 + mono(15).getlength(shown) / S + 2
        rrect(d, (cx, 153, cx + 2, 175), 1, fill=BLUE)

    steps = ["Checked macOS 14.5+, Command Line Tools and Ollama",
             "Pulled qwen2.5:1.5b (about 1 GB, one time)",
             "Built and installed TypoFix.app",
             "Settings: local model, no API key needed"]
    for i, label in enumerate(steps):
        p = prog(t, 3.0 + i * 0.8, 3.35 + i * 0.8)
        y = 226 + i * 30 + (1 - p) * 8
        check(d, 102, y, GREEN, p)
        text(d, (122, y), label, ui(16), rgba(INK, p), "lm")
    p = prog(t, 6.2, 6.6)
    y = 226 + 4 * 30 + 6 + (1 - p) * 8
    text(d, (96, y), "→", ui(18, True), rgba(BLUE, p), "lm")
    text(d, (122, y), "Your turn: allow Accessibility once (next step)", ui(16, True), rgba(BLUE, p), "lm")
    return img


def toggle(d, x, y, k):
    track = mix((203, 213, 225), BLUE, k)
    rrect(d, (x, y, x + 44, y + 24), 12, fill=track)
    circle(d, x + 12 + 20 * k, y + 12, 9.5, (255, 255, 255))


def scene2(t):
    img, d = canvas()
    header(d, 2, "Allow Accessibility once",
           "System Settings → Privacy & Security → Accessibility → add TypoFix → switch it on")
    window(d, (150, 100, 730, 392), "Accessibility")
    text(d, (176, 160), "Allow the applications below to control your computer.", ui(14), MUTED, "lm")

    rows = [("Terminal", (71, 85, 105), 1.0), ("TypoFix", BLUE, prog(t, 1.9, 2.3)), ("Notes", (234, 179, 8), 1.0)]
    for i, (name, col, k) in enumerate(rows):
        y0 = 186 + i * 58
        if i == 1 and t > 0.3:
            rrect(d, (164, y0 - 4, 716, y0 + 50), 10, fill=rgba((219, 234, 254), prog(t, 0.3, 0.7)))
        rrect(d, (178, y0 + 6, 206, y0 + 34), 7, fill=col)
        if i == 1:
            sparkle(d, 192, y0 + 20, 8, (255, 255, 255))
        text(d, (222, y0 + 20), name, ui(17), INK, "lm")
        toggle(d, 664, y0 + 8, k)

    ty = 186 + 58 + 20
    tx = 686
    # cursor travels to the toggle, then clicks
    k = prog(t, 0.5, 1.8)
    cx, cy = 560 + (tx - 560) * k, 340 + (ty - 340) * k
    if t < 3.4:
        r = lin(t, 1.9, 2.5)
        if 0 < r < 1:
            circle(d, tx, ty, 8 + 22 * r, rgba(BLUE, 0.35 * (1 - r)))
        cursor(d, cx, cy)
    p = prog(t, 2.7, 3.1)
    text(d, (440, 366), "That's the only manual step.", ui(15, True), rgba(DARK_GREEN, p), "mm")
    return img


NEW_TEXT = [("I", 1), (" ", 0), ("have", 1), (" ", 0), ("an", 1), (" apple and she ", 0),
            ("doesn't", 1), (" like it", 0), (".", 1)]


def keycap(d, cx, cy, label, pressed, f):
    dy = 3 if pressed else 0
    fill = (219, 234, 254) if pressed else (241, 245, 249)
    if not pressed:
        rrect(d, (cx - 28, cy - 28 + 4, cx + 28, cy + 28 + 4), 11, fill=BORDER)
    rrect(d, (cx - 28, cy - 28 + dy, cx + 28, cy + 28 + dy), 11, fill=fill, outline=BORDER, width=1.5)
    text(d, (cx, cy + dy), label, f, BLUE if pressed else INK, "mm")


def scene3(t):
    img, d = canvas()
    header(d, 3, "Select text, press ⌘U. Done.",
           "No popup. Your selection is replaced in place, usually in about a second.")

    # mini menu bar with the TypoFix icon
    rrect(d, (120, 98, 760, 124), 7, fill=(30, 41, 59))
    text(d, (136, 111), "Any app", ui(12), MUTED_LIGHT, "lm")
    busy = 4.2 <= t < 5.2
    if busy:
        for i in range(3):
            a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 9 - i * 1.2))
            circle(d, 733 + i * 8, 111, 2.4, rgba((255, 255, 255), a))
    else:
        sparkle(d, 745, 111, 7, (255, 255, 255))

    window(d, (120, 134, 760, 392), "Any app — text field")
    rrect(d, (150, 192, 730, 258), 10, fill=(255, 255, 255), outline=BORDER, width=1.5)

    old = "i has a apple and she dont like it"
    f = mono(22)
    x0, ymid = 170, 225
    if t < 5.2:
        n = int(len(old) * lin(t, 0.4, 2.4))
        shown = old[:n]
        sel = prog(t, 2.9, 3.4)
        if sel > 0:
            wlen = f.getlength(old) / S
            rrect(d, (x0 - 3, ymid - 16, x0 - 3 + (wlen + 6) * sel, ymid + 16), 4, fill=rgba((147, 197, 253), 0.75))
        text(d, (x0, ymid), shown, f, INK, "lm")
        if t < 2.9 and int(t * 2.5) % 2 == 0:
            cx = x0 + f.getlength(shown) / S + 2
            rrect(d, (cx, ymid - 14, cx + 2, ymid + 14), 1, fill=BLUE)
    else:
        flash = 1 - lin(t, 6.6, 7.2)
        x = x0
        for piece, changed in NEW_TEXT:
            w = f.getlength(piece) / S
            if changed:
                col = mix(INK, DARK_GREEN, flash)
                text(d, (x, ymid), piece, f, col, "lm")
                if flash > 0 and piece.strip():
                    line(d, [(x, ymid + 17), (x + w, ymid + 17)], rgba(GREEN, flash), 2)
            else:
                text(d, (x, ymid), piece, f, INK, "lm")
            x += w

    # keycaps
    kp = prog(t, 3.6, 4.0) * (1 - lin(t, 5.3, 5.6))
    if kp > 0:
        pressed = 4.0 <= t < 4.7
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer, "RGBA")
        text(ld, (372, 322), "Press", ui(17), MUTED, "rm")
        keycap(ld, 420, 322, "⌘", pressed, sym(26))
        text(ld, (456, 320), "+", ui(20), MUTED, "mm")
        keycap(ld, 492, 322, "U", pressed, ui(26, True))
        alpha = layer.getchannel("A").point(lambda v: int(v * kp))
        layer.putalpha(alpha)
        img.paste(layer, (0, 0), layer)
        d = ImageDraw.Draw(img, "RGBA")

    # result badge
    bp = prog(t, 5.6, 6.0)
    if bp > 0:
        rrect(d, (290, 296, 590, 342), 23, fill=rgba(GREEN, bp))
        check(d, 322, 319, (255, 255, 255), bp)
        line(d, [(318, 319), (321, 322.5), (327, 315.5)], rgba(GREEN, bp), 2.2)
        text(d, (342, 319), "Fixed in place. No popup.", ui(17, True), rgba((255, 255, 255), bp), "lm")
    p2 = prog(t, 6.3, 6.7)
    text(d, (440, 364), "qwen2.5:1.5b runs locally in Ollama, so your text stays on your Mac.",
         ui(13), rgba(MUTED, p2), "mm")
    return img


def render(t):
    for idx, (a, b) in enumerate(SCENES):
        if a <= t < b or (idx == len(SCENES) - 1 and t >= a):
            local = t - a
            img = [scene1, scene2, scene3][idx](local)
            fade = min(lin(local, 0, FADE), 1 - lin(local, (b - a) - FADE, b - a))
            if fade < 1:
                img = Image.blend(Image.new("RGB", img.size, BG), img, fade)
            d = ImageDraw.Draw(img, "RGBA")
            for i in range(3):
                circle(d, 440 + (i - 1) * 18, 424, 4.5 if i == idx else 3, (255, 255, 255, 230 if i == idx else 70))
            text(d, (860, 424), "Illustration of the flow, not a screen recording", ui(11), (100, 116, 139), "rm")
            return img.resize((W, H), Image.LANCZOS)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    if "--stills" in sys.argv:
        out = sys.argv[sys.argv.index("--stills") + 1]
        os.makedirs(out, exist_ok=True)
        for t in [1.5, 5.0, 6.5, 8.0, 9.2, 12.0, 13.5, 14.3, 15.0, 16.5, 18.5]:
            render(t).save(os.path.join(out, "t%05.2f.png" % t))
        print("stills ->", out)
        return

    times = [i * FRAME_MS / 1000 for i in range(int(TOTAL * 1000 / FRAME_MS))]
    frames = [render(t) for t in times]
    # one shared palette keeps colours steady and the file small
    sample = Image.new("RGB", (W, H * 6))
    for i, t in enumerate([1.0, 5.0, 8.5, 12.5, 15.2, 17.5]):
        sample.paste(render(t), (0, H * i))
    pal = sample.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    paletted = [f.quantize(palette=pal, dither=Image.Dither.NONE) for f in frames]
    out = os.path.join(here, "reel.gif")
    paletted[0].save(out, save_all=True, append_images=paletted[1:], duration=FRAME_MS, loop=0,
                     optimize=False, disposal=1)
    print("wrote", out, "%.0f KB" % (os.path.getsize(out) / 1024), "(%d frames)" % len(frames))


if __name__ == "__main__":
    main()
