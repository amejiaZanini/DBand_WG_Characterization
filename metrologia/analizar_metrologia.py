"""Analiza los CSV que genera Metrologia_EBG.ijm (Fiji) y los compara con el diseño.

Uso:
    python analizar_metrologia.py <carpeta_csv> [--salida <carpeta>] [--escala]

Entradas (en <carpeta_csv>, las que existan):
    pines_xy.csv, referencias.csv, perfiles.csv, canal.csv, rugosidad.csv, poros.csv

Salidas (en <carpeta>/resultados por defecto):
    pines_<muestra>.csv          un pin por fila: fila, columna, posición medida y nominal,
                                 desviaciones, diámetro, estado (ok / falta / fusionado / …)
    pins_asbuilt_<muestra>.csv   los 316 pines para CST (x, y, d, h en mm; 'falta' = no crear)
    <muestra>_mapa.png           mapa de desviaciones sobre la rejilla nominal
    <muestra>_histogramas.png    histogramas de Δd, Δx, Δy
    resumen.csv                  métricas por muestra (pines, alturas, canal, rugosidad, poros)

Sistema de coordenadas de diseño (el mismo que cad/upm/cst/gen_cst_macro.py):
    x a lo largo de la guía, y = 0 en el eje del canal. Columnas 1..79 en
    x = -31.2 + 0.8·(col-1) mm. Filas, de un lado al otro del canal:
    fila 1 = +1.8255 (exterior), 2 = +1.0255 (interior), 3 = -1.0255 (interior), 4 = -1.8255 (exterior).
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import numpy as np

PITCH = 0.8                                     # mm
NCOL = 79
X0 = -31.2                                      # mm, columna 1
FILAS_Y = {1: 1.8255, 2: 1.0255, 3: -1.0255, 4: -1.8255}
GEN_ROW = {2: 1, 1: 2, 3: 3, 4: 4}              # fila de este script -> índice de fila del generador CST
NOMINAL = {
    "d_pin_um": 400.0, "lado_pin_um": 400.0, "altura_pin_um": 770.0, "gap_pin_tapa_um": 50.0,
    "altura_cavidad_um": 820.0, "ancho_canal_um": 1651.0, "alto_canal_um": 820.0,
}
F_FUSION = 1.6                                  # área > 1.6 × la nominal -> pines fusionados
D_ASIG = 0.3 * PITCH                            # distancia máx. (mm) para asignar un centroide a un nodo


# ── lectura ─────────────────────────────────────────────────────────────────
def leer_csv(ruta: Path) -> list[dict]:
    if not ruta.exists():
        return []
    lineas = ruta.read_text(encoding="utf-8", errors="replace").strip().splitlines()
    if len(lineas) < 2:
        return []
    cab = lineas[0].split(",")
    filas = []
    for ln in lineas[1:]:
        v = ln.split(",")
        if len(v) != len(cab):
            continue
        filas.append({k: _num(x) for k, x in zip(cab, v)})
    return filas


def _num(x: str):
    try:
        return float(x)
    except ValueError:
        return x


def nodo_xy(fila: int, col: int) -> tuple[float, float]:
    return X0 + PITCH * (col - 1), FILAS_Y[fila]


# ── registro imagen -> diseño ───────────────────────────────────────────────
def ajuste_rigido(p: np.ndarray, q: np.ndarray):
    """R (2×2, se permite reflexión), t, s que minimizan |s·R·p + t − q|. p, q: (n, 2)."""
    pc, qc = p.mean(0), q.mean(0)
    P, Q = p - pc, q - qc
    U, S, Vt = np.linalg.svd(Q.T @ P)
    R = U @ Vt                                   # Kabsch sin forzar det = +1 (la imagen tiene y hacia abajo)
    s = S.sum() / (P ** 2).sum()
    return R, qc - R @ pc, s


def registrar(pts_mm: np.ndarray, refs: list[dict], aplicar_escala: bool):
    """Devuelve (función imagen->diseño, info). Usa los 3 pines de referencia si existen."""
    if len(refs) >= 3:
        r3 = refs[-3:]
        p = np.array([[r["x_um"], r["y_um"]] for r in r3]) / 1000.0
        # ajustar cada clic al centroide detectado más cercano
        for i in range(3):
            d = np.hypot(*(pts_mm - p[i]).T)
            if d.size and d.min() < 0.3 * PITCH:
                p[i] = pts_mm[d.argmin()]
        q = np.array([nodo_xy(int(r["fila"]), int(r["col"])) for r in r3])
        R, t, s = ajuste_rigido(p, q)
        if aplicar_escala:
            R, t = s * R, q.mean(0) - s * R @ p.mean(0)
        res = np.hypot(*((p @ R.T + t) - q).T)
        info = dict(metodo="referencias", escala=s, rot_deg=math.degrees(math.atan2(R[1, 0], R[0, 0])),
                    reflexion=bool(np.linalg.det(R) < 0), residuo_ref_um=1000 * res.max(), indices="absolutos")
        return (lambda x: x @ R.T + t), info
    # Sin referencias: eje principal + filas por agrupamiento en y. Índices RELATIVOS.
    c = pts_mm.mean(0)
    U, S, Vt = np.linalg.svd(pts_mm - c)
    ex = Vt[0]
    ey = np.array([-ex[1], ex[0]])
    R = np.vstack([ex, ey])
    loc = (pts_mm - c) @ R.T
    xmin = loc[:, 0].min()
    ys = np.sort(loc[:, 1])
    centro_y = (ys[0] + ys[-1]) / 2
    t = -R @ c + np.array([X0 - xmin, -centro_y])
    info = dict(metodo="automatico (sin referencias)", escala=float("nan"), rot_deg=math.degrees(math.atan2(ex[1], ex[0])),
                reflexion=False, residuo_ref_um=float("nan"),
                indices="RELATIVOS: la columna 1 es la primera visible; marca 3 referencias en Fiji para índices reales")
    return (lambda x: x @ R.T + t), info


# ── análisis de pines ───────────────────────────────────────────────────────
def analizar_pines(grupo: list[dict], refs: list[dict], geom: str, aplicar_escala: bool):
    pts = np.array([[g["x_um"], g["y_um"]] for g in grupo]) / 1000.0
    a_nom = (math.pi * (NOMINAL["d_pin_um"] / 2) ** 2) if geom == "circular" else NOMINAL["lado_pin_um"] ** 2
    a_med = np.array([g["area_um2"] for g in grupo])
    T, info = registrar(pts, refs, aplicar_escala)
    filas_y = np.array(list(FILAS_Y.values()))
    # Refinado: alinear con TODOS los pines asignados (mejor ajuste de la rejilla, como en una MMC)
    for _ in range(3):
        xy = T(pts)
        p_ok, q_ok = [], []
        for i, (x, y) in enumerate(xy):
            f = list(FILAS_Y)[int(np.abs(filas_y - y).argmin())]
            col = int(round((x - X0) / PITCH)) + 1
            if 1 <= col <= NCOL and a_med[i] <= F_FUSION * a_nom:
                xn, yn = nodo_xy(f, col)
                if math.hypot(x - xn, y - yn) <= D_ASIG:
                    p_ok.append(pts[i]); q_ok.append((xn, yn))
        if len(p_ok) < 3:
            break
        R, t, s = ajuste_rigido(np.array(p_ok), np.array(q_ok))
        if aplicar_escala:
            R, t = s * R, np.mean(q_ok, 0) - s * R @ np.mean(p_ok, 0)
        T = (lambda R_, t_: (lambda x: x @ R_.T + t_))(R, t)
        info.update(escala=s, rot_deg=math.degrees(math.atan2(R[1, 0], R[0, 0])),
                    reflexion=bool(np.linalg.det(R) < 0), n_ajuste=len(p_ok))
    xy = T(pts)
    asign = {}
    estados = []
    for i, (x, y) in enumerate(xy):
        f = list(FILAS_Y)[int(np.abs(filas_y - y).argmin())]
        col = int(round((x - X0) / PITCH)) + 1
        xn, yn = nodo_xy(f, col) if 1 <= col <= NCOL else (np.nan, np.nan)
        dist = math.hypot(x - xn, y - yn)
        est = "ok"
        if not (1 <= col <= NCOL) or dist > D_ASIG:
            est = "no_asignado"
        elif a_med[i] > F_FUSION * a_nom:
            est = "fusionado"
        estados.append([f, col, xn, yn, est, dist])
        if est != "no_asignado":
            k = (f, col)
            if k not in asign or dist < estados[asign[k]][5]:
                if k in asign:
                    estados[asign[k]][4] = "duplicado"
                asign[k] = i
            else:
                estados[i][4] = "duplicado"
    # nodos esperados dentro del rectángulo medido (menos medio pin de margen)
    g0 = grupo[0]
    rx, ry, rw, rh = (g0[k] / 1000.0 for k in ("roi_x_um", "roi_y_um", "roi_w_um", "roi_h_um"))
    esq = T(np.array([[rx, ry], [rx + rw, ry], [rx + rw, ry + rh], [rx, ry + rh]]))
    margen = 0.6 * NOMINAL["d_pin_um"] / 1000.0
    faltan = []
    for f, yv in FILAS_Y.items():
        for col in range(1, NCOL + 1):
            xn = X0 + PITCH * (col - 1)
            if _dentro((xn, yv), esq, margen) and (f, col) not in asign:
                faltan.append((f, col, xn, yv))
    filas = []
    for i, (f, col, xn, yn, est, _) in enumerate(estados):
        g = grupo[i]
        filas.append(dict(fila=f, col=col, x_nom_mm=xn, y_nom_mm=yn, x_med_mm=xy[i, 0], y_med_mm=xy[i, 1],
                          dx_um=1000 * (xy[i, 0] - xn), dy_um=1000 * (xy[i, 1] - yn),
                          d_eq_um=g["d_eq_um"], dd_um=g["d_eq_um"] - NOMINAL["d_pin_um"],
                          lado_eq_um=g["lado_eq_um"], feret_um=g["feret_um"], minferet_um=g["minferet_um"],
                          circ=g["circ"], area_um2=g["area_um2"], estado=est))
    for f, col, xn, yn in faltan:
        filas.append(dict(fila=f, col=col, x_nom_mm=xn, y_nom_mm=yn, x_med_mm=np.nan, y_med_mm=np.nan,
                          dx_um=np.nan, dy_um=np.nan, d_eq_um=np.nan, dd_um=np.nan, lado_eq_um=np.nan,
                          feret_um=np.nan, minferet_um=np.nan, circ=np.nan, area_um2=np.nan, estado="falta"))
    filas.sort(key=lambda r: (r["fila"], r["col"]))
    return filas, info, esq


def _dentro(p, poly, margen):
    """¿Punto dentro del cuadrilátero (convexo) con un margen hacia dentro?"""
    x, y = p
    n = len(poly)
    area2 = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1] for i in range(n))
    sgn = 1 if area2 > 0 else -1
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        cr = ((x2 - x1) * (y - y1) - (y2 - y1) * (x - x1)) * sgn
        if cr / math.hypot(x2 - x1, y2 - y1) < margen:
            return False
    return True


# ── perfiles, canal, rugosidad, poros ───────────────────────────────────────
TIPO_POR_ETIQUETA = {"gap_pin_tapa": "aire", "altura_cavidad": "aire", "alto_canal": "aire", "ancho_canal": "aire",
                     "altura_pin": "metal", "pared": "metal", "diametro_pin": "metal", "planitud_tapa": "aire"}


def resumir_perfiles(perf: list[dict]) -> dict:
    out = {}
    for et, tipo in TIPO_POR_ETIQUETA.items():
        v = [p["longitud_um"] for p in perf if p["etiqueta"] == et and p["tipo"] == tipo]
        nr = [p["contraste_min"] for p in perf if p["etiqueta"] == et and p["tipo"] == "sin_tramos"]
        if v:
            out[et] = (float(np.mean(v)), float(np.std(v, ddof=1)) if len(v) > 1 else 0.0, len(v))
        if nr:
            out[et + "_no_resuelto"] = (float(np.mean(nr)), 0.0, len(nr))
    pas = []
    for arch in {p["archivo_perfil"] for p in perf if p["etiqueta"] == "paso_pines"}:
        ms = sorted((p["inicio_um"] + p["fin_um"]) / 2 for p in perf if p["archivo_perfil"] == arch and p["tipo"] == "metal")
        pas += list(np.diff(ms))
    if pas:
        out["paso_pines"] = (float(np.mean(pas)), float(np.std(pas, ddof=1)) if len(pas) > 1 else 0.0, len(pas))
    if "altura_cavidad" in out and "gap_pin_tapa" in out:
        out["altura_pin_derivada"] = (out["altura_cavidad"][0] - out["gap_pin_tapa"][0],
                                      math.hypot(out["altura_cavidad"][1], out["gap_pin_tapa"][1]), 0)
    return out


def media_sd(v):
    v = [x for x in v if isinstance(x, float) and not math.isnan(x)]
    if not v:
        return float("nan"), float("nan"), 0
    return float(np.mean(v)), (float(np.std(v, ddof=1)) if len(v) > 1 else 0.0), len(v)


# ── figuras ─────────────────────────────────────────────────────────────────
def figuras(muestra: str, filas: list[dict], esq: np.ndarray, salida: Path, geom: str):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Circle, Rectangle, Polygon

    ok = [r for r in filas if r["estado"] == "ok"]
    cols = sorted({r["col"] for r in filas})
    xlo, xhi = X0 + PITCH * (max(1, cols[0] - 1) - 1) - 0.5, X0 + PITCH * (min(NCOL, cols[-1] + 1) - 1) + 0.5
    ancho = min(16.0, max(6.0, 1.1 * (xhi - xlo) + 2.5))
    fig, ax = plt.subplots(figsize=(ancho, 4.4))
    ax.add_patch(Polygon(esq, closed=True, fc="none", ec="0.6", ls="--", lw=1))
    for f, yv in FILAS_Y.items():
        for c in range(max(1, cols[0] - 1), min(NCOL, cols[-1] + 1) + 1):
            xn = X0 + PITCH * (c - 1)
            r0 = NOMINAL["d_pin_um"] / 2000
            pat = Circle((xn, yv), r0) if geom == "circular" else Rectangle((xn - r0, yv - r0), 2 * r0, 2 * r0)
            pat.set(fc="none", ec="0.75", lw=0.8)
            ax.add_patch(pat)
    if ok:
        vmax = max(10.0, max(abs(r["dd_um"]) for r in ok))
        cmap = plt.get_cmap("RdBu_r")
        for r in ok:
            rr = r["d_eq_um"] / 2000
            col = cmap(0.5 + r["dd_um"] / (2 * vmax))
            pat = Circle((r["x_med_mm"], r["y_med_mm"]), rr) if geom == "circular" else \
                Rectangle((r["x_med_mm"] - rr, r["y_med_mm"] - rr), 2 * rr, 2 * rr)
            pat.set(fc=col, ec="k", lw=0.5)
            ax.add_patch(pat)
        k = 10.0                                  # exageración de las flechas
        ax.quiver([r["x_nom_mm"] for r in ok], [r["y_nom_mm"] for r in ok],
                  [k * r["dx_um"] / 1000 for r in ok], [k * r["dy_um"] / 1000 for r in ok],
                  angles="xy", scale_units="xy", scale=1, width=0.002, color="k")
        sm = plt.cm.ScalarMappable(cmap=cmap, norm=plt.Normalize(-vmax, vmax))
        fig.colorbar(sm, ax=ax, pad=0.01, label="Δd (µm)")
    for r in filas:
        if r["estado"] == "falta":
            ax.plot(r["x_nom_mm"], r["y_nom_mm"], "x", color="#c0392b", ms=12, mew=2.5)
        elif r["estado"] in ("fusionado", "no_asignado", "duplicado"):
            ax.plot(r["x_med_mm"], r["y_med_mm"], "s", mfc="none", mec="#d35400", ms=14, mew=2)
    ax.axhline(0, color="#3a5ba0", lw=0.6, ls=":")
    ax.set_xlim(xlo, xhi)
    ax.set_ylim(-2.7, 2.7)
    ax.set_aspect("equal")
    ax.set_xlabel("x (mm, diseño)")
    ax.set_ylabel("y (mm)")
    ax.set_title(f"{muestra} · color = Δd · flechas = desplazamiento ×10 · ✕ falta · □ fusionado / sin asignar",
                 fontsize=10.5, loc="left")
    fig.tight_layout()
    fig.savefig(salida / f"{muestra}_mapa.png", dpi=130)
    plt.close(fig)

    fig, axs = plt.subplots(1, 3, figsize=(13, 3.6))
    for ax, key, lab in zip(axs, ("dd_um", "dx_um", "dy_um"), ("Δd (µm)", "Δx (µm)", "Δy (µm)")):
        v = [r[key] for r in ok]
        if v:
            ax.hist(v, bins=min(25, max(5, len(v) // 3)), color="#3a5ba0", alpha=0.85)
            ax.axvline(np.mean(v), color="#c0392b", lw=1.5)
            ax.set_title(f"{lab}: media {np.mean(v):+.1f}, σ {np.std(v, ddof=1) if len(v) > 1 else 0:.1f} (n={len(v)})",
                         fontsize=10)
        ax.set_xlabel(lab)
    fig.tight_layout()
    fig.savefig(salida / f"{muestra}_histogramas.png", dpi=130)
    plt.close(fig)


# ── exportación para CST ────────────────────────────────────────────────────
def exportar_asbuilt(muestra: str, filas: list[dict], perf_res: dict, salida: Path, geom: str):
    h = perf_res.get("altura_pin", perf_res.get("altura_pin_derivada", (NOMINAL["altura_pin_um"], 0, 0)))[0]
    fuente_h = "medida" if ("altura_pin" in perf_res or "altura_pin_derivada" in perf_res) else "nominal"
    por_nodo = {(r["fila"], r["col"]): r for r in filas}
    lineas = ["nombre,fila,col,x_mm,y_mm,d_mm,h_mm,estado,fuente_xy_d,fuente_h"]
    for f in FILAS_Y:
        for c in range(1, NCOL + 1):
            xn, yn = nodo_xy(f, c)
            nombre = f"pin{GEN_ROW[f]}_{c - 1:02d}"
            r = por_nodo.get((f, c))
            if r is None:
                x, y, d, est, fu = xn, yn, NOMINAL["d_pin_um"], "nominal", "nominal"
            elif r["estado"] == "falta":
                x, y, d, est, fu = xn, yn, 0.0, "falta", "medida"
            elif r["estado"] == "ok":
                d = r["d_eq_um"] if geom == "circular" else r["lado_eq_um"]
                x, y, est, fu = r["x_med_mm"], r["y_med_mm"], "medido", "medida"
            else:
                x, y, d, est, fu = xn, yn, NOMINAL["d_pin_um"], r["estado"], "nominal"
            lineas.append(f"{nombre},{f},{c},{x:.5f},{y:.5f},{d / 1000:.5f},{h / 1000:.5f},{est},{fu},{fuente_h}")
    (salida / f"pins_asbuilt_{muestra}.csv").write_text("\n".join(lineas) + "\n", encoding="utf-8")


# ── principal ───────────────────────────────────────────────────────────────
def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("carpeta", type=Path)
    ap.add_argument("--salida", type=Path, default=None)
    ap.add_argument("--escala", action="store_true", help="aplicar la escala del ajuste de referencias")
    a = ap.parse_args(argv)
    salida = a.salida or (a.carpeta / "resultados")
    salida.mkdir(parents=True, exist_ok=True)

    pines = leer_csv(a.carpeta / "pines_xy.csv")
    refs = leer_csv(a.carpeta / "referencias.csv")
    perf = leer_csv(a.carpeta / "perfiles.csv")
    canal = leer_csv(a.carpeta / "canal.csv")
    rug = leer_csv(a.carpeta / "rugosidad.csv")
    poros = leer_csv(a.carpeta / "poros.csv")
    muestras = sorted({r["muestra"] for r in pines + perf + canal + rug + poros})
    if not muestras:
        sys.exit(f"No hay CSV de metrología en {a.carpeta}")

    resumen = []
    for m in muestras:
        res = {"muestra": m}
        geom = next((r["geometria"] for r in pines + perf if r["muestra"] == m), "circular")
        todas = []
        grupos = {}
        for r in pines:
            if r["muestra"] == m:
                grupos.setdefault((r["imagen"], r["slice"]), []).append(r)
        info0, esq0 = None, None
        for (img, sl), g in grupos.items():
            rr = [x for x in refs if x["muestra"] == m and x["imagen"] == img and x["slice"] == sl]
            filas, info, esq = analizar_pines(g, rr, geom, a.escala)
            for f in filas:
                f.update(imagen=img, slice=sl)
            todas += filas
            info0, esq0 = info, esq
            print(f"[{m}] {img} corte {int(sl)}: {len(g)} detectados · registro {info['metodo']}"
                  f" · rot {info['rot_deg']:+.2f}° · escala {info['escala']:.4f} · reflexión {info['reflexion']}"
                  f" · residuo ref {info['residuo_ref_um']:.1f} µm · índices {info['indices']}")
        perf_m = [p for p in perf if p["muestra"] == m]
        pres = resumir_perfiles(perf_m)
        if todas:
            claves = list(todas[0].keys())
            txt = [",".join(claves)] + [",".join(f"{r[k]:.5g}" if isinstance(r[k], float) else str(r[k]) for k in claves)
                                        for r in todas]
            (salida / f"pines_{m}.csv").write_text("\n".join(txt) + "\n", encoding="utf-8")
            ok = [r for r in todas if r["estado"] == "ok"]
            res.update(n_detectados=sum(r["estado"] != "falta" for r in todas), n_ok=len(ok),
                       n_faltan=sum(r["estado"] == "falta" for r in todas),
                       n_fusionados=sum(r["estado"] == "fusionado" for r in todas),
                       faltan=" ".join(f"F{r['fila']}C{r['col']}" for r in todas if r["estado"] == "falta"))
            for k, nom in (("d_eq_um", "d"), ("dx_um", "dx"), ("dy_um", "dy"), ("circ", "circ")):
                mu, sd, n = media_sd([r[k] for r in ok])
                res[f"{nom}_media"], res[f"{nom}_sd"] = mu, sd
            res["dxy_rms_um"] = float(np.sqrt(np.mean([r["dx_um"] ** 2 + r["dy_um"] ** 2 for r in ok]))) if ok else float("nan")
            res.update(registro=info0["metodo"], escala=info0["escala"], rot_deg=info0["rot_deg"])
            figuras(m, todas, esq0, salida, geom)
            exportar_asbuilt(m, todas, pres, salida, geom)
        for k, (mu, sd, n) in pres.items():
            res[f"{k}_media_um"], res[f"{k}_sd_um"], res[f"{k}_n"] = mu, sd, n
            nk = f"{k}_um"
            if nk in NOMINAL:
                res[f"{k}_desv_um"] = mu - NOMINAL[nk]
        cm = [c for c in canal if c["muestra"] == m]
        if cm:
            for k in ("ancho_sub_um", "alto_sub_um"):
                mu, sd, n = media_sd([c[k] for c in cm])
                res[f"canal_{k}_media"], res[f"canal_{k}_sd"] = mu, sd
            res["canal_ancho_desv_um"] = res["canal_ancho_sub_um_media"] - NOMINAL["ancho_canal_um"]
            res["canal_alto_desv_um"] = res["canal_alto_sub_um_media"] - NOMINAL["alto_canal_um"]
        rm = [r for r in rug if r["muestra"] == m]
        if rm:
            for k in ("Ra_um", "Rq_um", "Rq_f_um"):
                res[f"rug_{k}_media"], res[f"rug_{k}_sd"], _ = media_sd([r[k] for r in rm])
        pm = [p for p in poros if p["muestra"] == m]
        if pm:
            a_s = sum(p["area_solida_um2"] for p in pm)
            res["porosidad_pct"] = 100 * sum(p["area_poros_um2"] for p in pm) / a_s if a_s else float("nan")
            res["n_poros"] = sum(p["n_poros"] for p in pm)
        resumen.append(res)

    claves = []
    for r in resumen:
        claves += [k for k in r if k not in claves]
    txt = [",".join(claves)] + [",".join(f"{r.get(k, ''):.6g}" if isinstance(r.get(k), float) else str(r.get(k, ""))
                                         for k in claves) for r in resumen]
    (salida / "resumen.csv").write_text("\n".join(txt) + "\n", encoding="utf-8")
    print(f"Resultados en {salida}")
    return resumen


if __name__ == "__main__":
    main()
