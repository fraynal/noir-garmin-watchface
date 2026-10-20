import sys
# Image de présentation du Store (1440x720) à partir des captures.
# Usage : python3 design/hero.py docs/screenshots docs/store-images/hero-en.png en
from PIL import Image, ImageDraw, ImageFont
shots, out, lang = sys.argv[1], sys.argv[2], sys.argv[3]
W, H = 1440, 720
TXT = {
    "en": ("Minimalist AMOLED watch face", "Readable, even in always-on.", "Free · Open source"),
    "fr": ("Cadran AMOLED minimaliste", "Lisible, même en veille.", "Gratuit · Open source"),
}[lang]
img = Image.new("RGB", (W, H), (0, 0, 0))
d = ImageDraw.Draw(img)
font = "/System/Library/Fonts/HelveticaNeue.ttc"
title = ImageFont.truetype(font, 150, index=7)   # Neue Thin
sub = ImageFont.truetype(font, 40, index=0)
small = ImageFont.truetype(font, 28, index=0)
x0 = 110
d.text((x0, 190), "Noir", font=title, fill=(242, 244, 247))
d.text((x0, 380), TXT[0], font=sub, fill=(185, 196, 212))
d.text((x0, 436), TXT[1], font=sub, fill=(185, 196, 212))
d.text((x0, 520), TXT[2], font=small, fill=(113, 120, 127))
# Deux écrans ronds : jour au premier plan, nuit en arrière-plan.
def disc(name, size):
    im = Image.open(f"{shots}/{name}.png").convert("RGB").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    return im, mask.resize((size, size), Image.LANCZOS)
def place(name, size, cx, cy, ring):
    im, mask = disc(name, size)
    r = size // 2 + 10
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(0, 0, 0), outline=ring, width=4)
    img.paste(im, (cx - size // 2, cy - size // 2), mask)
place("night", 340, 1250, 320, (38, 42, 48))
place("day", 400, 960, 380, (58, 63, 71))
img.save(out, optimize=True)
