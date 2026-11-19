"""Ejecuta las MISMAS operaciones de gen_cst_macro.py con un motor CSG (manifold3d)
para comprobar el modelo antes de abrir CST: piezas finales, número de pines,
interferencias y cortes. Genera UPM_v2_check.png.

Uso:  python check_geometry.py [tpl]      (requiere manifold3d, numpy y matplotlib)
"""
import math
import sys
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MPoly
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from manifold3d import Manifold

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_cst_macro as G  # noqa: E402

SEG = 40
P = {}
for n, v, _ in G.PARAMS:
    P[n] = eval(v, {}, P)
if len(sys.argv) > 1:
    P["tpl"] = float(sys.argv[1])
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
apin = math.pi * (P["dpin"] / 2 - P["tpl"]) ** 2
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
out = Path(__file__).resolve().parent / "UPM_v2_check.png"
fig.savefig(out, dpi=110, facecolor="white")
print(out)
