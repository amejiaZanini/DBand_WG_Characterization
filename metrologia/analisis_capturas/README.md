# Análisis de las capturas de VGSTUDIO (TAC) — Ni, ROI, vista TOP

Los `.tif` de `Scaner_Resultados/` son **capturas de pantalla de VGSTUDIO**: RGB de 8 bits,
con rótulos, ventana de gris y barra de escala. No son cortes en bruto del volumen.
Estos scripts repiten sobre la serie completa el procedimiento validado a mano en Fiji:
umbral ISO‑50, rellenar huecos, partículas y perfiles.

## Uso

```bash
python3 cargar_stack.py "../../Scaner_Resultados/reports/Ni/Capturas_ROI/TOP" <trabajo>   # ≈ 40 s
python3 top_pins.py <trabajo>     # partículas por pin            -> pins.json, particles_T99.npy
python3 top_mid.py  <trabajo>     # diámetro exterior a 3 alturas -> mid.json (+ distancias entre filas en pantalla)
python3 top_cav.py  <trabajo>     # cavidad por corte             -> cav.json
python3 top_fig.py  <trabajo>     # figura de 4 paneles           -> Ni_ROI_TOP_resultados.png
```

Se necesita `numpy`, `scipy`, `Pillow` y `matplotlib` (`python3 -m pip install matplotlib`).
`top_vol.npy` (≈ 87 MB) no se guarda en el repositorio porque se regenera con el primer paso.

## Parámetros (serie Ni/Capturas_ROI/TOP)

| Parámetro | Valor | Origen |
|---|---|---|
| Escala x‑y | 13.636 µm/px (también se prueba 13.76) | Barra de 3 mm = 220 / 218 px |
| Separación entre cortes | 13.72 µm | Rótulos: −3.16 → 3.74 mm en 504 cortes |
| Umbral T | 99.4 (se prueban 91 y 107) | (aire del canal + pico del pin) / 2 en 3 cortes con pines |
| Cortes válidos | 0–432 | Los cortes 433–503 son la brida (boca WR‑6.5), sin pines |
| Filas de pines (x, px) | 886.5 / 945.0 / 1095.0 / 1152.5 | Proyección de máximos |
| Tapa / base (y, px) | ≈ 997 / ≈ 1059 | Perfil medio |

## Método

- **Diámetro:** entre los bordes exteriores de las dos paredes del pin, porque el pin se ve hueco
  (artefacto). Se ajusta la cuerda w(z) = 2√(r² − (z − z₀)²) a lo largo de los cortes, a 3 alturas.
  Las columnas 1 y 8 quedan cortadas por el borde del stack o por la brida y se excluyen de la media.
- **Cavidad:** distancia entre los picos de las líneas de tapa y base. Si una línea sale doble, se
  toma el pico del lado del canal.

## Resultados (`resultados/Ni_ROI_TOP/`)

| Magnitud | Medido | Nominal | ¿Fiable con capturas? |
|---|---|---|---|
| Paso entre columnas | 794 ± 13 µm | 800 | Sí |
| Distancia entre filas 1‑2 / 2‑3 / 3‑4 | 808 / 2037 / 781 µm | 800 / 2051 / 800 | Sí (±1–2 %) |
| Pin que falta | Fila 2, columna 6 de la ROI (corte ≈ 298) | — | Sí |
| Diámetro a media altura (23 pines) | 404 ± 5 µm; 395–416 según T | 400 | Sí, ±10 µm |
| Conicidad (arriba → pie) | 393 → 408 µm | — | Indicio |
| Cavidad | 816 ± 39 µm | 820 | La media sí; corte a corte no |
| Gap pin–tapa | No resuelto (≈ 3.7 px) | 50 | No |

`datos/Ni_ROI_TOP_fiji_summary_T99.csv` es el *Summary* de *Analyze Particles* obtenido a mano en Fiji
(T = 99.4), que sirve de contraste.

**Limitaciones:** 8 bits con ventana de gris, 13.6 µm/px, líneas dobles en las superficies y pines
de aspecto hueco. Para medir el gap y la rugosidad hace falta exportar los cortes en bruto (16 bits,
vóxel nativo) o reescanear la ROI a ≤ 5 µm.
