"""Carga una serie de capturas de VGSTUDIO (.tif RGB) como volumen gris recortado.

Uso:
    python3 cargar_stack.py <carpeta_tif> <carpeta_trabajo>

Guarda <carpeta_trabajo>/top_vol.npy con forma (n_cortes, 200, 860), uint8.
El recorte (filas 930-1130, columnas 600-1460 de la imagen completa) contiene la
sección de la guía en la serie Ni/Capturas_ROI/TOP; los demás scripts usan ese origen.
"""
import os
import sys
import time

import numpy as np
from PIL import Image

Y0, Y1, X0, X1 = 930, 1130, 600, 1460   # recorte en coordenadas de imagen completa (px)


def main(src, dst):
    files = sorted(f for f in os.listdir(src) if f.lower().endswith(".tif"))
    if not files:
        sys.exit(f"No hay .tif en {src}")
    t0 = time.time()
    vol = np.zeros((len(files), Y1 - Y0, X1 - X0), np.uint8)
    for i, name in enumerate(files):
        vol[i] = np.asarray(Image.open(os.path.join(src, name)).convert("L"))[Y0:Y1, X0:X1]
    os.makedirs(dst, exist_ok=True)
    np.save(os.path.join(dst, "top_vol.npy"), vol)
    print(f"{vol.shape} en {time.time() - t0:.1f} s -> {dst}/top_vol.npy")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
