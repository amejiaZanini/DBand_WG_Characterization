# Session: 2026-11-24

**Started:** sesión larga, de septiembre a noviembre de 2026; se continuó varias veces tras compactar el contexto
**Last Updated:** 2026-11-24
**Project:** `amejiaZanini/DBand_WG_Characterization` (rama `main`)
**Topic:** guías EBG en banda D. Análisis de medidas, rediseño UPM (resina SLA + electrodeposición) con macro CST paramétrica, metrología TAC con Fiji y despliegue del toolkit de Claude.

> Idioma: el usuario escribe en español; responder en español, de forma simple y con
> imágenes cuando pida "muéstrame". No tocar el repositorio `MonoEstatic_Code`.
> No abrir PR salvo petición expresa. Commits `type: descripción` con las líneas de
> atribución de la sesión.

---

## What We Are Building

**Estudio de métodos de fabricación para antenas en bandas D y E.** Se fabrican guías de onda EBG (textura de pines, tipo *gap waveguide*) con dos métodos:
1. **Impresión 3D metálica.** Muestras de Ni y de Cu.
2. **Resina LCD/SLA + electrodeposición Cu/Ni**, fabricada por la UPM. Rediseñada en esta sesión como bloque partido en base y tapa.

Hay dos modelos de pines, **rectangulares** y **circulares**. Datos comunes del diseño:
- 316 pines (4 filas × 79), paso 0.8 mm, altura 0.77 mm.
- Gap de 0.05 mm entre pines y tapa.
- Boca WR‑6.5 de 1.651 × 0.82 mm y 68.24 mm de boca a boca.

El objetivo es **cuantificar la degradación en banda** (pérdidas de inserción, reflexión, rizado) y las imperfecciones de cada método, y **separar lo que es error de fabricación de lo que es error de diseño**.

**Cadena de trabajo:**
1. Medida VNA (Keysight PNA, puertos 1/3) → `.mat` en `data/`.
2. Postprocesado MATLAB (`WG_*.m` en la raíz).
3. Simulaciones CST (`Simulación/`).
4. Metrología TAC: pilas `.tif` del escáner de la UPC (Sant Adrià de Besòs) en `Scaner_Resultados/`, medidas con VGSTUDIO 2024 y Fiji. El objetivo es extraer diámetros, alturas, posiciones y pines que faltan, y construir un **modelo CST "tal como se fabricó"**.
5. Comparación en cuatro niveles: ideal → modelo → fabricado → medido.

---

## What WORKED (with evidence)

- **Macro CST paramétrica UPM v3** (`cad/upm/cst/gen_cst_macro.py` → `UPM_v3_macro.bas` y `UPM_v3_rect_macro.bas`). Confirmado por `check_geometry.py` (motor CSG `manifold3d`), con y sin chapado (`tpl = 0.005`):
  - 2 piezas de un solo bloque, 316 pines y gap de 0.050;
  - interferencia base∩tapa de unos 1e‑13 mm³;
  - 20 agujeros pasantes con 0.00 µm de desviación entre base y tapa;
  - centroide en (0, 0) y brida derecha igual a la izquierda girada 180°;
  - todas las holguras ≥ 0.45 mm (tabla en el propio script).
  - **La v2 se ejecutó en CST y el usuario validó cotas. La v3 NO se ha ejecutado aún en CST.**
- **Macros de Fiji `metrologia/fiji/Metrologia_EBG.ijm`** (F1–F8, guiadas por la selección del usuario). Confirmado por `metrologia/pruebas/prueba_macros.py`, que ejecuta ImageJ 1.54f en batch con `xvfb-run` sobre TAC sintético de verdad conocida. Resultado **TODO OK**:
  - 31 de 31 pines y el pin que falta identificado (F2C13);
  - diámetro medio 407.1 µm frente a 407.7;
  - gap 52.6 frente a 50; cavidad 822.3 frente a 820;
  - canal 1648 × 818 frente a 1651 × 820;
  - Rq 3.97 frente a 4.12; poros 2 de 2;
  - pin gordo con Δd = +69.4 frente a +70;
  - error de posición rms de 3.8 µm, por debajo de ½ vóxel.
- **`metrologia/analizar_metrologia.py`**: alineación con la rejilla nominal (3 referencias y refinado con todos los pines), detección de pines que faltan o están fusionados, mapas, `resumen.csv` y `pins_asbuilt_<muestra>.csv`. Confirmado por la misma prueba.
- **Modelo CST desde pines medidos**: `python cad/upm/cst/gen_cst_macro.py round <pins_asbuilt.csv>`. Confirmado con el CSV sintético: genera la macro y `check_geometry` cuenta un pin menos.
- **Herramientas MATLAB** (antes de esta parte de la sesión): `WG_PlotResults.m` (modos visualizar y comparar, colores por material, simulación superpuesta), `WG_PowerBalance.m`, `WG_TimeGating.m` (velocidad de propagación por retardo de grupo sobre 68.24 mm) y `WG_LossMap.m`. El usuario las usa y las ha retocado.
- **Toolkit desplegado** en `.claude/` y subido a `main` (commit `8c6e5ee`). La skill `pptx-reporting` se probó con la demo PPTX → PDF (LibreOffice) → PNG (`pdftoppm`) y funcionó.
- **Cálculo de reflexión por desalineamiento de la boca** (ajuste de modos propio):
  - plano H: 25 µm → −49/−53 dB; 50 µm → −38/−42 dB;
  - plano E a 170 GHz: 25 µm → −46 dB; 50 µm → −35 dB; 100 µm → −24 dB.
  - Margen máximo de unos 50 µm; objetivo de 25 µm.

---

## What Did NOT Work (and why)

- **ImageJ sin pantalla (`-Djava.awt.headless=true`) con `open()`** → `HeadlessException` en `IJ.init` (menús). Solución: ejecutar con `xvfb-run -a java -jar ij.jar -batch macro.ijm`.
- **En el lenguaje de macros de ImageJ, una expresión que EMPIEZA por una función propia que devuelve texto**, como `x = meta() + ","`, se evalúa como número y da error. Con pantalla, el error abre un diálogo que bloquea ImageJ para siempre. Solución: empezar por texto (`"" + meta() + ...`) o asignar antes (`m0 = meta();`). Tampoco se puede indexar el resultado de una llamada (`split(s, ",")[6]`).
- **`pip install X` instala para `python3.13`, no para `python3` (3.11).** Usar `python3 -m pip install X`.
- **Uniones con "copiar + unir" de Transform en CST** (`GroupObjects`) → nombres e uniones de copias no fiables; el agujero B salía descentrado. Solución: crear cada pin, taladro, tornillo y tuerca de forma explícita.
- **Agujero B como ranura y diámetros distintos en base y tapa (2.95 / 3.05)** → el usuario lo vio descentrado. Sustituido por un cilindro pasante común a las dos piezas (Ø2.8) y escariado conjunto a 3.0 H7.
- **Brida derecha por espejo** (recomendación mía inicial, errónea) → el patrón a 45° de la UG‑387 tiene orientación. Correcto: giro de 180° alrededor de z.
- **Rosca 4‑40 en resina** → se arranca con unos 0.2 N·m (≈ 350 N). Sustituida por una tuerca 4‑40 cautiva.
- **Diseño con disco de brida que sobresale** → solo 12 mm² de apoyo en la cama de la impresora. Sustituido por un bloque de caras planas (`Hhalf = Rdisc + zpart`).
- **Push rechazado varias veces** porque el usuario había subido commits a la rama remota → `git fetch` + `git merge --no-edit FETCH_HEAD` y volver a subir. Nunca forzar.
- **`get_session`** (para saber el modelo) fue denegado por el usuario; no volver a usarlo.

---

## What Has NOT Been Tried Yet

- **Ejecutar las macros de Fiji sobre las pilas reales** de `Scaner_Resultados/reports/Ni/Circular_General` (vóxel 45.335 µm) y `.../Ni/Capturas_ROI` (≈ 11 µm); también Cu (`reports/Cu/General_VIEW`, `reports/Cu/reports`).
- **Ejecutar `UPM_v3_macro.bas` en CST** (proyecto vacío → *Macros → Run Macro*). Después, reexportar los cortes XY/ZX/ZY en DXF para contrastarlos. El paso con extrusión por puntos (`.Mode "Pointlist"`, alojamientos de tuerca) es el más incierto.
- **Simular la variante de pines rectangulares** y ajustar `wpx`/`wpy` si se desplaza la banda de bloqueo.
- **Construir el modelo CST "tal como se fabricó"** de las muestras metálicas con `pins_asbuilt_*.csv`, y hacer la **cascada** ideal → modelo → fabricado → medido.
- **Reescaneo de alta resolución o corte metalográfico** para medir el gap de 50 µm, que no se resuelve a 45 µm.
- **Comprobar con un perfil de gris** si los "pines huecos" del TAC de Ni son reales o artefacto del haz (cupping).
- **Leer `EUCAP2027.md` y `MRFC2023.md`**, añadidos por el usuario a `main`, probablemente el borrador del artículo y una referencia. Usarlos con `pptx-reporting`.
- **Respuesta del proveedor UPM.** El correo se redactó (preguntas sobre capa de 10 µm, absorción de agua de la resina, capa base y electroplating, probeta, plazo y coste); no se sabe si se envió.

---

## Current State of Files

| File | Status | Notes |
| --- | --- | --- |
| `.claude/` (CLAUDE.md, agents, commands, rules, skills, session-data) | PASS: Complete | Toolkit con la opción B + configuraciones antiguas movidas desde la raíz. En `main` |
| `.claude/rules-inactivas/` | PASS: Complete | `testing.md`, `development-workflow.md`, `agents.md`: aparcadas, no se cargan |
| `cad/upm/cst/gen_cst_macro.py` | PASS: Complete | Generador v3: `python gen_cst_macro.py [round\|rect] [pins_asbuilt.csv]` |
| `cad/upm/cst/check_geometry.py` | PASS: Complete | `python3.13 check_geometry.py [rect] [tpl]`: verificación CSG, tabla de holguras, figuras |
| `cad/upm/cst/UPM_v3_macro.bas`, `UPM_v3_rect_macro.bas` (+ `_history.txt`, PNG) | In Progress | Verificadas con CSG; falta ejecutarlas en CST |
| `cad/upm/cst/REDISENO_CST_UPM.md` | PASS: Complete | Documento del rediseño: entradas, decisiones, correcciones, formato |
| `cad/upm/gen_upm_v1.py` + `UPM_v1_*` | PASS: Complete | Primer layout (superado por la v3) |
| `metrologia/fiji/Metrologia_EBG.ijm` | PASS: Complete | 8 herramientas F1–F8, probadas con datos sintéticos |
| `metrologia/analizar_metrologia.py` | PASS: Complete | Análisis y exportación as-built |
| `metrologia/pruebas/prueba_macros.py` | PASS: Complete | Necesita `ij.jar` (Maven), Java y `xvfb-run` |
| `metrologia/README.md` | PASS: Complete | Protocolo: qué medir en general y en ROI, límites, cascada |
| `WG_PlotResults.m`, `WG_PowerBalance.m`, `WG_TimeGating.m`, `WG_LossMap.m` | PASS: Complete | Postprocesado; el usuario hizo retoques propios |
| `Scaner_Resultados/` (≈ 2.7 GB, ~2700 `.tif`) | Not Started | Datos de TAC subidos por el usuario; aún sin medir con las macros |

---

## Decisions Made

- **Partición en el techo de la cavidad (tapa plana)** — el chapado uniforme no cambia ni la altura del canal ni el gap; solo se compensa en el plano (`tpl`).
- **Brida UG‑387 integrada dentro de los 68.24 mm**, una mitad por pieza; la derecha es la izquierda girada 180°.
- **Reconstruir en macro paramétrica sin picks** en lugar de parchear el modelo original.
- **Pasadores A/B: cilindros pasantes cortados antes de partir**; Ø2.8 impreso, escariado conjunto a 3.0 H7, pasadores Ø3 h8. Sin ranura.
- **Tornillos:** 9 + 9 M2.5 en y = ±7.75 (pared de 1.3 mm a la cavidad), paso 7.25, hasta x = ±29; tuercas giradas 30°.
- **4 agujeros a 45° de Ø1.638 en cada brida** (los pasadores del extensor valen en cualquier diagonal); sin pasadores propios.
- **Bloque de caras planas** y **tuerca 4‑40 cautiva**.
- **Pieza maciza al 100 %**: sin nervios ni vaciado (líquido atrapado del baño, efecto ventosa, estabilidad dimensional).
- **Metalización:** 5 µm nominales (mínimo 1 µm en zonas hundidas, máximo 6 µm en aristas); última capa de Cu electrolítico (o Ni electrolítico en la versión de níquel), nunca níquel químico; probeta previa. Simulación con `Ni_plated` y `Cu_plated`, ambos con `Mu = 1`.
- **Estimación de fabricabilidad** (de ingeniería): juego utilizable a la primera ≈ 20 % (v2) → ≈ 50 % (v3 con pines rectangulares); 70–75 % con 2 bases por tanda y probeta.
- **Metrología:**
  - bordes al 50 % entre aire y metal (ISO‑50), con niveles medidos en cada pila (F2);
  - filas 1 = exterior y 2 = interior de un lado, 3 = interior y 4 = exterior del otro; columnas 1–79;
  - 3 pines de referencia para numeración absoluta;
  - refinado de la alineación con todos los pines;
  - incertidumbre de ±½ vóxel; rasgos de menos de 2 vóxeles no se miden.
- **Separar diseño y fabricación** con cuatro curvas S21: ideal (diseño bien modelado), modelo (el CST que se usó), fabricado (geometría del TAC + rugosidad) y medida (con ventana temporal).
- **Simulación del pin faltante de la guía circular con PEC** (decisión del usuario): se buscaba ver si la tendencia de S21/S11 reproduce la degradación medida, no el valor absoluto.
- **Toolkit en `main`**; los duplicados se resolvieron a favor de las versiones del toolkit.

---

## Blockers & Open Questions

- **Guía circular:** se conocen varias causas candidatas en su modelo CST (un pin en Vacuum en x = 3.212, y = −1.0125; filas descentradas 13.5 µm; Ni con μr = 600; brida fuera de la longitud, 75.35 mm frente a 68.24). Falta confirmar con las medidas del TAC cuál explica la medida real.
- **A 45.335 µm el gap no se resuelve:** para afirmar que el gap o los defectos explican las pérdidas hace falta el ROI a ≈ 11 µm o metalografía.
- **La v3 sin ejecutar en CST:** posible incompatibilidad del bloque `With Extrude .Mode "Pointlist"`.
- **Pendiente del proveedor UPM** (impresora LCD de 18 µm, resina lavable con agua, capa de 10–200 µm): capa de 10 µm, absorción de agua de la resina, tipo de capa base y electroplating posterior, probeta, plazo y coste.
- **Fiji:** no hay Fiji en el contenedor en la nube. Las macros se ejecutan en el ordenador del usuario; aquí solo se prueban con `ij.jar` y `xvfb-run`.

---

## Exact Next Step

En Fiji, en el ordenador del usuario:
1. *Plugins ▸ Macros ▸ Install…* ▸ `metrologia/fiji/Metrologia_EBG.ijm`.
2. Abrir una pila de `Scaner_Resultados/reports/Ni/Circular_General`.
3. **F1**: muestra p. ej. `Ni_C_general`, Ni, circular, general, 45.335 µm, aplicar el vóxel y elegir la carpeta de salida.
4. **F2**: niveles de aire y de metal (zona gruesa, p. ej. la brida).
5. **F3**: rectángulo sobre los pines en un corte a media altura del pin, y 3 referencias.
6. Pasar a Claude la carpeta de CSV. Ejecutar `python metrologia/analizar_metrologia.py <carpeta>` y revisar el mapa y el resumen.

Después, repetir en el ROI (`Capturas_ROI`, ≈ 11 µm) con F4 y F5 (gap y alturas) y F7 (rugosidad).

---

## Environment & Setup Notes

- **Python:** `python3` es la 3.11 (numpy, matplotlib; `python-pptx` se instala con `python3 -m pip install python-pptx`). `python3.13` tiene `manifold3d` y `python-pptx`; con él se ejecuta `check_geometry.py`. En un contenedor nuevo puede hacer falta `python3.13 -m pip install manifold3d matplotlib`.
- **pptx-reporting:** LibreOffice (`soffice`), Poppler (`pdftoppm`) y Node vienen instalados.
- **Pruebas de Fiji:** descargar `https://repo1.maven.org/maven2/net/imagej/ij/1.54f/ij-1.54f.jar` (Maven es accesible; downloads.imagej.net no) y ejecutar `python3 metrologia/pruebas/prueba_macros.py ij-1.54f.jar <carpeta_de_trabajo>`. Necesita Java y `xvfb-run`, que están instalados.
- **Ramas:** `main` contiene todo (PR #1 fusionó `upm-sla-redesign`, más el toolkit). `upm-sla-redesign` no tiene el commit del toolkit.
- **Sin MATLAB, VNA, CST ni Fiji en la nube:** el MATLAB se valida leyendo; las macros CST con `check_geometry.py`.
