# DBand_WG_Characterization

Medida de parámetros S de prototipos de guías de onda en banda D (110–170 GHz) con VNA Keysight PNA.

## Descripción

Script de adquisición para caracterizar prototipos de guías de onda fabricados con distintos métodos. Mide S11, S31, S13 y S33 usando los puertos 1 y 3 del VNA, con calibración TRL/SOLT previa.

**Características:**
- Calibración única al inicio de la sesión (sin recalibrar entre prototipos)
- Referencia THRU antes y después del batch
- Time-sweep: N medidas por prototipo, cada una guardada como `.mat` individual con timestamp
- Organización automática de datos: `data/Session/ProtoNombre/ProtoNombre_YYYY-MM-DD-HHMMSS.mat`
- Configuración centralizada en `config.yaml`

## Estructura del proyecto

```
DBand_WG_Characterization/
├── config.yaml          # Parámetros del VNA y la sesión de medida
├── VNA_Coms.py          # Clase VNAMeasurement (PyVISA + SCPI, Keysight PNA)
├── WG_CalSetup.py       # Configuración del VNA + calibración TRL/SOLT
├── WG_Main.py           # Sesión de medida de prototipos
└── data/                # Directorio de salida (generado automáticamente)
    └── Session_YYYY-MM-DD/
        ├── thru_before_YYYY-MM-DD-HHMMSS.mat
        ├── thru_after_YYYY-MM-DD-HHMMSS.mat
        └── <ProtoNombre>/
            ├── <ProtoNombre>_YYYY-MM-DD-HHMMSS.mat
            └── ...
```

## Uso

### 1. Editar `config.yaml`

```yaml
vna:
  device: "USB0::0x0AAD::0x0240::101285::0::INSTR"
  freq_start_ghz: 110
  freq_stop_ghz:  170
  n_points:       2001
  if_bw_hz:       3000
  cal_file:       ""      # rellenado automáticamente por WG_CalSetup.py

measurement:
  n_repeats:        10
  sweep_interval_s:  3.5
  n_thru_averages:   5

output:
  directory: "data/Session_2026-09-08"
```

### 2. Calibrar el VNA (primera vez o sesión nueva)

```bash
python WG_CalSetup.py
```

Sigue las instrucciones en pantalla:
1. El script configura las trazas en el VNA.
2. Realiza la calibración TRL o SOLT manualmente en el VNA.
3. Guarda el archivo `.cal` en el Cal Pool del VNA.
4. El script aplica la calibración a los 4 canales y guarda el nombre en `config.yaml`.

### 3. Medir prototipos

```bash
python WG_Main.py
```

Si ya existe un `cal_file` en `config.yaml` (de una sesión anterior), se reutiliza sin recalibrar.

El flujo guiado por pantalla:
1. Configura el VNA (ONCE) y aplica la calibración.
2. Mide referencia THRU (promedio de `n_thru_averages` sweeps).
3. Introduce cuántos prototipos vas a medir.
4. Para cada prototipo: monta las guías, da OK → time-sweep → archivos .mat.
5. Al terminar el batch: opción de añadir más prototipos.
6. Mide referencia THRU final.

## Dependencias

```
pyvisa
numpy
scipy
pyyaml
```

Instalar:
```bash
pip install pyvisa numpy scipy pyyaml
```

## Notas importantes

- **No llamar `WG_CalSetup.py` mientras `WG_Main.py` está en curso**: reconfigura las trazas del VNA (`CALC:PAR:DEL:ALL`) y rompe el enlace con el Cal Pool.
- **Puertos 1 y 3**: el VNA mide S11, S31, S13, S33 — no S21/S12.
- **Formato `.mat`**: compatible con MATLAB y Python (`scipy.io.loadmat`). Cada archivo contiene `freq_ghz`, `S11`, `S31`, `S13`, `S33` como vectores complejos de longitud `n_points`.
