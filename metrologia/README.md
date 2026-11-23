# Metrología de las guías EBG a partir de TAC (Fiji + Python)

Herramientas para medir la fabricación de las muestras (impresión metálica Ni y Cu, y más
adelante la de resina + electrodeposición) sobre las pilas `.tiff` del escáner de la UPC y
compararla con el diseño. El objetivo final es construir un **modelo CST "tal como se
fabricó"** y separar cuánto de la degradación medida viene de la fabricación y cuánto del
diseño.

| Archivo | Qué hace |
|---|---|
| `fiji/Metrologia_EBG.ijm` | 8 herramientas para Fiji (atajos F1–F8) que miden sobre **tu selección** |
| `analizar_metrologia.py` | Lee los CSV, alinea los pines con la rejilla nominal, detecta los que faltan o están fusionados, calcula desviaciones y exporta los pines para CST |
| `pruebas/prueba_macros.py` | Prueba de extremo a extremo con imágenes sintéticas de valor conocido |

## 1. Instalación

1. Fiji ▸ **Plugins ▸ Macros ▸ Install…** ▸ `metrologia/fiji/Metrologia_EBG.ijm`.
   Las herramientas aparecen en *Plugins ▸ Macros* y con las teclas **F1–F8**. Para tenerlas
   siempre, copia el archivo a `Fiji.app/macros/StartupMacros.fiji.ijm` o instálalo en cada sesión.
2. Python 3 con `numpy` y `matplotlib` para el análisis.

## 2. Flujo de trabajo en Fiji

Abre la pila `.tiff`, con *File ▸ Import ▸ Image Sequence* si viene en archivos sueltos.

| Tecla | Herramienta | Qué seleccionas | Qué guarda |
|---|---|---|---|
| **F1** | Configurar sesión | — (diálogo): muestra, material, geometría, escaneo, vóxel, carpeta | `sesiones.csv`; calibra la imagen (µm) |
| **F2** | Niveles aire / metal | Un rectángulo en aire y otro en metal macizo (p. ej. la brida) | `niveles.csv`; fija el umbral **ISO‑50** de la sesión |
| **F3** | Pines en corte XY | Un **rectángulo** sobre los pines, en un corte a **media altura del pin**; después, 3 pines de referencia | `pines_xy.csv`, `referencias.csv`, `control/pines_*.png` |
| **F4** | Reslice por fila | Una **línea** a lo largo de una fila de pines, por su centro | Una imagen nueva con el corte longitudinal |
| **F5** | Perfil: bordes | Una **línea** que cruce los bordes a medir, y qué mides (gap, altura de cavidad, pared…) | `perfiles.csv`, `perfiles/perfil_*.csv` |
| **F6** | Sección del canal | Un **rectángulo** alrededor de la sección del canal | `canal.csv` (ancho y alto sub‑vóxel) |
| **F7** | Rugosidad de una pared | Una **línea** paralela a la pared, encima del borde | `rugosidad.csv`, `perfiles/rugosidad_*.csv` |
| **F8** | Poros por corte | Un **rectángulo** de metal y un rango de cortes | `poros.csv`, `poros_lista.csv` |

**Pines de referencia (F3).** Con la herramienta *Multi‑point* marca A y B en la **misma fila**,
lo más separados posible, y C en **otra fila**. Después escribe su fila y columna:
- **Filas, de un lado a otro del canal:** 1 = exterior, 2 = interior | canal | 3 = interior, 4 = exterior.
  Elige un lado como filas 1–2 y mantenlo siempre.
- **Columnas:** 1–79 desde la boca de referencia.

Con esto el análisis da índices **absolutos**, que permiten llevar cada pin a CST. Sin
referencias, los índices son relativos.

### Qué medir en cada tipo de escaneo

| | General (vóxel 45.335 µm) | ROI (vóxel ≈ 11 µm) |
|---|---|---|
| Pines: posición, paso, que faltan o están fusionados | **Sí** (todos los pines) | Sí |
| Diámetro del pin (Ø400 ≈ 9 vóxeles / 36 vóxeles) | Orientativo (±23 µm) | **Sí** (±6 µm) |
| Gap pin–tapa (50 µm ≈ 1.1 / 4.5 vóxeles) | **No se resuelve**: queda como «sin_tramos», con su contraste | **Sí** |
| Altura de cavidad (820 µm) y de pin (770 µm) | Sí | Sí |
| Ancho y alto del canal | Sí | Sí |
| Alabeo o planitud de la tapa (varios perfiles a lo largo) | Sí | En la zona del ROI |
| Rugosidad | No | Solo ondulación ≥ 2–3 vóxeles (no es Ra de perfilómetro) |
| Poros | ≥ 136 µm | ≥ 33 µm |

**Recomendación de medidas por muestra:**
- **General:** F3 en 2–3 cortes a media altura del pin. F5 con varios perfiles de *altura_cavidad* a lo largo de la guía, que dan el alabeo. F6 al inicio, centro y final.
- **ROI:** F3 en el corte a media altura. F4 por cada fila visible y F5 con *gap_pin_tapa* en cada pin. F5 con *altura_cavidad* entre pines. F7 en 2–3 paredes. F8.

**Criterio y límites:**
- Los bordes se toman al 50 % entre aire y metal (ISO‑50), con interpolación sub‑vóxel.
- Un rasgo de menos de unos 2 vóxeles no se mide.
- Incertidumbre orientativa: ±½ vóxel en bordes aislados.
- Mide los niveles (F2) en cada pila: dependen del escaneo.
- Los pines que parecen huecos suelen ser un artefacto del haz (centro oscuro). F3 los rellena con la opción «incluir huecos interiores».

## 3. Análisis

```bash
python metrologia/analizar_metrologia.py <carpeta_de_los_csv>
```

| Salida (en `<carpeta>/resultados/`) | Contenido |
|---|---|
| `pines_<muestra>.csv` | Un pin por fila: fila, columna, posición nominal y medida, Δx, Δy, d_eq, Δd, circularidad, estado (`ok`, `falta`, `fusionado`, `no_asignado`, `duplicado`) |
| `<muestra>_mapa.png` | Mapa sobre la rejilla nominal: color = Δd, flechas = desplazamiento ×10, ✕ = falta |
| `<muestra>_histogramas.png` | Histogramas de Δd, Δx, Δy |
| `pins_asbuilt_<muestra>.csv` | Los 316 pines para CST: x, y, d y h en mm. Los no medidos quedan nominales y los `falta` no se crean |
| `resumen.csv` | Una fila por muestra: pines, alturas, gap, canal, rugosidad, poros y desviaciones frente al nominal |

**Alineación:** con las 3 referencias se hace un primer ajuste y luego se refina con **todos** los
pines asignados, como en una máquina de medir por coordenadas. El análisis indica el giro, si
hay reflexión (la imagen tiene y hacia abajo) y la **escala**: una escala distinta de 1 apunta a un
error de calibración del vóxel o de la pieza.

**Nominales:** Ø400 µm (o 400 × 400), paso 800, filas ±1025.5 / ±1825.5 µm, altura de pin 770,
gap 50, cavidad 820 y canal 1651 × 820. Están en `NOMINAL` y `FILAS_Y`, al principio del script.

## 4. Modelo CST tal como se fabricó

```bash
python cad/upm/cst/gen_cst_macro.py round <carpeta>/resultados/pins_asbuilt_<muestra>.csv
```

Genera `UPM_v3_asbuilt_<muestra>_macro.bas` con cada pin en su posición, con su diámetro y su altura medidos, sin compensación de chapado y sin los pines que faltan. El resto de cotas medidas (ancho y alto del canal, cavidad) se ajustan con los parámetros `aWR`, `bWR` y `Wcav` de la macro.

El envolvente exterior es el de la v3, pero para los parámetros S solo importa la geometría interior del aire, que es la misma que la de las muestras metálicas.

## 5. Cómo separar fabricación y diseño

| Curva S21 | Qué representa | La diferencia con la anterior es… |
|---|---|---|
| S_ideal | El diseño previsto, bien modelado | — |
| S_modelo | El modelo CST que se usó para fabricar (con sus errores) | error de **diseño o modelado** |
| S_as‑built | El modelo CST con la geometría medida aquí, y además la rugosidad | error de **fabricación**: geometría, y aparte la superficie, simulando con y sin rugosidad |
| S_medida | La medida del VNA, con ventana temporal para aislar la estructura de pines | **residuo**: bridas, conductividad real y lo que el TAC no ve |

Se representa con una gráfica en cascada de pérdidas de inserción en el centro de banda (ideal → modelo → fabricado → medido) y con las cuatro S21 superpuestas.

## 6. Prueba

```bash
python metrologia/pruebas/prueba_macros.py ij-1.54f.jar     # requiere Java y xvfb-run
```

Genera imágenes sintéticas con verdad conocida y ejecuta las funciones de medida en ImageJ. Comprueba:
- 31 pines detectados y el pin que falta (F2C13);
- un pin de Δd = +70 µm;
- gap 50 µm, cavidad 820 µm, canal 1651 × 820 µm;
- Rq de una pared ondulada y 2 poros;
- error de posición por debajo de ½ vóxel.

Último resultado: **todo OK**. Errores de 2–3 µm en bordes con vóxel de 11 µm.
