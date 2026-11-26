"""Outer pin width at several heights (outer edge of both walls, ISO crossing at T) + chord fit per pin."""
import sys, json, numpy as np
from scipy.optimize import least_squares
S = sys.argv[1]
V = np.load(f"{S}/top_vol.npy").astype(float); Y0, X0 = 930, 600
DZ = 13.72; ROWS = [886.5, 945.0, 1095.0, 1152.5]; LAST = 432
HEIGHTS = {"alto": 1010, "medio": 1028, "bajo": 1046}   # rows (full px): near top, mid, near foot

def outer(p, T, c, half=24):
    w = p[c - half:c + half + 1]; idx = np.where(w >= T)[0]
    if len(idx) == 0 or idx[0] == 0 or idx[-1] == len(w) - 1: return np.nan, np.nan
    i, j = idx[0], idx[-1]
    xl = i - 1 + (T - w[i - 1]) / (w[i] - w[i - 1]); xr = j + (w[j] - T) / (w[j] - w[j + 1])
    return c - half + xl, c - half + xr

def fit(z, w):
    f = lambda q: 2 * np.sqrt(np.clip(q[0]**2 - (z - q[1])**2, 0, None)) - w
    q = least_squares(f, [w.max() / 2, z[np.argmax(w)]]).x; return 2 * abs(q[0]), q[1]

def run(T, s):
    out = {}
    for name, yr in HEIGHTS.items():
        res = []
        for r, cx in enumerate(ROWS):
            c = int(round(cx - X0)); recs = []
            for k in range(LAST + 1):
                p = V[k, yr - Y0 - 2:yr - Y0 + 3, :].mean(axis=0)
                xl, xr = outer(p, T, c)
                if np.isfinite(xl): recs.append((k, xl + X0, xr + X0))
            recs = np.array(recs)
            if len(recs) == 0: continue
            ks = recs[:, 0]; br = np.where(np.diff(ks) > 3)[0]
            for seg in np.split(np.arange(len(ks)), br + 1):
                if len(seg) < 10: continue
                z = ks[seg] * DZ; w = (recs[seg, 2] - recs[seg, 1]) * s
                d, z0 = fit(z, w)
                cen = np.abs(z - z0) <= 2 * DZ
                xc = np.median((recs[seg, 1][cen] + recs[seg, 2][cen]) / 2) if cen.any() else np.nan
                res.append(dict(row=r + 1, s0=int(ks[seg][0]), s1=int(ks[seg][-1]), d=d, z0=z0, xc=xc, wmax=w.max()))
        out[name] = res
    return out

R = {f"{T}_{s}": run(T, s) for T in (91, 99.4, 107) for s in (13.636, 13.76)}
json.dump(R, open(f"{S}/mid.json", "w"), indent=1, default=float)
for key, o in R.items():
    line = [key]
    for name, res in o.items():
        d = np.array([x["d"] for x in res if x["s1"] - x["s0"] >= 15])
        line.append(f"{name}: {d.mean():5.0f}±{d.std(ddof=1):3.0f} (n={len(d)})")
    print("  ".join(line))
o = R["99.4_13.636"]["medio"]
xs = {r: np.nanmedian([x["xc"] for x in o if x["row"] == r and x["s1"] - x["s0"] >= 15]) for r in (1, 2, 3, 4)}
print("filas xc (px):", {k: round(v, 2) for k, v in xs.items()})
for s in (13.636, 13.76):
    print(f"  s={s}: 1-2={(xs[2]-xs[1])*s:.0f}  2-3={(xs[3]-xs[2])*s:.0f}  3-4={(xs[4]-xs[3])*s:.0f}  1-4={(xs[4]-xs[1])*s:.0f} um  (nom 800/2051/800/3651)")
print("escala que da 1-4 nominal:", round(3651 / (xs[4] - xs[1]), 3), "um/px")
