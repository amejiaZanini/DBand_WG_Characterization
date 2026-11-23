"""Prueba de extremo a extremo de Metrologia_EBG.ijm y analizar_metrologia.py con imágenes sintéticas.

Genera cortes de TAC sintéticos con valores conocidos (pines desplazados, uno que falta,
diámetros variables, gap de 50 µm, canal, una pared con ondulación conocida y poros),
ejecuta las funciones de medida de la macro en ImageJ sin interfaz (las mismas que
llaman los atajos F3–F8, pero con la selección fijada) y compara con la verdad.

Uso:  python prueba_macros.py <ruta a ij.jar> [carpeta de trabajo]
      (ij.jar: https://repo1.maven.org/maven2/net/imagej/ij/1.54f/ij-1.54f.jar)
"""
import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

AQUI = Path(__file__).resolve().parent
MACRO = AQUI.parent / "fiji" / "Metrologia_EBG.ijm"
AIRE, METAL, RUIDO = 1000.0, 3000.0, 60.0
rng = np.random.default_rng(7)


def borroso(img, sigma=1.0):
    k = np.arange(-4, 5)
    g = np.exp(-k ** 2 / (2 * sigma ** 2)); g /= g.sum()
    img = np.apply_along_axis(lambda v: np.convolve(v, g, mode="same"), 0, img)
    return np.apply_along_axis(lambda v: np.convolve(v, g, mode="same"), 1, img)


def supermuestreo(func, w, h, vox, ss=4):
    """Rasteriza con supermuestreo (volumen parcial) una función indicadora en µm."""
    ys, xs = np.mgrid[0:h * ss, 0:w * ss]
    m = func((xs + 0.5) * vox / ss, (ys + 0.5) * vox / ss).astype(float)
    return m.reshape(h, ss, w, ss).mean(axis=(1, 3))


def guardar(img, ruta):
    v = AIRE + (METAL - AIRE) * img
    v = borroso(v, 1.0) + rng.normal(0, RUIDO, v.shape)
    Image.fromarray(np.clip(v, 0, 65535).astype(np.uint16)).save(ruta)


def generar(carpeta: Path):
    verdad = {}
    vox = 11.0
    # 1) Pines en XY (ROI de 8 columnas). Imagen: x hacia la derecha, y hacia ABAJO; giro de 1.5°.
    th = math.radians(1.5)
    cols = range(10, 18)
    filas_y = {1: 1825.5, 2: 1025.5, 3: -1025.5, 4: -1825.5}
    pines = []
    for f, yv in filas_y.items():
        for c in cols:
            if (f, c) == (2, 13):
                continue                                   # pin que falta
            d = 410 + rng.normal(0, 6)
            if (f, c) == (4, 15):
                d = 470                                    # pin gordo
            dx, dy = rng.normal(0, 8, 2)
            pines.append((f, c, -31200 + 800 * (c - 1) + dx, yv + dy, d))
    xs_d = np.array([p[2] for p in pines]); ys_d = np.array([p[3] for p in pines])
    x0, y0 = xs_d.mean(), 0.0
    W, H = 640, 470
    def a_imagen(x, y):                                    # diseño (µm) -> imagen (µm)
        u = (x - x0) * math.cos(th) - (y - y0) * math.sin(th)
        v = (x - x0) * math.sin(th) + (y - y0) * math.cos(th)
        return u + W * vox / 2, -v + H * vox / 2           # y de imagen hacia abajo
    cen = [a_imagen(p[2], p[3]) for p in pines]
    def ind_pines(X, Y):
        m = np.zeros_like(X, dtype=bool)
        for (cx, cy), p in zip(cen, pines):
            m |= (X - cx) ** 2 + (Y - cy) ** 2 <= (p[4] / 2) ** 2
        return m
    guardar(supermuestreo(ind_pines, W, H, vox), carpeta / "sint_pines.tif")
    ref = {}
    for (cx, cy), p in zip(cen, pines):
        ref[(p[0], p[1])] = (cx / vox, cy / vox)
    verdad["pines"] = pines
    verdad["refs"] = [(*ref[(1, 10)], 1, 10), (*ref[(1, 17)], 1, 17), (*ref[(4, 11)], 4, 11)]

    # 2) Corte longitudinal: suelo, pines de 770 µm, gap de 50 µm, tapa.
    W2, H2 = 300, 160
    z_suelo = 400.0
    def ind_long(X, Y):
        z = (H2 * vox - Y)                                 # z hacia arriba
        suelo = z < z_suelo
        tapa = z > z_suelo + 820
        pin = (np.mod(X - 200, 800) < 400) & (z < z_suelo + 770)
        return suelo | tapa | pin
    guardar(supermuestreo(ind_long, W2, H2, vox), carpeta / "sint_long.tif")
    verdad["gap"], verdad["cavidad"] = 50.0, 820.0
    # 3) Sección del canal: hueco 1651 × 820 en metal.
    W3, H3 = 220, 140
    def ind_canal(X, Y):
        return ~((np.abs(X - W3 * vox / 2) < 825.5) & (np.abs(Y - H3 * vox / 2) < 410))
    guardar(supermuestreo(ind_canal, W3, H3, vox), carpeta / "sint_canal.tif")
    # 4) Pared con ondulación: borde en y = 400 + 5 sin(2πx/200) + 3 sin(2πx/1000) µm (metal debajo).
    W4, H4 = 400, 80
    def ind_pared(X, Y):
        return Y > 400 + 5 * np.sin(2 * np.pi * X / 200) + 3 * np.sin(2 * np.pi * X / 1000)
    guardar(supermuestreo(ind_pared, W4, H4, vox, ss=8), carpeta / "sint_pared.tif")
    # 5) Poros en un bloque de metal (vóxel 45.335): Ø 180 y 250 µm (Ø 60 no debe contarse).
    v5 = 45.335
    W5 = H5 = 120
    poros = [(1500, 1500, 180), (3500, 2500, 250), (2500, 4000, 60)]
    def ind_poros(X, Y):
        m = np.ones_like(X, dtype=bool)
        for cx, cy, d in poros:
            m &= (X - cx) ** 2 + (Y - cy) ** 2 > (d / 2) ** 2
        return m
    guardar(supermuestreo(ind_poros, W5, H5, v5), carpeta / "sint_poros.tif")
    return verdad


def macro_de_prueba(carpeta: Path, verdad) -> str:
    lib = MACRO.read_text(encoding="utf-8").splitlines()
    lib = [l for l in lib if not l.startswith("macro ")]   # solo variables y funciones
    o = str(carpeta) + "/"
    r = verdad["refs"]
    t = f"""
gOut = "{o}"; gMuestra = "SINT"; gMaterial = "Ni"; gGeom = "circular"; gEscaneo = "ROI"; gVoxel = 11;
open("{o}sint_pines.tif"); setVoxelSize(11, 11, 11, "um");
makeRectangle(20, 20, 600, 430); getStatistics(a, mean);
registrarNiveles({AIRE}, {RUIDO}, {METAL}, {RUIDO});
n = medirPines(20, 20, 600, 430, "ISO50", (gAire + gMetal) / 2, 160, 760, true, true, true);
print("PINES " + n);
registrarReferencias(newArray({r[0][0]}, {r[1][0]}, {r[2][0]}), newArray({r[0][1]}, {r[1][1]}, {r[2][1]}),
                     newArray({r[0][2]}, {r[1][2]}, {r[2][2]}), newArray({r[0][3]}, {r[1][3]}, {r[2][3]}));
close("*");
open("{o}sint_long.tif"); setVoxelSize(11, 11, 11, "um");
xp = (200 + 800 + 200) / 11; makeLine(xp, 159, xp, 1);   // por el centro de un pin, de abajo arriba
medirPerfil("gap_pin_tapa", 50, "sesion", gAire, gMetal, 3);
xa = (200 + 400 + 200) / 11; makeLine(xa, 159, xa, 1);   // entre pines: suelo -> tapa
medirPerfil("altura_cavidad", 820, "sesion", gAire, gMetal, 3);
close("*");
open("{o}sint_canal.tif"); setVoxelSize(11, 11, 11, "um");
medirCanal(30, 20, 160, 100, (gAire + gMetal) / 2);
close("*");
open("{o}sint_pared.tif"); setVoxelSize(11, 11, 11, "um");
makeLine(10, 400 / 11, 390, 400 / 11);
medirRugosidad(66, 250, (gAire + gMetal) / 2);
close("*");
open("{o}sint_poros.tif"); setVoxelSize(45.335, 45.335, 45.335, "um"); gVoxel = 45.335; gEscaneo = "general";
medirPoros(5, 5, 110, 110, 1, 1, (gAire + gMetal) / 2, 136);
close("*");
newImage("pila", "16-bit black", 100, 80, 20); setVoxelSize(11, 11, 22, "um");
makeLine(10, 40, 90, 40); t = resliceLinea(); getPixelSize(u, pw, ph, pd);
print("RESLICE " + t + " " + getWidth() + "x" + getHeight() + " " + pw + " " + ph);
print("FIN");
"""
    return "\n".join(lib) + "\n" + t


def leer(ruta):
    import csv
    with open(ruta, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def main():
    ij = Path(sys.argv[1])
    carpeta = Path(sys.argv[2]) if len(sys.argv) > 2 else AQUI / "_salida"
    carpeta.mkdir(parents=True, exist_ok=True)
    for f in carpeta.glob("*.csv"):
        f.unlink()
    verdad = generar(carpeta)
    m = carpeta / "prueba.ijm"
    m.write_text(macro_de_prueba(carpeta, verdad), encoding="utf-8")
    import shutil
    cmd = ["java", "-jar", str(ij), "-batch", str(m)]
    if shutil.which("xvfb-run"):                 # ImageJ necesita una pantalla (virtual) para open()
        cmd = ["xvfb-run", "-a"] + cmd
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    log = r.stdout + r.stderr
    print("\n".join(l for l in log.splitlines() if not l.startswith("Picked up")))
    assert "FIN" in log, "la macro no terminó"

    fallos = []
    def comprobar(nombre, valor, esperado, tol):
        ok = abs(valor - esperado) <= tol
        print(f"  {'OK ' if ok else 'MAL'} {nombre}: {valor:.2f} (esperado {esperado:.2f} ± {tol})")
        if not ok:
            fallos.append(nombre)

    pin = leer(carpeta / "pines_xy.csv")
    comprobar("nº de pines detectados", len(pin), len(verdad["pines"]), 0)
    d_med = np.mean([float(p["d_eq_um"]) for p in pin if float(p["d_eq_um"]) < 450])
    d_ver = np.mean([p[4] for p in verdad["pines"] if p[4] < 450])
    comprobar("diámetro medio (µm)", d_med, d_ver, 4)
    perf = leer(carpeta / "perfiles.csv")
    gap = [float(p["longitud_um"]) for p in perf if p["etiqueta"] == "gap_pin_tapa" and p["tipo"] == "aire"]
    cav = [float(p["longitud_um"]) for p in perf if p["etiqueta"] == "altura_cavidad" and p["tipo"] == "aire"]
    comprobar("gap pin-tapa (µm)", gap[0] if gap else -1, 50, 4)
    comprobar("altura de cavidad (µm)", cav[0] if cav else -1, 820, 4)
    can = leer(carpeta / "canal.csv")[0]
    comprobar("ancho del canal (µm)", float(can["ancho_sub_um"]), 1651, 4)
    comprobar("alto del canal (µm)", float(can["alto_sub_um"]), 820, 4)
    rug = leer(carpeta / "rugosidad.csv")[0]
    rq_ver = math.sqrt(5 ** 2 / 2 + 3 ** 2 / 2)
    comprobar("Rq sin filtro (µm)", float(rug["Rq_um"]), rq_ver, 1.2)
    por = leer(carpeta / "poros.csv")[0]
    comprobar("nº de poros ≥ 136 µm", float(por["n_poros"]), 2, 0)
    comprobar("reslice creado", float("RESLICE" in log), 1, 0)

    sys.path.insert(0, str(AQUI.parent))
    import analizar_metrologia as A
    res = A.main([str(carpeta)])[0]
    comprobar("analizador: pines que faltan", float(res["n_faltan"]), 1, 0)
    print(f"     faltan: {res['faltan']} (esperado F2C13)")
    if res["faltan"].strip() != "F2C13":
        fallos.append("pin que falta mal identificado")
    pf = leer(carpeta / "resultados" / "pines_SINT.csv")
    gordo = [p for p in pf if p["fila"] == "4" and p["col"] == "15"]
    comprobar("analizador: pin gordo F4C15 Δd (µm)", float(gordo[0]["dd_um"]) if gordo else -1, 70, 5)
    reales = {(p[0], p[1]): p for p in verdad["pines"]}
    errs = []
    for p in pf:
        if p["estado"] == "ok":
            v = reales[(int(p["fila"]), int(p["col"]))]
            errs.append(math.hypot(float(p["x_med_mm"]) * 1000 - v[2], float(p["y_med_mm"]) * 1000 - v[3]))
    comprobar("analizador: error de posición rms (µm, ≤ ½ vóxel)", float(np.sqrt(np.mean(np.square(errs)))), 0, 5.5)
    print("\nRESULTADO:", "TODO OK" if not fallos else f"FALLOS: {fallos}")
    sys.exit(1 if fallos else 0)


if __name__ == "__main__":
    main()
