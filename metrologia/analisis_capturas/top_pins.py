"""Per-pin analysis of the Ni ROI TOP stack (replicates the Fiji procedure: T, fill holes, particles)."""
import sys, json
import numpy as np
from scipy import ndimage as ndi
from scipy.optimize import least_squares

S = sys.argv[1]
V = np.load(f"{S}/top_vol.npy").astype(float)          # (504, 200, 860), origin y=930, x=600
Y0, X0 = 930, 600
DZ = 13.72                                            # um per slice (labels -3.16..3.74 mm / 503)
ROWS_X = np.array([886.5, 945.0, 1095.0, 1152.5])     # pin rows (full-image px), from max projection
LAST = 432                                            # slices >= 433: flange region (no pins)
YC0, YC1, XC0, XC1 = 990, 1070, 850, 1190             # particle crop (channel interior)
YMID = 1028                                           # mid pin height row

def cross(p, T, i0, step):
    """Sub-pixel position where profile p crosses T walking from i0 in direction step."""
    i = i0
    while 0 <= i + step < len(p):
        a, b = p[i], p[i + step]
        if (a - T) * (b - T) <= 0 and a != b:
            return i + step * (T - a) / (b - a)
        i += step
    return np.nan

def analyse(T, s_xy):
    amin = 20000 / s_xy**2
    out = []                                           # rows: slice,row,bx0,bx1,by0,by1,area,wmid
    for k in range(LAST + 1):
        img = V[k, YC0 - Y0:YC1 - Y0, XC0 - X0:XC1 - X0]
        b = ndi.binary_fill_holes(img >= T)
        lab, n = ndi.label(b, structure=np.ones((3, 3)))
        if n == 0:
            continue
        objs = ndi.find_objects(lab)
        areas = ndi.sum(b, lab, range(1, n + 1))
        merged = {}
        for j, sl in enumerate(objs):
            if areas[j] < amin:
                continue
            ys, xs = sl
            if ys.start == 0 or xs.start == 0 or ys.stop == b.shape[0] or xs.stop == b.shape[1]:
                continue                               # exclude on edges
            xc = XC0 + (xs.start + xs.stop - 1) / 2
            r = int(np.argmin(abs(ROWS_X - xc)))
            if abs(ROWS_X[r] - xc) > 30:
                continue
            m = merged.setdefault(r, [1e9, -1e9, 1e9, -1e9, 0])
            m[0] = min(m[0], XC0 + xs.start); m[1] = max(m[1], XC0 + xs.stop - 1)
            m[2] = min(m[2], YC0 + ys.start); m[3] = max(m[3], YC0 + ys.stop - 1)
            m[4] += areas[j]
        prof = V[k, YMID - Y0 - 2:YMID - Y0 + 3, :].mean(axis=0)
        for r, m in merged.items():
            c = int(round(ROWS_X[r] - X0))
            pk = c - 15 + int(np.argmax(prof[c - 15:c + 16]))
            xl = cross(prof, T, pk, -1); xr = cross(prof, T, pk, +1)
            out.append([k, r, *m, (xr - xl) if prof[pk] >= T else np.nan, X0 + xl, X0 + xr])
    return np.array(out, float)

def runs(sl):
    sl = np.sort(sl); out = []; st = sl[0]
    for a, b in zip(sl[:-1], sl[1:]):
        if b - a > 3:
            out.append((st, a)); st = b
    out.append((st, sl[-1])); return out

def chord_fit(z, w):
    """Fit w = 2 sqrt(r^2 - (z - z0)^2) (um)."""
    f = lambda p: 2 * np.sqrt(np.clip(p[0]**2 - (z - p[1])**2, 0, None)) - w
    p = least_squares(f, [w.max() / 2, z[np.argmax(w)]]).x
    return abs(p[0]) * 2, p[1]

def pins(res, s_xy):
    pins_out = []
    for r in range(4):
        R = res[res[:, 1] == r]
        if len(R) == 0:
            continue
        for a, b in runs(R[:, 0]):
            P = R[(R[:, 0] >= a) & (R[:, 0] <= b)]
            if len(P) < 8:
                continue
            z = P[:, 0] * DZ; wb = (P[:, 3] - P[:, 2] + 1) * s_xy; wm = P[:, 7] * s_xy
            ok = np.isfinite(wm)
            dmid, z0 = chord_fit(z[ok], wm[ok]) if ok.sum() >= 6 else (np.nan, np.nan)
            dfoot, _ = chord_fit(z, wb)
            cen = np.abs(z - z0) <= 3 * DZ
            h = np.median((P[cen, 5] - P[cen, 4] + 1)) * s_xy if cen.any() else np.nan
            ytop = np.median(P[cen, 4]) if cen.any() else np.nan
            xl = np.median(P[cen, 8]); xr = np.median(P[cen, 9])
            pins_out.append(dict(row=r + 1, s0=int(a), s1=int(b), z0_um=z0, d_mid_um=dmid, d_foot_um=dfoot,
                                 h_um=h, ytop=ytop, xl=xl, xr=xr, n=len(P)))
    return pins_out

if __name__ == "__main__":
    res = {}
    for T in (91, 99.4, 107):
        for s in (13.636, 13.76):
            r = analyse(T, s)
            res[f"{T}_{s}"] = pins(r, s)
            if T == 99.4 and s == 13.636:
                np.save(f"{S}/particles_T99.npy", r)
    json.dump(res, open(f"{S}/pins.json", "w"), default=float, indent=1)
    print("ok")
