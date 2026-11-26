import sys, json, numpy as np
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
S = sys.argv[1]; DZ = 13.72
M = json.load(open(f"{S}/mid.json")); C = np.array(json.load(open(f"{S}/cav.json")))
CEN = np.array([9.9, 64.9, 123.2, 181.3, 240.0, 298.4, 356.3, 412.4])
col = lambda z0: int(np.argmin(abs(CEN * DZ - z0))) + 1
RC = ["#4C72B0", "#55A868", "#C44E52", "#8172B2"]
fig, ax = plt.subplots(2, 2, figsize=(13, 8.6))

a = ax[0, 0]; base = M["99.4_13.636"]
for j, (h, mk) in enumerate([("alto", "v"), ("medio", "o"), ("bajo", "^")]):
    for x in base[h]:
        if x["s1"] - x["s0"] < 15: continue
        c = col(x["z0"]); a.plot(c + (x["row"] - 2.5) * 0.15, x["d"], mk, color=RC[x["row"] - 1], ms=5, alpha=.85)
a.axhline(400, color="k", lw=1); a.axhspan(388, 412, color="grey", alpha=.15, lw=0)
a.text(8.45, 401, "nominal 400", fontsize=8, va="bottom", ha="right")
a.set_xticks(range(1, 9)); a.set_xlabel("Columna de pines en la ROI (desde el corte 0)")
a.set_ylabel("Diámetro exterior (µm)"); a.set_ylim(340, 450)
a.set_title("(a) Diámetro de cada pin · ▼ arriba  ● medio  ▲ pie   (franja gris = efecto del umbral 91–107)", fontsize=9.5)
for r in range(4): a.plot([], [], "o", color=RC[r], label=f"fila {r+1}")
a.plot(6 + (2 - 2.5) * .15, 360, "x", color="k", ms=10, mew=2.5); a.text(6.05, 352, "falta\n(fila 2)", fontsize=8)
a.legend(fontsize=8, ncol=4, loc="upper left")
for cx in (1, 8): a.axvspan(cx - .45, cx + .45, color="orange", alpha=.12, lw=0)
a.text(8, 445, "col. 1 y 8 cortadas\n(borde del stack / brida)", fontsize=7.5, ha="center", va="top")

a = ax[0, 1]; G = np.full((4, 8), np.nan)
for x in base["medio"]:
    if x["s1"] - x["s0"] >= 15: G[x["row"] - 1, col(x["z0"]) - 1] = x["d"] - 400
im = a.imshow(G, cmap="RdBu_r", vmin=-30, vmax=30, aspect="auto")
for r in range(4):
    for c in range(8):
        a.text(c, r, "✕ falta" if (r == 1 and c == 5) else (f"{G[r,c]:+.0f}" if np.isfinite(G[r, c]) else ""), ha="center", va="center", fontsize=8)
a.set_xticks(range(8)); a.set_xticklabels(range(1, 9)); a.set_yticks(range(4)); a.set_yticklabels([f"fila {i}" for i in range(1, 5)])
a.axhline(1.5, color="k", lw=2); a.text(7.6, 1.5, "canal", fontsize=8, va="center")
a.set_xlabel("Columna"); a.set_title("(b) Mapa de pines: Δd a media altura (µm) respecto a 400", fontsize=9.5)
plt.colorbar(im, ax=a, fraction=.035, label="Δd (µm)")

a = ax[1, 0]; s = 13.636
a.plot(C[:, 0], (C[:, 2] - C[:, 1]) * s, ".", ms=3, color="#4C72B0", label="automático, pico interior (lado canal)")
a.plot(C[:, 0], (C[:, 4] - C[:, 3]) * s, ".", ms=2, color="#bbbbbb", label="automático, pico exterior")
a.plot([50, 150, 250, 350], [833.7, 861.4, 847.7, 806.4], "D", color="#C44E52", ms=7, label="tus medidas manuales")
a.axhline(820, color="k", lw=1); a.text(5, 823, "nominal 820", fontsize=8)
a.set_ylim(650, 1100); a.set_xlabel("Corte TOP"); a.set_ylabel("Altura de cavidad (µm)")
inner = (C[:, 2] - C[:, 1]) * s
a.set_title(f"(c) Cavidad a lo largo de la guía · interior {inner.mean():.0f} ± {inner.std(ddof=1):.0f} µm", fontsize=9.5)
a.legend(fontsize=8, loc="upper right")

a = ax[1, 1]; a.axis("off")
d = lambda k: np.array([x["d"] for x in M[k]["medio"] if x["s1"] - x["s0"] >= 15])
rows = [["Magnitud", "Valor medido", "Nominal", "¿Fiable con estas imágenes?"],
        ["Paso entre columnas", "794 ± 13 µm", "800", "Sí (±13 µm)"],
        ["Distancia filas 1-2 / 2-3 / 3-4", "808 / 2037 / 781 µm", "800/2051/800", "Sí (±1–2 %)"],
        ["Pines que faltan", "1 (fila 2, col. 6)", "0", "Sí"],
        ["Diámetro (media altura, col. 2–7)", "404 ± 5 µm", "400", "Sí, ±10 µm (umbral)"],
        ["Conicidad arriba→pie", "393 → 408 µm", "0", "Indicio (al límite)"],
        ["Cavidad (pico interior)", f"{inner.mean():.0f} ± {inner.std(ddof=1):.0f} µm", "820", "Media sí; corte a corte no"],
        ["Gap pin–tapa", "0–8 px (no resuelto)", "50", "No"],
        ["Rugosidad / poros", "—", "—", "No"]]
t = a.table(cellText=rows, loc="center", cellLoc="left", colWidths=[.33, .27, .15, .31]); t.auto_set_font_size(False); t.set_fontsize(8.5); t.scale(1, 1.6)
for j in range(4): t[0, j].set_facecolor("#dde3ee")
a.set_title("(d) Resumen · Ni ROI TOP · T = 99.4 · 13.64 µm/px", fontsize=9.5)
fig.suptitle("Metrología TAC · muestra Ni (pines circulares) · ROI, vista TOP (504 cortes)", fontsize=12)
fig.tight_layout(); fig.savefig(f"{S}/Ni_ROI_TOP_resultados.png", dpi=140)
