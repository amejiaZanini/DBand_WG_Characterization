"""Ejecuta las MISMAS operaciones de gen_cst_macro.py con un motor CSG (manifold3d)
para comprobar el modelo antes de abrir CST: piezas finales, número de pines,
interferencias y cortes. Genera UPM_v2_check.png.

Uso:  python check_geometry.py [rect] [tpl]      (requiere manifold3d, numpy y matplotlib)
"""
import math
import os
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MPoly
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from manifold3d import CrossSection, Manifold

ARGS = sys.argv[1:]
if "rect" in ARGS:                          # python check_geometry.py rect [tpl]
    os.environ["UPM_PINS"] = "rect"
    ARGS.remove("rect")
sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_cst_macro as G  # noqa: E402

SEG = 96
P = {}
for n, v, _ in G.PARAMS:
    P[n] = eval(v, {}, P)
if ARGS:
    P["tpl"] = float(ARGS[0])
    for n, v, _ in G.PARAMS:            # re-evaluar dependientes
        if n != "tpl":
            P[n] = eval(v, {}, P)


def ev(e):
    return float(eval(str(e), {}, P))


S = {}
for op in G.OPS:
    k = op[0]
    if k == "brick":
        _, name, xr, yr, zr = op
        lo = [ev(xr[0]), ev(yr[0]), ev(zr[0])]
        hi = [ev(xr[1]), ev(yr[1]), ev(zr[1])]
        S[name] = Manifold.cube([h - l for l, h in zip(lo, hi)]).translate(lo)
    elif k == "cyl":
        _, name, axis, r, rng, c1, c2, seg = op
        a, b = ev(rng[0]), ev(rng[1])
        n = int(seg) or SEG
        c = Manifold.cylinder(b - a, ev(r), circular_segments=n)
        if axis == "z":
            S[name] = c.translate([ev(c1), ev(c2), a])
        else:                               # eje x: (x,y,z) -> (z, y, -x)
            S[name] = c.rotate([0, 90, 0]).translate([a, ev(c1), ev(c2)])
    elif k == "hex":                        # prisma hexagonal, caras planas hacia ±x
        _, name, xc, yc, z0, h = op
        s = P["hexS"] / 2 + P["tpl"]
        pts = [(s * math.cos(math.radians(a)) / 0.8660254, s * math.sin(math.radians(a)) / 0.8660254)
               for a in (30, 90, 150, 210, 270, 330)]
        S[name] = Manifold.extrude(CrossSection([pts]), ev(h)).translate([ev(xc), ev(yc), ev(z0)])
    elif k == "translate":
        _, name, vec, reps, unite, dest = op
        v = np.array([ev(x) for x in vec])
        if dest:
            S[f"{dest}:{name.split(':')[1]}"] = S[name]
            continue
        acc = S[name]
        for i in range(1, int(reps) + 1):
            acc = acc + S[name].translate(list(v * i))
        S[name] = acc
    elif k == "mirror_y":
        S[op[1]] = S[op[1]] + S[op[1]].mirror([0, 1, 0])
    elif k == "rotate_z180":
        S[op[1]] = S[op[1]] + S[op[1]].rotate([0, 0, 180])
    elif k in ("Add", "Subtract", "Intersect"):
        _, a, b = op
        S[a] = {"Add": S[a] + S[b], "Subtract": S[a] - S[b], "Intersect": S[a] ^ S[b]}[k]
        del S[b]
    elif k == "rename":
        _, a, new = op
        S[f"{a.split(':')[0]}:{new}"] = S.pop(a)

base, tapa = S["Base:base"], S["Tapa:tapa"]
zp = P["zpart"]
print("Sólidos finales:", sorted(S))
for nm, m in (("base", base), ("tapa", tapa)):
    bb = m.bounding_box()
    print(f"  {nm}: piezas={len(m.decompose())}  vol={m.volume():.1f} mm3  "
          f"x[{bb[0]:.3f},{bb[3]:.3f}] y[{bb[1]:.2f},{bb[4]:.2f}] z[{bb[2]:.4f},{bb[5]:.4f}]")
print(f"  interferencia base∩tapa = {(base ^ tapa).volume():.2e} mm3")

polys0 = base.slice(0.0).to_polygons()
apin = (math.pi * (P["dpin"] / 2 - P["tpl"]) ** 2 if G.PIN_SHAPE == "round"
        else (P["wpx"] - 2 * P["tpl"]) * (P["wpy"] - 2 * P["tpl"]))
npins = sum(abs(abs(0.5 * np.sum(p[:, 0] * np.roll(p[:, 1], -1) - np.roll(p[:, 0], -1) * p[:, 1])) - apin) < 0.1 * apin
            for p in polys0)
print(f"  pines en el corte z=0: {npins}")
# altura de pin y gap
pin_top = -P["bWR"] / 2 + P["hpin"]


def count_pins(z):
    return sum(abs(abs(0.5 * np.sum(p[:, 0] * np.roll(p[:, 1], -1) - np.roll(p[:, 0], -1) * p[:, 1])) - apin)
               < 0.1 * apin for p in base.slice(z).to_polygons())


print(f"  pines justo bajo su techo: {count_pins(pin_top - 0.01)}  ·  justo encima: {count_pins(pin_top + 0.01)}")
print(f"  techo (partición) z={zp:.4f}  ·  gap pin-tapa = {zp - pin_top:.3f} mm")


# ── Figura ──────────────────────────────────────────────────────────────────
def draw(ax, polys, color, flip=None, swap=False, lw=0.5, alpha=1.0):
    for p in polys:
        q = p.copy()
        if flip == "zx":                    # (x, -z) -> (x, z)
            q[:, 1] = -q[:, 1]
        if flip == "zy":                    # (-z, y) -> (y, z)
            q = np.c_[q[:, 1], -q[:, 0]]
        ax.add_patch(MPoly(q, closed=True, fc=color, ec="k", lw=lw, alpha=alpha))


def even_odd(ax, polys, color, **kw):
    """Rellena respetando agujeros: dibuja contornos CCW en color y CW en blanco."""
    outer, holes = [], []
    for p in polys:
        area = 0.5 * np.sum(p[:, 0] * np.roll(p[:, 1], -1) - np.roll(p[:, 0], -1) * p[:, 1])
        (outer if area > 0 else holes).append(p)
    draw(ax, outer, color, **kw)
    draw(ax, holes, "white", **kw)


TOP, BOT = "#1f6b45", "#86d24a"
fig = plt.figure(figsize=(18, 20))
gs = fig.add_gridspec(3, 2, height_ratios=[1.15, 1, 0.9])

ax = fig.add_subplot(gs[0, :], projection="3d")
for m, col, dz in ((base, BOT, 0.0), (tapa, TOP, 16.0)):
    mesh = m.to_mesh()
    v = np.asarray(mesh.vert_properties)[:, :3].copy()
    v[:, 2] += dz
    tri = np.asarray(mesh.tri_verts)
    pc = Poly3DCollection(v[tri], fc=col, ec="none", alpha=1.0)
    n = np.cross(v[tri[:, 1]] - v[tri[:, 0]], v[tri[:, 2]] - v[tri[:, 0]])
    n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    shade = 0.45 + 0.55 * np.clip(n @ np.array([0.3, -0.5, 0.8]), 0, 1)
    rgb = np.array(matplotlib.colors.to_rgb(col))
    pc.set_facecolor(np.c_[np.outer(shade, rgb), np.ones(len(shade))])
    ax.add_collection3d(pc)
ax.set_xlim(-36, 36); ax.set_ylim(-24, 24); ax.set_zlim(-14, 30)
ax.set_box_aspect((72, 48, 44))
ax.view_init(elev=28, azim=-60)
ax.set_axis_off()
ax.set_title("Vista explosionada: BASE (cavidad + pines + media brida inferior)  ·  TAPA plana (media brida superior)",
             fontsize=13, fontweight="bold")

ax = fig.add_subplot(gs[1, 0])
even_odd(ax, polys0, BOT)
ax.set_title(f"BASE · corte z = 0 (mitad de la cavidad) · {npins} pines", fontsize=12, fontweight="bold", loc="left")
ax.set_xlim(-37, 37); ax.set_ylim(-22, 22); ax.set_aspect("equal"); ax.tick_params(labelsize=8)

ax = fig.add_subplot(gs[1, 1])
even_odd(ax, tapa.slice(P["zpart"] + P["Hhalf"] - 1.0).to_polygons(), TOP)
draw(ax, [p for p in tapa.slice(zp + 0.05).to_polygons()
          if 0.5 * np.sum(p[:, 0] * np.roll(p[:, 1], -1) - np.roll(p[:, 0], -1) * p[:, 1]) < 0],
     "none", lw=0.8)
ax.set_title("TAPA · corte a 1 mm de la cara superior (tuercas, A redondo, B ranura)", fontsize=12,
             fontweight="bold", loc="left")
ax.set_xlim(-37, 37); ax.set_ylim(-22, 22); ax.set_aspect("equal"); ax.tick_params(labelsize=8)

ax = fig.add_subplot(gs[2, 0])
for m, col in ((base, BOT), (tapa, TOP)):
    even_odd(ax, m.rotate([90, 0, 0]).slice(0.0).to_polygons(), col, flip="zx")
ax.axhline(zp, color="#c0392b", ls="-.", lw=1)
ax.set_title("Corte ZX (y = 0): boca a boca 68.24, discos dentro de la longitud", fontsize=12,
             fontweight="bold", loc="left")
ax.set_xlim(-37, 37); ax.set_ylim(-11, 11); ax.set_aspect("equal"); ax.tick_params(labelsize=8)

ax = fig.add_subplot(gs[2, 1])
xf = -P["Lwg"] / 2 + P["tboss"] + 0.5
for m, col in ((base, BOT), (tapa, TOP)):
    even_odd(ax, m.rotate([0, -90, 0]).slice(xf).to_polygons(), col, flip="zy")
ax.axhline(zp, color="#c0392b", ls="-.", lw=1)
ax.set_title("Corte ZY a 0.5 mm de la cara del disco (brida izquierda)", fontsize=12, fontweight="bold", loc="left")
ax.set_xlim(-21, 21); ax.set_ylim(-11, 11); ax.set_aspect("equal"); ax.tick_params(labelsize=8)

fig.tight_layout()
out = Path(__file__).resolve().parent / f"UPM_v2{G.SUFFIX}_check.png"
fig.savefig(out, dpi=110, facecolor="white")
print(out)


# ── Centrado y alineación ───────────────────────────────────────────────────
def area(p):
    return 0.5 * np.sum(p[:, 0] * np.roll(p[:, 1], -1) - np.roll(p[:, 0], -1) * p[:, 1])


def centroid(p):
    a = area(p)
    x, y = p[:, 0], p[:, 1]
    c = x * np.roll(y, -1) - np.roll(x, -1) * y
    return (np.sum((x + np.roll(x, -1)) * c) / (6 * a), np.sum((y + np.roll(y, -1)) * c) / (6 * a))


def holes(m, z, dmax=4.0):
    """Agujeros cerrados (contornos CW) de diámetro equivalente < dmax en el corte z."""
    out = []
    for p in m.slice(z).to_polygons():
        a = area(p)
        if a < 0 and 2 * math.sqrt(-a / math.pi) < dmax:
            out.append((*centroid(p), 2 * math.sqrt(-a / math.pi)))
    return out


hb, ht = holes(base, zp - 0.05), holes(tapa, zp + 0.05)
print("\nAgujeros en la cara de unión (base z = zpart-0.05 · tapa z = zpart+0.05):")
print(f"  {'agujero':<9}{'x base':>9}{'y base':>9}{'Ø base':>8}{'x tapa':>9}{'y tapa':>9}{'Ø tapa':>8}{'desvío µm':>11}")
worst = 0.0
names = {(-P["xab"], P["yab"]): "A", (P["xab"], -P["yab"]): "B"}
for xb, yb, db in sorted(hb, key=lambda h: (round(h[1], 1), h[0])):
    xt, yt, dt = min(ht, key=lambda h: math.hypot(h[0] - xb, h[1] - yb))
    dev = 1000 * math.hypot(xt - xb, yt - yb)
    worst = max(worst, dev)
    tag = next((n for (x, y), n in names.items() if math.hypot(x - xb, y - yb) < 0.5), "tornillo")
    print(f"  {tag:<9}{xb:9.3f}{yb:9.3f}{db:8.3f}{xt:9.3f}{yt:9.3f}{dt:8.3f}{dev:11.2f}")
print(f"  -> {len(hb)} agujeros en la base, {len(ht)} en la tapa; desvío máximo base-tapa = {worst:.2f} µm")

# centroide de TODO el corte z = 0 (cuerpo con cavidad, canal, pines y agujeros): debe ser (0, 0)
_sec = base.slice(0.0).to_polygons()
_A = sum(area(p) for p in _sec)
cx = sum(area(p) * centroid(p)[0] for p in _sec) / _A
cy = sum(area(p) * centroid(p)[1] for p in _sec) / _A
pins = [centroid(p) for p in base.slice(0.0).to_polygons() if abs(abs(area(p)) - apin) < 0.1 * apin]
px, py = np.mean([c[0] for c in pins]), np.mean([c[1] for c in pins])
print(f"  centroide del corte z=0 de la base = ({cx:+.4f}, {cy:+.4f})  ·  centro del bosque de pines = ({px:+.4f}, {py:+.4f})")
fl = holes(base.rotate([0, -90, 0]), -P["Lwg"] / 2 + P["tboss"] + 0.5) + \
     holes(tapa.rotate([0, -90, 0]), -P["Lwg"] / 2 + P["tboss"] + 0.5)
fr = holes(base.rotate([0, -90, 0]), P["Lwg"] / 2 - P["tboss"] - 0.5) + \
     holes(tapa.rotate([0, -90, 0]), P["Lwg"] / 2 - P["tboss"] - 0.5)
# en el corte girado: (u, v) = (-z, y). Brida derecha = izquierda girada 180° en z -> (z, y) -> (z, -y)
L = sorted((round(-u, 3), round(v, 3), round(d, 3)) for u, v, d in fl)
R = sorted((round(-u, 3), round(-v, 3), round(d, 3)) for u, v, d in fr)
print(f"  brida derecha = izquierda girada 180°: {'SÍ' if L == R else 'NO'}  ({len(L)} agujeros por brida)")

# Holguras mínimas (analíticas, con tpl)
rh_flat = P["hexS"] / 2 + P["tpl"]                 # semientrecaras (hacia ±x)
rh_vert = rh_flat / 0.8660254                      # semidiagonal (hacia ±y)
rs = P["dsc"] / 2 + P["tpl"]
ztop = zp + P["Hhalf"]
y_up = math.sqrt(P["Rdisc"] ** 2 - ztop ** 2)       # el disco asoma sobre la tapa si |y| < y_up
y_dn = math.sqrt(P["Rdisc"] ** 2 - (zp - P["Hhalf"]) ** 2)
x_disc = P["Lwg"] / 2 - P["tboss"] - P["tdisc"]
x_end = P["Lwg"] / 2 - P["tboss"]
xrow = 3 * P["xsc"]
chk = [
    ("pared tornillo de fila - cavidad", P["ysc"] - rs - P["Wcav"] / 2 - P["tpl"]),
    ("resina entre tuercas vecinas (caras planas)", P["xsc"] - 2 * rh_flat),
    ("tuerca exterior de fila - disco que asoma", x_disc - xrow - rh_flat),
    ("tuerca de esquina - disco que asoma (en y)", P["yce"] - rh_vert - y_up),
    ("tuerca de esquina - cara de brida (en x)", x_end - P["xce"] - rh_flat),
    ("cabeza M2.5 (Ø4.5) de esquina - disco bajo la base", P["yce"] - 2.25 - y_dn),
    ("tuerca de esquina - tuerca de fila", math.hypot(P["xce"] - xrow, P["yce"] - P["ysc"]) - 2 * rh_vert),
    ("agujero A/B - tuerca más cercana", min(math.hypot(P["xab"] - x, P["yab"] - y) for x, y in
     [(k * P["xsc"], P["ysc"]) for k in range(-3, 4)] + [(P["xce"], P["yce"])]) - rh_vert - P["dab"] / 2),
    ("agujero A/B - borde exterior", P["Wbody"] / 2 - P["yab"] - P["dab"] / 2),
]
print("\nHolguras mínimas (mm):")
for txt, v in chk:
    print(f"  {txt:<52}{v:7.2f}  {'OK' if v >= 0.4 else 'REVISAR'}")

# Figura de alineación: cara de unión de la base con los agujeros de la tapa superpuestos
fig, axs = plt.subplots(1, 3, figsize=(19, 6.4), gridspec_kw=dict(width_ratios=[2.2, 1, 1]))
ax = axs[0]
even_odd(ax, base.slice(zp - 0.05).to_polygons(), BOT, lw=0.4)
for x, y, d in ht:
    ax.add_patch(plt.Circle((x, y), d / 2, fc="none", ec="#c0392b", lw=1.2, ls="--"))
for (x, y), n in names.items():
    ax.text(x, y + 2.4, n, ha="center", fontsize=13, fontweight="bold")
ax.plot(0, 0, "+", color="k", ms=14, mew=1.5)
ax.set_title("Cara de unión de la BASE (verde) con los agujeros de la TAPA (rojo discontinuo)",
             fontsize=12, fontweight="bold", loc="left")
ax.set_xlim(-37, 37); ax.set_ylim(-21, 21); ax.set_aspect("equal"); ax.tick_params(labelsize=8)
for ax, ((x0, y0), n) in zip(axs[1:], names.items()):
    xb, yb, db = min(hb, key=lambda h: math.hypot(h[0] - x0, h[1] - y0))
    xt, yt, dt = min(ht, key=lambda h: math.hypot(h[0] - x0, h[1] - y0))
    ax.add_patch(plt.Circle((xb, yb), db / 2, fc="#dff2d0", ec=BOT, lw=3))
    ax.add_patch(plt.Circle((xt, yt), dt / 2, fc="none", ec="#c0392b", lw=1.5, ls="--"))
    ax.plot([xb], [yb], "+", color=BOT, ms=18, mew=2)
    ax.plot([xt], [yt], "x", color="#c0392b", ms=12, mew=1.5)
    ax.set_xlim(x0 - 2.2, x0 + 2.2); ax.set_ylim(y0 - 2.2, y0 + 2.2); ax.set_aspect("equal")
    ax.tick_params(labelsize=8)
    ax.set_title(f"Pasador {n} (zoom)", fontsize=12, fontweight="bold", loc="left")
    ax.text(0.5, 0.04, f"base ({xb:.3f}, {yb:.3f}) Ø{db:.3f}\ntapa ({xt:.3f}, {yt:.3f}) Ø{dt:.3f}\n"
            f"desvío {1000 * math.hypot(xt - xb, yt - yb):.2f} µm", transform=ax.transAxes, ha="center",
            fontsize=10, bbox=dict(fc="white", ec="0.7"))
fig.tight_layout()
out2 = Path(__file__).resolve().parent / f"UPM_v2{G.SUFFIX}_alineacion.png"
fig.savefig(out2, dpi=110, facecolor="white")
print(out2)
