# Style Template — Project Results Deck

Single source of truth for BOTH targets (HTML and PPTX). Values come from the
project PowerPoint template `TemplateResultados.potx`. Geometry is given in
inches (for python-pptx) and in px at 96 dpi (for HTML/CSS), where 1 in = 96 px
on a 13.33 × 7.5 in → **1280 × 720** stage.

## Canvas
- Aspect 16:9, 13.33 × 7.5 in → 1280 × 720 px.
- Side margins 0.39 in (37 px); content extends to x ≈ 12.96 in (1244 px).

## Colors (hex)
| Token | Hex | Use |
|---|---|---|
| `dark1` | `#000000` | main text |
| `light1` | `#FFFFFF` | background |
| `dark2` | `#44546A` | secondary text / header |
| `light2` | `#E7E6E6` | light fill |
| `accent1` | `#4472C4` | primary accent |
| `accent2` | `#ED7D31` | accent |
| `accent3` | `#A5A5A5` | accent |
| `accent4` | `#FFC000` | accent |
| `accent5` | `#5B9BD5` | accent |
| `accent6` | `#70AD47` | accent |
| `link` | `#0563C1` / visited `#954F72` | hyperlinks |
| table OK cell | fill `#C6EFCE`, text `#006100` | pass cells |
| table border | `#000000`, 1 pt | table rules |

## Fonts
- Titles: **Calibri Light** (HTML fallback: `Carlito`, `Segoe UI`, sans-serif).
- Body & tables: **Calibri** (HTML fallback: `Carlito`, `Segoe UI`, sans-serif).

## Sizes (pt)
| Element | pt |
|---|---|
| Cover title | 40 (subtitles 20) |
| Cover date | 16 |
| Slide title (top-left) | 18 |
| Section subtitle (top-right) | 13 |
| File name over a column | 10, bold, centered |
| Chart labels | 8, centered |
| Table | 10, header bold |
| "Restricted" | 14, bold, white, centered |

## Fixed elements (repeat on every slide)
| Element | x, y (in) | size (in) | x, y (px) | size (px) |
|---|---|---|---|---|
| Logo (bottom-left) | 0.39, 7.04 | 1.26 × 0.25 | 37, 676 | 121 × 24 |
| "Restricted" | 9.93, 7.07 | 1.47 × 0.20 | 953, 679 | 141 × 19 |
| Slide number (centered) | 5.17, 6.95 | 3.00 × 0.40 | 496, 667 | 288 × 38 |
| Footer rule | 0.39→12.96 at y 6.85 | — | 37→1244 at y 658 | — |
| Header rounded rect | -0.09, 0.42 | 4.64 × 0.52 | -9, 40 | 445 × 50 |
| Header rule | 4.68→12.82 at y 0.72 | — | 449→1231 at y 69 | — |

## Cover slide
- Rounded rect full width at y 1.29 in (124 px), height 1.93 in (185 px), with a
  background image.
- Title box x 7.39 / y 1.60 in (709 / 154 px), 5.06 × 1.54 in (486 × 148 px).
- Date at y 3.29 in (316 px).

## Results slide (slides 2–5)
- Two-column grid, **figure left + figure right** (no bullets).
- Column 1 at x 0.35 in (34 px), column 2 at x 6.94 in (666 px); each 5.83 in
  (560 px) wide.
- Each column: a **file name** at y 0.92 in (88 px), then **3 rows × 2 charts**.
  - Chart pairs per column: Attenuation + Phase, then Horizontal, then Vertical.
  - Label rows at y 1.20 / 3.07 / 4.95 in (115 / 295 / 475 px); sub-column x at
    0.35 / 3.13 in (col 1) and 6.94 / 9.72 in (col 2) → px 34 / 300 and 666 / 933.

## Table slide (slide 6)
- Table at x 0.92 / y 2.87 in (88 / 275 px), size 11.5 × 1.76 in (1104 × 169 px),
  **7 columns**.
- Column widths (in): 3.80 / 1.48 / 1.34 / 1.00 / 0.87 / 1.37 / 1.64
  → px: 365 / 142 / 129 / 96 / 84 / 132 / 157.
- Header row bold; OK cells fill `#C6EFCE` / text `#006100`; borders black 1 pt.

## HTML/CSS note
The HTML deck is a derivative: it reuses this palette, typography and geometry on
a 1280 × 720 stage (`style.css`). Animations are optional and subtle (reveal on
enter); they do not exist in the PPTX output and must never change the layout.
