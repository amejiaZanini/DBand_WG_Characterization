---
name: pptx-reporting
description: Build a results/report presentation (HTML or PPTX) from a project's generated results — CSV metrics, pipeline figures (TIFF), optional paper text — for RF / PhD contexts. Use for results reports, project follow-ups, team meetings, and conference talks. Two modes: NEW deck from results, or ENHANCE an existing deck. Governs content FIRST, then style. PPTX is generated with python-pptx.
---

# PPTX Reporting

Turn generated results into a presentation. Content is decided and validated
**before** any styling. Reuses the project's own figures; never invents results.

## Phase 0 — Pick the mode
- **new** — "I have raw results and want to understand + present them."
- **enhancement** — "I already have a deck and want to improve/modify it."

Ask which if the user did not say.

## Phase 1 — Intake (NEW). Ask explicitly; do not assume.
Collect, and state back what was given, before anything else:
1. **Report intention / idea** — the one message this deck must land.
2. **Inputs and their exact locations (repos / paths):**
   - results: `Metrics_*.csv` path(s)
   - figures: the folder of `.tiff` the pipeline produced
   - optional: a `.md` / draft of the paper text (a guide on how the study
     turned out)
   If a location is not given, ask for it explicitly — do not guess a path.
3. **Purpose & audience:** results report | project follow-up | conference talk;
   audience = tutor | team meeting | conference | project tracking.
4. **Output mode:** PPTX or HTML. If the user has no preference → default to an
   **HTML draft** and say so.

## Phase 2 — Read content references (mandatory)
- Read `content-structure.md` (argument spine: SCR / funnel / answer-first,
  action titles, ghost-deck test) BEFORE outlining.
- Parse the inputs: read the CSV, list the available `.tiff`, read the paper
  `.md` if provided.

## Phase 3 — Design content → OUTLINE (content gate)
- Produce a slide-by-slide **outline**: for each slide, the action title and the
  exhibit type (which figure/table/number).
- Run the ghost-deck test: the action titles read in order must tell the whole
  argument.
- **Confirm the outline with the user. Do not build until it is approved.**

## Phase 4 — Read the style
- Read `style-template.md` for the chosen target:
  - HTML → the CSS base + project style in `style.css` / `html-template.md`
  - PPTX → the project's PowerPoint template, implemented with **python-pptx**
    (`slide-patterns.md` for per-slide layout).

## Phase 5 — Build the deck
- Default: build the **HTML draft**; or the **PPTX** (python-pptx) if chosen.
- **Figures:** reuse the project's `.tiff`. Generate graphics only for conceptual
  **block / flow diagrams** (to explain a concept), never for results. If a
  needed result figure is missing, ask for the project's results-generating
  script and have it save the figure as **TIFF 300 dpi or PNG** — this should
  rarely be needed, since the project already has code that generates results.
- Follow `slide-patterns.md` (e.g. results slide = figure left, interpretive
  bullets right).

## Phase 6 — Validate style (style gate)
- HTML: render and check viewport fit at 1920×1080 (and smaller); preview/export
  with `scripts/export-pdf.sh`.
- PPTX: render slide images via LibreOffice (`soffice`) + `pdftoppm`; run the QA
  checklist in `content-structure.md`.
- Iterate until a full pass reveals no new issues.

## Phase 7 — Deliver
- Ask the final format: keep current | PPTX | PDF. Export with the scripts.

## ENHANCEMENT mode
1. Locate the existing deck (HTML or PPTX) and what to improve.
2. Extract content: `scripts/extract-pptx.py` for PPTX; read the file for HTML.
3. Rework / relocate / readjust content → confirm with the user.
4. Re-read `style-template.md`, re-apply, validate (Phase 6), deliver (Phase 7).

## Files
| File | Role | Status |
|---|---|---|
| `content-structure.md` | Argument spine + QA checklist | baseline (tune to RF) |
| `slide-patterns.md` | Per-slide layout (python-pptx) | see build-pptx.py |
| `style-template.md` | THIS project's visual style (HTML + PPTX) | step 3 (style) |
| `html-template.md` | HTML deck architecture | step 3 (style) |
| `style.css` | Viewport base + project style | step 3 (style) |
| `scripts/extract-pptx.py` | PPTX → JSON + images (enhancement) | ready |
| `scripts/export-pdf.sh` | HTML → PDF (Playwright) | ready |
| `scripts/build-pptx.py` | Build PPTX from a content spec (python-pptx); live slide numbers + editable titles | ready |

## Dependencies
- **python-pptx** (`pip install python-pptx`) — create/edit the `.pptx`
  (preferred generator). NOT yet installed in this container; install on first
  PPTX build.
- **markitdown** (`pip install "markitdown[pptx]"`) — optional, PPTX text
  extraction for content QA.
- **LibreOffice** (`soffice`) — PPTX → PDF and rendering for visual QA.
  *Already installed here.*
- **Poppler** (`pdftoppm`) — PDF → images for slide-level visual QA.
  *Already installed here.*
- **Node.js + Playwright** — `scripts/export-pdf.sh` uses them for HTML → PDF.
  Node is installed; the script installs Playwright into a temp dir on first run.
- **Chromium** — pulled by Playwright (or use the preinstalled one at
  `PLAYWRIGHT_BROWSERS_PATH` when set).
