"""
WG_Main.py
──────────
Sesión de medida de prototipos de guías de onda en banda D (110–170 GHz).

Flujo:
  [A] Leer config.yaml  →  conectar al VNA y configurar trazas (ONCE).
  [B] Aplicar calibración del Cal Pool (cal_file de config.yaml).
  [C] Medir referencia THRU antes del batch (n_thru_averages sweeps, promediados).
  [D] Preguntar cuántos prototipos se van a medir.
  [E] Para cada prototipo:
        – Pedir nombre del prototipo.
        – Esperar OK del operador (guías ajustadas y listas).
        – Time-sweep: N_repeats medidas, una cada sweep_interval_s.
        – Guardar cada medida como .mat individual con timestamp.
  [F] Al terminar el batch: ¿medir más prototipos? → volver a [E].
  [G] Medir referencia THRU al final del batch.
  [H] Guardar THRU final y mostrar resumen.

Estructura de salida (config.yaml → output.directory):
  data/Session_YYYY-MM-DD/
    thru_before_YYYY-MM-DD-HHMMSS.mat
    thru_after_YYYY-MM-DD-HHMMSS.mat
    <ProtoNombre>/
      <ProtoNombre>_YYYY-MM-DD-HHMMSS.mat   ← una por repetición

Uso:
  python WG_Main.py
  (Ejecutar WG_CalSetup.py antes para calibrar el VNA si no hay calibración guardada.)
"""

import os
import sys
from datetime import datetime
from time import sleep, time

import numpy as np
import yaml
from scipy.io import savemat

from VNA_Coms import VNAMeasurement


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

def _load_config(path="config.yaml"):
    with open(path) as f:
        return yaml.safe_load(f)


# ---------------------------------------------------------------------------
# VNA controller
# ---------------------------------------------------------------------------

class VNAController:
    """Wrapper around VNAMeasurement for waveguide characterization.

    setup() is called ONCE at session start — it issues CALC:PAR:DEL:ALL
    internally, which breaks any active cal pool link.  After apply_cal() the
    calibration is active for the whole session; never call setup() again.
    """

    def __init__(self, cfg):
        self.cfg = cfg
        self.vna = VNAMeasurement(device=cfg["device"])

    def setup(self):
        """Configure 4 windows (S11/S31/S13/S33) on ports 1 and 3.
        Call ONCE before apply_cal — not again during the batch.
        """
        c = self.cfg
        self.vna.setup_traces_S11_S13_S31_S33(
            c["freq_start_ghz"],
            c["freq_stop_ghz"],
            c["n_points"],
            bw=c["if_bw_hz"],
        )

    def apply_cal(self, cal_file, channels=(1, 2, 3, 4)):
        """Load cal_file from the VNA Cal Pool into every channel."""
        pna = self.vna.pna
        for ch in channels:
            pna.write(f"MMEM:LOAD:CORR {ch},'{cal_file}'")
            sleep(0.3)
        pna.query("*OPC?")

        print("\n  Verificando calibración en los canales:")
        all_ok = True
        for ch in channels:
            loaded = pna.query(f"MMEM:LOAD:CORR? {ch}").strip().strip("'\"")
            ok = loaded.lower() == cal_file.lower()
            print(f"  CH{ch}: '{loaded}'  {'✓' if ok else '✗'}")
            if not ok:
                all_ok = False
        return all_ok

    def _wait_sweep(self):
        """Wait for one complete VNA sweep across all 4 channels."""
        c = self.cfg
        sleep(4 * c["n_points"] / c["if_bw_hz"] * 1.3)

    def acquire(self):
        """Return (S11, S31, S13, S33) as complex 1-D numpy arrays."""
        self._wait_sweep()
        s11_r, s11_i = self.vna.get_data(1, "S11_Real")
        s31_r, s31_i = self.vna.get_data(2, "S31_Real")
        s13_r, s13_i = self.vna.get_data(3, "S13_Real")
        s33_r, s33_i = self.vna.get_data(4, "S33_Real")
        return (
            s11_r + 1j * s11_i,
            s31_r + 1j * s31_i,
            s13_r + 1j * s13_i,
            s33_r + 1j * s33_i,
        )

    def freq_axis_ghz(self):
        """Return the frequency axis in GHz matching the VNA config."""
        c = self.cfg
        return np.linspace(c["freq_start_ghz"], c["freq_stop_ghz"], c["n_points"])


# ---------------------------------------------------------------------------
# Data manager
# ---------------------------------------------------------------------------

class DataManager:
    def __init__(self, outdir):
        self.outdir = outdir
        os.makedirs(outdir, exist_ok=True)

    def prototype_dir(self, proto_name):
        d = os.path.join(self.outdir, proto_name)
        os.makedirs(d, exist_ok=True)
        return d

    def _ts(self):
        return datetime.now().strftime("%Y-%m-%d-%H%M%S")

    def save_mat(self, subfolder, base_name, data_dict):
        ts = self._ts()
        filename = os.path.join(subfolder, f"{base_name}_{ts}.mat")
        savemat(filename, data_dict)
        print(f"  [SAVE] {filename}")
        return filename

    def save_thru(self, label, freq_ghz, s11, s31, s13, s33):
        ts = self._ts()
        filename = os.path.join(self.outdir, f"thru_{label}_{ts}.mat")
        savemat(filename, {
            "freq_ghz": freq_ghz,
            "S11": s11,
            "S31": s31,
            "S13": s13,
            "S33": s33,
        })
        print(f"  [SAVE] {filename}")
        return filename


# ---------------------------------------------------------------------------
# Calibration helper
# ---------------------------------------------------------------------------

def _ensure_calibration(vna_ctrl, cfg_vna):
    """Apply calibration from config, or prompt the operator for the file name."""
    cal_file = cfg_vna.get("cal_file", "").strip()

    if not cal_file:
        print()
        print("  No hay archivo de calibración en config.yaml.")
        print("  Ejecuta WG_CalSetup.py primero, o introduce el nombre ahora.")
        while True:
            cal_file = input("  Nombre del .cal (o ENTER para abortar): ").strip()
            if not cal_file:
                print("[ABORTADO] Sin calibración.")
                sys.exit(1)
            if not cal_file.lower().endswith(".cal"):
                cal_file += ".cal"
            break

    print(f"\n  Aplicando calibración: '{cal_file}'")
    ok = vna_ctrl.apply_cal(cal_file)
    if not ok:
        print("\n  ✗ Algún canal no confirmó el archivo de calibración.")
        print("    Comprueba el nombre exacto en el Cal Pool del VNA.")
        resp = input("  Continuar igualmente? [s/N]: ")
        if resp.strip().lower() != "s":
            print("[ABORTADO]")
            sys.exit(1)
    else:
        print("  ✓ Calibración aplicada correctamente.")


# ---------------------------------------------------------------------------
# Thru measurement
# ---------------------------------------------------------------------------

def measure_thru(vna_ctrl, data_mgr, n_averages, label="before"):
    """Average n_averages sweeps with ports in THRU configuration.

    Prompts the operator to connect the thru standard before measuring.
    """
    print()
    print("─" * 60)
    print(f"  REFERENCIA THRU  ({label})")
    print("─" * 60)
    print("  Conecta los cabezales en configuración THRU (puerto 1 → puerto 3).")
    input("  Pulsa ENTER cuando estés listo... ")

    freq = vna_ctrl.freq_axis_ghz()
    n_pts = len(freq)
    acc = [np.zeros(n_pts, dtype=complex) for _ in range(4)]

    print(f"  Midiendo {n_averages} sweeps para promediar...")
    for k in range(n_averages):
        s11, s31, s13, s33 = vna_ctrl.acquire()
        acc[0] += s11
        acc[1] += s31
        acc[2] += s13
        acc[3] += s33
        print(f"  Sweep {k + 1}/{n_averages}")

    avg = [a / n_averages for a in acc]
    fname = data_mgr.save_thru(label, freq, avg[0], avg[1], avg[2], avg[3])
    print(f"  ✓ Thru '{label}' guardado.")
    return fname


# ---------------------------------------------------------------------------
# Prototype time-sweep
# ---------------------------------------------------------------------------

def measure_prototype(vna_ctrl, data_mgr, proto_name, n_repeats, sweep_interval_s):
    """Time-sweep for one prototype: N_repeats acquisitions, one .mat each.

    The operator is prompted to mount the prototype before measurement starts.
    The sweep_interval_s is an ADDITIONAL wait on top of the VNA sweep time
    (which is already handled inside vna_ctrl.acquire()).
    """
    print()
    print("═" * 60)
    print(f"  PROTOTIPO: {proto_name}")
    print("═" * 60)
    print("  Monta el prototipo y ajusta las bridas.")
    input("  Pulsa ENTER cuando el prototipo esté listo para medir... ")

    proto_dir = data_mgr.prototype_dir(proto_name)
    freq = vna_ctrl.freq_axis_ghz()

    print(f"\n  Time-sweep: {n_repeats} medidas  (intervalo ~{sweep_interval_s:.1f}s + sweep)\n")
    t0 = time()
    for rep in range(1, n_repeats + 1):
        s11, s31, s13, s33 = vna_ctrl.acquire()
        data_dict = {
            "freq_ghz": freq,
            "S11": s11,
            "S31": s31,
            "S13": s13,
            "S33": s33,
        }
        data_mgr.save_mat(proto_dir, proto_name, data_dict)

        elapsed = time() - t0
        remaining = n_repeats - rep
        eta = remaining * (elapsed / rep) if rep else 0
        print(
            f"  [{rep:>2}/{n_repeats}]  elapsed {elapsed:5.0f}s  "
            f"ETA {eta:5.0f}s"
        )

        if rep < n_repeats:
            sleep(sweep_interval_s)

    print(f"\n  ✓ {proto_name}: {n_repeats} medidas guardadas en '{proto_dir}'")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    cfg = _load_config()
    vc = cfg["vna"]
    mc = cfg["measurement"]
    outdir = cfg["output"]["directory"]

    print()
    print("═" * 60)
    print("  MEDIDA DE GUÍAS DE ONDA  —  BANDA D (110–170 GHz)")
    print("═" * 60)

    # ── [A] Conectar al VNA y configurar trazas ──────────────────────────────
    print("\n[A] Conectando al VNA y configurando trazas (S11, S31, S13, S33)...")
    vna = VNAController(vc)
    vna.setup()   # ONCE — no volver a llamar durante el batch
    print(f"  Rango  : {vc['freq_start_ghz']} – {vc['freq_stop_ghz']} GHz")
    print(f"  Puntos : {vc['n_points']}")
    print(f"  IF BW  : {vc['if_bw_hz']} Hz")
    print(f"  Trazas : S11 (CH1)  S31 (CH2)  S13 (CH3)  S33 (CH4)  — puertos 1 y 3")

    data = DataManager(outdir)

    # ── [B] Aplicar calibración ───────────────────────────────────────────────
    print("\n[B] Aplicando calibración del Cal Pool...")
    _ensure_calibration(vna, vc)

    # ── [C] Thru antes del batch ─────────────────────────────────────────────
    print("\n[C] Midiendo referencia THRU (antes del batch)...")
    measure_thru(vna, data, mc["n_thru_averages"], label="before")

    # ── [D–F] Bucle de prototipos ─────────────────────────────────────────────
    print()
    while True:
        resp = input("[D] ¿Cuántos prototipos vas a medir en este batch? (número): ").strip()
        if resp.isdigit() and int(resp) > 0:
            n_prototypes = int(resp)
            break
        print("  Introduce un número entero > 0.")

    completed = []
    for i in range(n_prototypes):
        print()
        print(f"  ── Prototipo {i + 1} / {n_prototypes} ──")
        while True:
            name = input("  Nombre del prototipo (sin espacios, p.ej. Proto_WG_01): ").strip()
            if name:
                break
            print("  El nombre no puede estar vacío.")

        measure_prototype(vna, data, name, mc["n_repeats"], mc["sweep_interval_s"])
        completed.append(name)

    # ── [F] ¿Medir más prototipos? ────────────────────────────────────────────
    while True:
        print()
        print(f"  Batch completado: {completed}")
        resp = input("  ¿Medir más prototipos? [s/N]: ").strip().lower()
        if resp != "s":
            break

        while True:
            extra = input("  ¿Cuántos prototipos adicionales? (número): ").strip()
            if extra.isdigit() and int(extra) > 0:
                n_extra = int(extra)
                break
            print("  Introduce un número entero > 0.")

        for i in range(n_extra):
            print()
            print(f"  ── Prototipo adicional {i + 1} / {n_extra} ──")
            while True:
                name = input("  Nombre del prototipo: ").strip()
                if name:
                    break
                print("  El nombre no puede estar vacío.")
            measure_prototype(vna, data, name, mc["n_repeats"], mc["sweep_interval_s"])
            completed.append(name)

    # ── [G] Thru después del batch ────────────────────────────────────────────
    print("\n[G] Midiendo referencia THRU (después del batch)...")
    measure_thru(vna, data, mc["n_thru_averages"], label="after")

    # ── [H] Resumen ───────────────────────────────────────────────────────────
    print()
    print("═" * 60)
    print("  ✓  SESIÓN COMPLETADA")
    print("═" * 60)
    print(f"  Directorio: {outdir}")
    print(f"  Prototipos medidos ({len(completed)}):")
    for name in completed:
        print(f"    • {name}  ({mc['n_repeats']} medidas)")
    print()


if __name__ == "__main__":
    main()
