# CLAUDE.md

Operational guide for Claude Code in this repository: what the project is, how
it is laid out, and the `.claude/` toolkit (agents, commands, rules, skills) and
how to use it.

## Project
- **Fabrication-method study for D/E-band antennas.** Two EBG (pin-texture gap)
  waveguides of the same design — rectangular and circular pins, 316 pins
  (4 rows × 79, period 0.8 mm, height 0.77 mm, pin–lid gap 0.05 mm), WR-6.5
  aperture 1.651 × 0.82 mm, 68.24 mm flange to flange — are built with
  **(a) metal 3D printing** and **(b) LCD/SLA resin printing + Cu/Ni
  electroplating (UPM)**. Goal: quantify the in-band degradation (insertion loss,
  return loss, ripple) and the fabrication imperfections of each method, and
  separate **fabrication error** from **design** contributions.
  → measurement + post-processing at the repo root (`WG_*.py`, `WG_*.m`)
- **Fabrication redesign for UPM (resin + electroplating, two-part split block)**
  → `cad/upm/cst/` (parametric CST macro generator; see `cad/upm/cst/REDISENO_CST_UPM.md`)
- **Manufacturing metrology** of the samples (CT scans from UPC, `.tiff` stacks; VGSTUDIO 2024
  + Fiji/ImageJ) → `metrologia/` (Fiji macros + Python analysis + as-built pins for CST:
  `python cad/upm/cst/gen_cst_macro.py round <pins_asbuilt.csv>`).

**Known findings so far**
- Circular-pin model (`FV4_EBG_C`): one pin was set to Vacuum (missing pin, x = 3.212,
  y = −1.0125 in the original frame); the pin rows were offset 13.5 µm from the
  aperture; Ni was defined with μr = 600 (inflates simulated loss). The missing pin
  was simulated with **PEC** (`Simulación/PinFaltante_Circular_Niquel/`) to check
  whether the S21/S11 trend reproduces the measured degradation (different material
  on purpose: the trend matters, not the absolute loss).
- Metal-print CT (Ni, Cu): full scans at **45.335 µm** voxel (global geometry only;
  the 50 µm pin–lid gap is not resolvable); **ROI scans at ≈ 11 µm** for pins/gap.

**Current stack: Python (acquisition, CAD generators) + MATLAB (post-processing)**.
- Acquisition: `WG_Main.py` / `WG_CalSetup.py` / `VNA_Coms.py` drive a Keysight PNA
  over PyVISA (needs the lab instrument; cannot run in the cloud). Ports 1 and 3:
  the `.mat` files store `S11, S31, S13, S33`; scripts label them S11/S21/S12/S22.
- Post-processing (MATLAB R2016b+): `WG_PlotResults.m` (view/compare, material
  colours Ni/Cu, CST overlay), `WG_PowerBalance.m` (L = 1 − |S11|² − |S21|²),
  `WG_TimeGating.m` (IFFT/TDR, VELFAC from S21 group delay over L = 68.24 mm),
  `WG_LossMap.m` (reflection map + de-embedded EBG loss).
- CAD: `cad/upm/cst/gen_cst_macro.py` → CST VBA macro (`python gen_cst_macro.py [rect]`);
  `cad/upm/cst/check_geometry.py` verifies it with manifold3d (`python3.13`).
- No automated tests. Validate MATLAB by reading; validate CAD with `check_geometry.py`.
- The user communicates in Spanish: answer in Spanish.

If the stack grows, reuse this file's structure and swap only this section.

## Architecture
| Path | What |
|---|---|
| `config.yaml` | VNA + session settings (4001 pts, 110–170 GHz, IFBW 1 kHz, repeats, output dir) |
| `VNA_Coms.py`, `WG_CalSetup.py`, `WG_Main.py` | Acquisition (PyVISA/SCPI) |
| `WG_PlotResults.m`, `WG_PowerBalance.m`, `WG_TimeGating.m`, `WG_LossMap.m` | MATLAB post-processing |
| `data/` | Measured `.mat` per session/prototype (**git-ignored**, created by `WG_Main.py`) |
| `Simulación/` | CST S-parameter exports (`.txt`, Re/Im): `Rectangular/`, `Circular/` × `Copper/`, `Ni/`; `PinFaltante_Circular_Niquel/` |
| `Diseño/STEP/` | Original metal monoblock designs `FV4_EBG_C_raw.stp` (circular), `FV4_EBG_R_raw.stp` (rectangular) |
| `Diseño/Drawings/` | Exported views of the design (`.tif`/`.png`) |
| `Imagenes/` | Photos of the samples / setup |
| `cad/upm/` | UPM redesign: v1 layout (`gen_upm_v1.py`), CST v3 macros + verification in `cst/` |
| `Scaner_Resultados/` | CT scan exports (≈2.7 GB, ~2700 `.tif`): `reports/Ni/{Circular_General,Capturas_ROI}`, `reports/Cu/{General_VIEW,reports}`, `Fotos/` |
| `metrologia/` | CT metrology: Fiji macro set `fiji/Metrologia_EBG.ijm` (F1–F8, selection-driven) → CSV; `analizar_metrologia.py` → per-pin deviations, missing/merged pins, `pins_asbuilt_*.csv` for CST; synthetic test in `pruebas/` |
| `.claude/agents/` | Subagents (delegation) |
| `.claude/commands/` | Slash commands |
| `.claude/rules/` | Always-on guidelines |
| `.claude/rules-inactivas/` | Generic rules kept for reference but **not loaded** (TDD/80 % coverage, always-parallel agents) |
| `.claude/skills/` | On-demand capabilities |

> `config.yaml → output.directory` fixes where `WG_Main.py` writes (`data/Session_*`);
> the MATLAB scripts read those folders. Keep `data/` at the repo root and the
> `S31`/`S13`/`S33` field names in the `.mat` files — do not rename them.

<!-- ==== GENERIC TOOLKIT (keep as-is) ===================================== -->

## Commands (slash)
| Command | Use it to |
|---|---|
| `/checkpoint` | Snapshot work: summarize changes + commit |
| `/verify` | Quick read-based sanity pass before committing |
| `/save-session` | Save session state (committed to repo `.claude/session-data/`) |
| `/resume-session` | Reload the last session and get a briefing |
| `/sessions` | List saved sessions |

## Agents — when to delegate
| Agent | When |
|---|---|
| `planner` | Plan a multi-step change |
| `code-reviewer` | After writing / modifying code |
| `code-simplifier` | Tidy recently changed code without changing behavior |

**Rules when using agents:** own the result (wait, integrate, then answer);
delegate only when the work does not fit one context; pass the relevant rule into
the agent's prompt.

## Skills
- `pptx-reporting` — build a results report (HTML + PPTX) from figures + metrics;
  PPTX via python-pptx (live slide numbers, editable titles). Zanini-styled.
- `matlab-use-symbolic-math` — Symbolic Math Toolbox help (if the stack is MATLAB).

## Conventions (always)
- **Code:** follow `rules/matlab-coding-standards.md` + `matlab-performance-optimization.md`
  (or the applicable language rule). Keep one config source; minimal diffs that
  preserve numeric results exactly.
- **Data integrity:** result numbers come from the measured `.mat` files in `data/`
  (processed by `WG_*.m`), the CST exports in `Simulación/` and, for metrology, the
  CT/Fiji measurement tables. There is no single metrics CSV yet.
  Never invent or round a value down; if a figure is missing, say so.
- **Paper writing (if applicable):** follow `rules/paper-format.md` — impersonal,
  concise, verifiable statements, never invent citations, voice target "sounds
  like an actual person, not an LLM smoothing itself into paste".
- **Git:** commits `type: description` (feat/fix/refactor/docs/chore); develop on
  the stated branch; no PR unless asked.

## Environment
- Cloud sessions: no MATLAB, no VNA, no CST, no Fiji → validate MATLAB by reading;
  CST macros are checked with `cad/upm/cst/check_geometry.py`.
- Python: default `python3` (3.11) has numpy/matplotlib/python-pptx; `python3.13`
  has manifold3d + python-pptx (use it for `check_geometry.py`). LibreOffice
  (`soffice`), Poppler (`pdftoppm`) and Node are available for `pptx-reporting`.
- Session logs persist in the repo `.claude/session-data/` (resume with `/resume-session`).
- Branches: `main` (measurement + post-processing), `upm-sla-redesign`
  (UPM fabrication redesign, current work).
