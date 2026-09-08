"""
WG_CalSetup.py
──────────────
Workflow de calibración para medida de guías de onda en banda D (110–170 GHz).

Pasos:
  1. Aplica la configuración del VNA (config.yaml) — frecuencias, IF BW, trazas.
  2. Guía al operador en la calibración TRL/SOLT manual (puertos 1 y 3).
  3. Aplica el archivo .cal a los 4 canales vía SCPI y verifica.
  4. Guarda el nombre del .cal en config.yaml para reutilizarlo en WG_Main.py.
  5. (Opcional) lanza WG_Main.py.

Uso:
  python WG_CalSetup.py
"""

import re
import subprocess
import sys
from time import sleep

import yaml

from VNA_Coms import VNAMeasurement


def _load_config(path="config.yaml"):
    with open(path) as f:
        return yaml.safe_load(f)


def _save_cal_to_config(cal_file, path="config.yaml"):
    """Actualiza la línea cal_file en config.yaml preservando el resto del archivo."""
    with open(path) as f:
        content = f.read()
    new_line = f'  cal_file: "{cal_file}"'
    if re.search(r'^\s*cal_file:', content, re.MULTILINE):
        content = re.sub(r'^\s*cal_file:.*', new_line, content, flags=re.MULTILINE)
    else:
        content = re.sub(r'(  if_bw_hz:.*\n)', r'\1' + new_line + '\n', content, count=1)
    with open(path, "w") as f:
        f.write(content)
    print(f"  [CONFIG] cal_file guardado en config.yaml → '{cal_file}'")


def _apply_calgroup(pna, cal_file, channels=(1, 2, 3, 4)):
    """Aplica cal_file a cada canal, bloquea en *OPC? y verifica."""
    for ch in channels:
        pna.write(f"MMEM:LOAD:CORR {ch},'{cal_file}'")
        sleep(0.3)
    pna.query("*OPC?")

    print("\n  Verificando aplicación del archivo de calibración:")
    all_ok = True
    for ch in channels:
        loaded = pna.query(f"MMEM:LOAD:CORR? {ch}").strip().strip("'\"")
        match = loaded.lower() == cal_file.lower()
        print(f"  Canal {ch}: '{loaded}'  {'✓' if match else '✗'}")
        if not match:
            all_ok = False
    return all_ok


def main():
    cfg = _load_config()
    vc = cfg["vna"]
    N_CHANNELS = 4

    print()
    print("═" * 62)
    print("  CONFIGURACIÓN VNA  +  CALIBRACIÓN  —  BANDA D (110–170 GHz)")
    print("═" * 62)

    # ── 1. Conectar y configurar trazas ───────────────────────────────────────
    print("\n[1/3] Conectando al VNA y aplicando configuración...")
    vna = VNAMeasurement(device=vc["device"])
    vna.setup_traces_S11_S13_S31_S33(
        vc["freq_start_ghz"],
        vc["freq_stop_ghz"],
        vc["n_points"],
        bw=vc["if_bw_hz"],
    )
    print(f"  Rango  : {vc['freq_start_ghz']} – {vc['freq_stop_ghz']} GHz")
    print(f"  Puntos : {vc['n_points']}")
    print(f"  IF BW  : {vc['if_bw_hz']} Hz")
    print(f"  Trazas : S11 (CH1)  S31 (CH2)  S13 (CH3)  S33 (CH4)  — puertos 1 y 3")
    print("\n  [OK] Configuración aplicada. El VNA tiene la malla de frecuencias")
    print("       correcta — la calibración no mostrará 'Cal Int'.")

    # ── 2. Calibración ────────────────────────────────────────────────────────
    print()
    print("─" * 62)
    print("[2/3] CALIBRACIÓN")
    print("─" * 62)

    existing_cal = vc.get("cal_file", "").strip()
    cal_file = None

    if existing_cal:
        print(f"\n  Calibración guardada en config: '{existing_cal}'")
        resp = input("  ¿Reutilizar esta calibración? [S/n]: ")
        if resp.strip().lower() != "n":
            cal_file = existing_cal

    if cal_file is None:
        print()
        print("  Pasos a seguir en el VNA:")
        print("    1. Inicia el asistente de calibración  (Cal → Start Cal)")
        print("    2. Selecciona calibración TRL o SOLT de 2 puertos (puertos 1 y 3)")
        print("    3. Sigue los pasos del asistente con los estándares de calibración")
        print("    4. Al finalizar, guarda en el Cal Pool del VNA:")
        print("          Cal → Pool → Store  (p.ej. 'TRL_110_170GHz_WG.cal')")
        print()
        input("  Pulsa ENTER cuando hayas guardado la calibración en el Cal Pool... ")

        while True:
            resp = input("  ¿Calibración guardada correctamente en el Cal Pool? [s/N]: ")
            if resp.strip().lower() == "s":
                break
            print("  Guarda la calibración antes de continuar.")

        while True:
            cal_file = input("  Nombre del archivo .cal: ").strip()
            if cal_file:
                break
            print("  El nombre no puede estar vacío.")
        if not cal_file.lower().endswith(".cal"):
            cal_file += ".cal"

    # ── 3. Aplicar calibración vía SCPI ───────────────────────────────────────
    print()
    print("─" * 62)
    print("[3/3] APLICANDO CALIBRACIÓN A LOS CANALES")
    print("─" * 62)
    print(f"\n  Aplicando '{cal_file}' a los {N_CHANNELS} canales via SCPI...")
    success = _apply_calgroup(vna.pna, cal_file, channels=range(1, N_CHANNELS + 1))

    print()
    if success:
        _save_cal_to_config(cal_file)
        print("═" * 62)
        print("  ✓  CALIBRACIÓN APLICADA Y GUARDADA EN CONFIG CORRECTAMENTE")
        print("═" * 62)
    else:
        print("═" * 62)
        print("  ✗  ADVERTENCIA: algún canal no confirmó el archivo esperado.")
        print("     Comprueba el nombre exacto del archivo en el Cal Pool del VNA.")
        print("═" * 62)
        resp = input("\n  Continuar igualmente? [s/N]: ")
        if resp.strip().lower() != "s":
            print("[ABORTADO]")
            sys.exit(1)

    # ── 4. Lanzar medida ──────────────────────────────────────────────────────
    print()
    resp = input("  ¿Iniciar sesión de medida ahora? (ejecuta WG_Main.py) [S/n]: ")
    if resp.strip().lower() != "n":
        print("\n[INICIO] Lanzando WG_Main.py...\n")
        subprocess.run([sys.executable, "WG_Main.py"], check=False)
    else:
        print("\n  Lanza la medida con:  python WG_Main.py")


if __name__ == "__main__":
    main()
