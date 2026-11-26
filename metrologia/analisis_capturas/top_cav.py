"""Cavity height per slice: lid/base line peaks at channel centre (inner = channel-side peak)."""
import sys, json, numpy as np
S = sys.argv[1]
V = np.load(f"{S}/top_vol.npy").astype(float); Y0, X0 = 930, 600
LAST = 432; XA, XB = 1005, 1035

def peaks(v, lo, hi, thr):
    out = []
    for i in range(lo + 1, hi - 1):
        if v[i] >= v[i - 1] and v[i] > v[i + 1] and v[i] > thr:
            a, b, c = v[i - 1], v[i], v[i + 1]; den = a - 2 * b + c
            out.append(i + (0.5 * (a - c) / den if den != 0 else 0))
    return out

rows = []
for k in range(LAST + 1):
    v = V[k, :, XA - X0:XB - X0].mean(axis=1)
    base = np.median(v[1010 - Y0:1040 - Y0]); thr = base + 6
    lid = peaks(v, 985 - Y0, 1012 - Y0, thr); bas = peaks(v, 1045 - Y0, 1072 - Y0, thr)
    if lid and bas:
        rows.append([k, Y0 + max(lid), Y0 + min(bas), Y0 + min(lid), Y0 + max(bas), len(lid), len(bas)])
R = np.array(rows)
json.dump(R.tolist(), open(f"{S}/cav.json", "w"))
for s in (13.636, 13.76):
    inner = (R[:, 2] - R[:, 1]) * s; outer = (R[:, 4] - R[:, 3]) * s
    dbl = ((R[:, 5] > 1) | (R[:, 6] > 1)).mean() * 100
    print(f"s={s}: n={len(R)}  interior={inner.mean():.0f}±{inner.std(ddof=1):.0f} (p5-p95 {np.percentile(inner,5):.0f}-{np.percentile(inner,95):.0f})"
          f"  exterior={outer.mean():.0f}±{outer.std(ddof=1):.0f}  lineas dobles en {dbl:.0f}% de cortes")
for k in (50, 150, 250, 350, 385):
    r = R[R[:, 0] == k]
    if len(r): r = r[0]; print(k, "int", round((r[2]-r[1])*13.636, 1), "ext", round((r[4]-r[3])*13.636, 1), "picos", r[1:5].round(2))
