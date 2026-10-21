# Prompt de génération des icônes d'indicateurs

À copier tel quel dans ChatGPT. Les SVG obtenus vont dans `resources/images/`,
puis je les vérifie (cadre, épaisseur, rendu à 28 px) avant de les intégrer.

---

You are an icon designer. Create 10 SVG icons for a minimalist Garmin AMOLED watch face called "Noir" (black background, light pastel line icons). They must match the 3 existing icons below exactly in style.

## Existing icons (style reference, do not redraw them)

Heart rate:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#DE858B" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.51 4.04 3 5.5l7 7Z"/>
</svg>
```

Body Battery:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#A9BEDD" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M13 2 3 14h7l-1 8 10-12h-7z"/>
</svg>
```

Steps:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#79BFB7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z"/><path d="M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z"/><path d="M16 17h4"/><path d="M4 13h4"/>
</svg>
```

## Icons to create

| File name | Meaning | Suggested motif | Stroke color |
|---|---|---|---|
| `stress.svg` | Stress level | a jagged / zigzag wave line, or a gauge with a needle | `#E3B27D` |
| `calories.svg` | Calories burned | a flame | `#E89A7A` |
| `floors.svg` | Floors climbed | a staircase going up, with a small up arrow | `#A9C98A` |
| `intensity.svg` | Intensity minutes (weekly) | a stopwatch with a small lightning or a filled-progress hint, all as strokes | `#E8C46E` |
| `respiration.svg` | Respiration rate (breaths per minute) | lungs, or wind/breath curves | `#8FC3E0` |
| `pulse_ox.svg` | Blood oxygen (SpO2) | a drop with a small "O2"-like circle, strokes only, no text | `#D98FA8` |
| `recovery.svg` | Recovery time (hours) | a clock with a circular arrow (restart / rewind) | `#9FB4E0` |
| `sleep_score.svg` | Sleep score | a bed, or a crescent moon with a small "z" drawn as strokes | `#A7A3DE` |
| `altitude.svg` | Altitude | a mountain (two peaks) | `#C9B796` |
| `solar.svg` | Solar charging intensity | a sun (circle with short rays) | `#F0CF6B` |

## Strict rules (every icon)

1. Exactly this root element, only the stroke color changes:
   `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#XXXXXX" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">`
2. Line icons only: `fill="none"` everywhere, no filled shapes, no gradients, no opacity, no masks, no `<text>`, no `<defs>`, no `<style>`, no CSS, no `transform`.
3. Use only `<path>`, `<circle>`, `<rect>`, `<line>`, `<polyline>`. One color per icon (the stroke color of the root).
4. All drawing must stay inside x and y between 2 and 22 (the 2 px stroke must not touch or cross the 24×24 box). Center the drawing visually in the box.
5. Same visual weight as the reference icons: simple, recognizable at 28 px on a watch, no more than 4–5 strokes, no tiny details (nothing smaller than 2 units).
6. Same family as the Lucide icon set (the references come from it). You may start from the matching Lucide icon if one exists.

## Output format

For each icon, output its file name as a heading, then the complete SVG in its own ```svg code block. No explanations between icons. At the end, one line listing the 10 file names.
