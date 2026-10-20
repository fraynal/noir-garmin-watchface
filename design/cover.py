# Image de couverture du Store (500x500, < 300 Ko) à partir des captures.
# Usage : python3 design/cover.py docs/screenshots docs/store-images/cover.png
import sys
from PIL import Image, ImageDraw, ImageFont
shots, out = sys.argv[1], sys.argv[2]
S, D = 500, 380                     # taille de l'image, diamètre de l'écran
img = Image.new("RGB", (S, S), (0, 0, 0))
d = ImageDraw.Draw(img)
cx, cy = S // 2, 205
screen = Image.open(f"{shots}/day.png").convert("RGB").resize((D, D), Image.LANCZOS)
mask = Image.new("L", (D * 4, D * 4), 0)
ImageDraw.Draw(mask).ellipse((0, 0, D * 4 - 1, D * 4 - 1), fill=255)
mask = mask.resize((D, D), Image.LANCZOS)
r = D // 2 + 9
d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(0, 0, 0), outline=(58, 63, 71), width=4)
img.paste(screen, (cx - D // 2, cy - D // 2), mask)
font = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 64, index=7)  # Neue Thin
d.text((cx, 455), "Noir", font=font, fill=(242, 244, 247), anchor="mm")
img.save(out, optimize=True)
