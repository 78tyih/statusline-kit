#!/usr/bin/env python3
# Render the statusline as a PNG (terminal-style), no browser needed.
from PIL import Image, ImageDraw, ImageFont

MONO = "/System/Library/Fonts/SFNSMono.ttf"
EMOJI = "/System/Library/Fonts/Apple Color Emoji.ttc"
FS = 38            # text px (3x scale of ~13pt)
EMJ = 34          # emoji strike size we draw, then composited
PAD_X, PAD_Y = 60, 50
LINE_GAP = 18
BG = (13, 16, 23)

font = ImageFont.truetype(MONO, FS)
try:
    efont = ImageFont.truetype(EMOJI, 160)  # Apple emoji fixed strike
except Exception:
    efont = None

C = {
    "118": (135, 255, 0), "220": (255, 215, 0), "208": (255, 135, 0),
    "48": (0, 255, 135), "203": (255, 95, 95), "81": (95, 215, 255),
    "141": (175, 135, 255), "213": (255, 135, 255), "108": (135, 175, 135),
    "110": (135, 175, 215), "dim": (58, 63, 75), "bf": (135, 255, 0),
    "be": (42, 47, 58), "fg": (200, 205, 215),
}

# token stream: ("text"|"emoji", content, color_key)
line1 = [
    ("emoji", "📄", None), ("sp", " ", None),
    ("text", "████", "bf"), ("text", "░░░░░░", "be"), ("sp", " ", None),
    ("text", "42%", "118"), ("sp", "  ", None),
    ("text", "|", "dim"), ("sp", " ", None),
    ("emoji", "💰", None), ("sp", " ", None), ("text", "$1.23", "220"), ("sp", " ", None),
    ("text", "·", "dim"), ("sp", " ", None), ("text", "$0.80/hr", "208"), ("sp", "  ", None),
    ("text", "|", "dim"), ("sp", " ", None),
    ("emoji", "✏️", None), ("sp", "  ", None),
    ("text", "+120", "48"), ("sp", " ", None), ("text", "-30", "203"), ("sp", "  ", None),
    ("text", "|", "dim"), ("sp", " ", None),
    ("emoji", "🔑", None), ("sp", " ", None),
    ("text", "0.10M", "81"), ("text", "/", "dim"), ("text", "2.40M", "141"),
]
line2 = [
    ("text", "Opus 4.8", "213"), ("sp", " ", None),
    ("text", "git:(main*)", "108"), ("sp", "   ", None),
    ("text", "~/projects/kaoshipan", "110"),
]

def measure(tokens):
    w = 0
    ch = font.getlength("M")
    for kind, content, _ in tokens:
        if kind == "emoji":
            w += EMJ + 6
        elif kind == "sp":
            w += ch * len(content)
        else:
            w += font.getlength(content)
    return w

def emoji_img(ch):
    big = Image.new("RGBA", (180, 180), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    try:
        d.text((10, 10), ch, font=efont, embedded_color=True)
    except Exception:
        pass
    bbox = big.getbbox()
    if bbox:
        big = big.crop(bbox)
    return big.resize((EMJ, EMJ), Image.LANCZOS)

w1, w2 = measure(line1), measure(line2)
W = int(max(w1, w2)) + PAD_X * 2
asc, desc = font.getmetrics()
LH = asc + desc
H = PAD_Y * 2 + LH * 2 + LINE_GAP

img = Image.new("RGBA", (W, H), BG + (255,))
draw = ImageDraw.Draw(img)

def render(tokens, y):
    x = PAD_X
    ch = font.getlength("M")
    for kind, content, ck in tokens:
        if kind == "emoji":
            ei = emoji_img(content)
            img.alpha_composite(ei, (int(x), int(y + (LH - EMJ) // 2)))
            x += EMJ + 6
        elif kind == "sp":
            x += ch * len(content)
        else:
            draw.text((x, y), content, font=font, fill=C[ck])
            x += font.getlength(content)

render(line1, PAD_Y)
render(line2, PAD_Y + LH + LINE_GAP)

out = "/Users/a1234/.claude/skills/statusline-kit/preview.png"
img.convert("RGB").save(out)
print("saved", out, img.size)
