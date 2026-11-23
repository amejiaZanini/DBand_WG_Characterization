# Rediseño en CST de la guía WR‑6 de pines (banda D) para fabricación UPM

Este documento resume cómo se pasó del modelo CST original, pensado para impresión metálica en una sola pieza, a una **guía en dos piezas de resina LCD metalizada**. La guía queda definida por una macro paramétrica y verificada antes de abrir CST.

- **Estado:** versión **UPM v3**, con pines redondos y una variante con pines rectangulares.
- **Rama:** `upm-sla-redesign`.
- **Carpeta:** `cad/upm/cst/`.

---

## 1. Proceso de rediseño: entradas, método y salidas

### 1.1 Entradas

| Entrada | Formato | Para qué sirvió |
|---|---|---|
| Cortes del modelo CST original (XY por el centro, ZX vertical, ZY por la boca) | `.dxf` exportado desde CST, con una capa por material | Medir el modelo real: cuerpo, cavidad, filas de pines, M3, brida y partición |
| Historial del modelo original | `.txt` (macro del History List de CST) | Ver **cómo** estaba construido: picks, materiales, transformaciones y errores ocultos |
| Modelo del prototipo metálico | `.stp` (`Diseño/STEP/FV4_EBG_*_raw.stp`) | Referencias: 68.24 mm de boca a boca, filas de pines, partición original |
| Brida estándar UG‑387 (WR‑6) | Cotas | Círculo de tornillos de 14.2875, roscas 4‑40, agujeros a 45° de Ø1.5875 y Ø1.638, resalte de Ø9.525 × 0.508, disco de Ø19.05 |
| Guía WR‑6.5 | Cotas | Boca de 1.651 × 0.826, que en el modelo es 0.82 |
| Datos de la impresora del proveedor | Texto | LCD de alta resolución, resina lavable con agua, píxel de 18 µm, capa de 10–200 µm, volumen de 153 × 77 × 165 mm |
| Datos de metalización | Texto | Cu y Ni a unos 5 µm/h, con posibilidad de electroplating posterior |
| Requisitos del tutor | Texto | Pasadores de alineación que encajen con margen conocido, tornillos más cerca de la guía y más numerosos, pieza robusta y manejable con dimensiones WR‑6 |

### 1.2 Método

1. **Diagnóstico.** Se leyeron los DXF con `ezdxf` (polilíneas por capa) y se midieron todas las cotas. Se leyó el historial `.txt` línea a línea y se listaron todos los problemas (sección 3).
2. **Decisión de arquitectura.** Dos piezas, base y tapa, con la partición en el techo de la cavidad (tapa plana). Cada mitad lleva integrada su mitad de la brida.
3. **Reconstrucción paramétrica.** No se parcheó el modelo original: se escribió un **generador en Python** (`gen_cst_macro.py`) que produce la macro VBA de CST.
   - Todo depende de parámetros (`StoreParameter`) y no hay ningún pick.
   - Cada paso entra en el History List con `AddToHistory`, así que *Rebuild* funciona al cambiar cualquier parámetro.
4. **Verificación fuera de CST.** `check_geometry.py` ejecuta **las mismas operaciones** (guardadas en `OPS` por el generador) con un motor de geometría 3D (`manifold3d`). Comprueba:
   - número de piezas, número de pines y gap;
   - que base y tapa no se solapen;
   - centrado y simetría;
   - que la brida derecha sea la izquierda girada 180°;
   - que los agujeros coincidan entre base y tapa;
   - una tabla de holguras mínimas.

   Además dibuja cortes y una vista 3D.
5. **Iteración con el usuario.** Cada cambio se enseñaba en una imagen de antes y después y se aplicaba solo tras el visto bueno.
6. **Validación en CST.** La v2 se ejecutó en CST y se comprobaron cotas, lo que llevó a la corrección del centrado de A/B. **La v3 está verificada con el motor de geometría y falta ejecutarla en CST.** El siguiente paso es reexportar los cortes XY/ZX/ZY en DXF para contrastarlos.

### 1.3 Salidas

| Archivo | Contenido |
|---|---|
| `UPM_v3_macro.bas` | Macro CST, pines redondos. Uso: proyecto vacío → *Macros → Run Macro* |
| `UPM_v3_rect_macro.bas` | Macro CST, pines rectangulares (`wpx` × `wpy`) |
| `UPM_v3_history.txt`, `UPM_v3_rect_history.txt` | Los mismos pasos en texto plano, con la tabla de parámetros |
| `UPM_v3_check.png`, `UPM_v3_rect_check.png` | Vista explosionada y cortes |
| `UPM_v3_alineacion.png`, `UPM_v3_rect_alineacion.png` | Base y tapa superpuestas, con zoom a los pasadores A/B |
| `UPM_v3_vista.png` | Resumen visual de la v3, con zoom de pines redondos y rectangulares |
| `gen_cst_macro.py` | Generador. `python gen_cst_macro.py` da la versión redonda y `python gen_cst_macro.py rect` la rectangular |
| `check_geometry.py` | Verificación. `python check_geometry.py [rect] [tpl]` |

**Geometría final (v3):**
- **Base y tapa:** 68.24 mm de boca a boca, 40 mm de ancho y 9.935 mm por mitad (el bloque cubre el disco de brida, así que las caras exteriores son planas). Unos 56 g en total.
- **Canal:** 1.651 × 0.82.
- **Pines:** 316, en 4 filas de 79, de Ø0.39 o 0.39 × 0.39 y 0.77 de alto, con gap de 0.05.
- **Brida UG‑387:** integrada a cada lado y partida con cada mitad.
- **Tornillos de cierre:** 9 + 9 M2.5 en y = ±7.75, con tuerca en un alojamiento hexagonal.
- **Brida (fijación al extensor):** 4 agujeros a 45° de Ø1.638 y tuerca 4‑40 cautiva.
- **Pasadores A/B:** dos agujeros pasantes de centrado comunes a base y tapa, en (±17.25, ±14.5).

---

## 2. Línea de pensamiento aprobada y validada

Decisiones en el orden en que se tomaron, con su justificación. Todas fueron aprobadas o validadas antes de pasar a la siguiente.

1. **Partición en el techo de la cavidad (tapa plana).** La base contiene el canal en U, la cavidad y los pines, y la tapa es plana.
   - Una tapa plana se imprime y metaliza sin problemas.
   - **El chapado uniforme no cambia ni la altura del canal ni el gap.** El metal añadido en el suelo y en la cara inferior de la tapa se compensa con el que se añade en las caras de unión.
   - Solo hay que compensar en el plano: `tpl = 0.005` (canal y cavidad +tpl por pared, pines −tpl de radio, agujeros +tpl).
2. **Brida estándar integrada, dentro de los 68.24 mm y partida con cada mitad.** Se mantiene la longitud de boca a boca del metálico y de la simulación. La mitad superior de la brida va con la tapa y la inferior con la base.
3. **Brida derecha = izquierda girada 180° alrededor de z, no reflejada.** El patrón de pasador y agujero a 45° de la UG‑387 tiene orientación: un espejo produciría una brida que no casa con el extensor.
4. **Reconstruir en lugar de parchear.** El historial original dependía de picks, tenía sólidos duplicados y cotas con descentrados de micras. Una macro paramétrica sin picks da un historial coherente y reproducible.
5. **Formas explícitas, sin "copiar + unir" de Transform.** Cada pin, taladro, tornillo y tuerca se crea con nombre propio. El resultado no depende de cómo CST nombra o une las copias, y esto evitó un desplazamiento del agujero B.
6. **Pasadores de centrado A/B: un cilindro pasante cortado antes de partir el bloque.** Así salen idénticos y concéntricos en base y tapa por construcción (verificado: 0.00 µm).
   - Se imprimen a Ø2.8 y se **escarian a Ø3.0 H7 con las dos mitades montadas**, con pasadores de Ø3 h8.
   - Al escariar juntas, la distancia A–B (37.9 mm) deja de acumular error de impresión. Una contracción del 0.2 % serían 76 µm, y dos pasadores redondos no entrarían.
7. **Presupuesto de tolerancias en la boca.** Reflexión calculada por ajuste de modos en WR‑6.5:

   | Desalineamiento | Plano H (a lo ancho) | Plano E (a lo alto), caso peor a 170 GHz |
   |---|---|---|
   | 25 µm | −49 a −53 dB | −46 dB |
   | 50 µm | −38 a −42 dB | −35 dB |
   | 75 µm | −32 a −36 dB | −28.5 dB |
   | 100 µm | −27 a −32 dB | −24 dB |

   - **Máximo: unos 50 µm en total; objetivo: 25 µm o menos.**
   - El desalineamiento entre tapa y base no cambia la guía (la tapa es plana y la boca está entera en la base). Solo mueve el agujero de brida que cae en la tapa.
8. **Tornillos más cerca de la guía y más numerosos.** De 10 M3 a 11.45 mm del eje se pasó a 9 + 9 M2.5 a 7.75 mm.
   - Pared de 1.3 mm hasta la cavidad; el vano sin apoyo entre filas baja de 22.9 a 15.5 mm.
   - Llegan hasta x = ±29, a 4.6 mm de la boca, que es donde la junta no está protegida por pines.
   - **M2.5 frente a M3:** permite filas más cercanas y más margen entre tuercas. La fuerza no es el límite: la resina fluye bajo carga, así que hay que usar arandelas DIN 433, un par de 0.2–0.25 N·m y reapretar.
9. **Tuercas giradas 30°.** Las caras planas miran a la tuerca vecina, lo que deja 2.05 mm de resina entre tuercas. Se construyen como extrusión por puntos para no depender de cómo CST orienta un cilindro de 6 lados.
10. **Cuatro agujeros a 45° iguales, de Ø1.638.** No se sabe en qué diagonal tiene el extensor sus pasadores, así que valen ambas. No se ponen pasadores propios: añadirían una segunda cadena de tolerancias.
11. **Bloque de caras planas** (`Hhalf = Rdisc + zpart`). En la v2 solo 12 mm² de cada pieza tocaban la cama. En la v3 apoya la cara entera, sin soportes, y las caras críticas se imprimen las últimas, limpias. La tapa es 4.5 veces más rígida.
12. **Tuerca 4‑40 cautiva en la brida.** La rosca 4‑40 en resina se arranca con unos 0.2 N·m (unos 350 N). Ahora el tornillo del extensor pasa libre por un agujero de Ø3.0 y rosca en una tuerca de acero.
13. **Pieza maciza al 100 %, sin nervios ni vaciado.**
    - Los huecos cerrados atrapan resina y líquido del baño de metalización.
    - Los huecos abiertos hacia la cama hacen efecto ventosa.
    - Una pieza vaciada es menos estable dimensionalmente.
    - El ahorro sería de unos 12 g y el tiempo de impresión no cambiaría.
14. **Variante de pines rectangulares.** Resisten 1.7 veces más a flexión: se rompen con unos 0.39–0.58 N frente a unos 0.23–0.34 N los redondos. Además se alinean con los píxeles de la pantalla. **Hay que simularla antes de fabricar**, porque con el mismo lado tiene un 27 % más de sección y la banda de bloqueo se desplaza.
15. **Metalización.**
    - El espesor de penetración de la corriente es de 0.16–0.20 µm en Cu y de 0.32–0.40 µm en Ni.
    - **Especificación:** 5 µm nominales, como mínimo 1 µm en las zonas hundidas y como máximo 6 µm en aristas.
    - La **última capa** debe ser Cu electrolítico (o Ni electrolítico en la versión de níquel), nunca níquel químico, que conduce unas 10 veces peor.
    - Se metaliza primero una probeta y se mide en un corte.
16. **Probabilidad estimada de que el primer juego sea utilizable** (estimación de ingeniería): **≈ 20 % en la v2 y ≈ 50 % en la v3 con pines rectangulares**. Imprimiendo 2 bases por tanda y metalizando antes una probeta sube al ≈ 70–75 %.

---

## 3. Lo que estaba mal y cómo se corrigió

### 3.1 En el modelo CST original (DXF + historial)

| Problema | Consecuencia | Corrección |
|---|---|---|
| Material `Nickel` con `Mu "600"`, aplicado a todos los sólidos | Pérdidas infladas unas 24 veces en la simulación; a 140 GHz el níquel no es magnético | Materiales `Ni_plated` (σ = 1.44·10⁷) y `Cu_plated` (σ = 5.8·10⁷), los dos con `Mu = 1` |
| Brida (PEC, 4.064 mm) añadida **fuera** del cuerpo | Boca a boca de 75.35 mm en lugar de 68.24; la simulación no correspondía al metálico | Brida integrada dentro de los 68.24 mm |
| Brida derecha obtenida con un espejo | El patrón a 45° no casa con el extensor | Giro de 180° alrededor de z |
| Filas de pines en +1.0395 / +1.8395 / −1.0125 / −1.8125 | Descentradas 13.5 µm respecto a la boca | Filas en ±(aWR/2 + dpin/2) y ±(… + ppin): ±1.0255 / ±1.8255 |
| Un pin con material Vacuum, en (3.212, −1.0125) | Hueco en el bosque de pines | Los 316 pines, todos del mismo material |
| Sólidos duplicados en la tapa y un bloque extra de 6 × 6 | Historial incoherente y uniones dudosas | Reconstrucción limpia: al final quedan solo 2 sólidos (`Base:base`, `Tapa:tapa`) |
| Anchos distintos: base ±20 y tapa ±16 | Mitades que no encajan | Mismo ancho en las dos (`Wbody = 40`) |
| Alojamiento de tuerca hecho con `ECylinder` (Xradius e/2 ≠ Yradius S/2, 6 segmentos) | Hexágono irregular: la tuerca no entraba | Hexágono regular por extrusión de puntos, con entrecaras `hexS` |
| Rosca de la brida de solo unos 2.5 mm | Poca sujeción | Primero rosca ciega de 6 mm; en la v3, tuerca cautiva |
| Puertos, extrusiones, chaflanes y planos de trabajo definidos con picks | El historial se rompe al cambiar cualquier cosa | Todo por coordenadas y parámetros; puertos con `.Coordinates "Free"` |
| El `.txt` del historial no incluía los valores de los parámetros | No se podía reproducir el modelo | El generador escribe todos los parámetros (`StoreParameter`) y los documenta en `*_history.txt` |

### 3.2 Durante las iteraciones del rediseño

| Problema detectado | Corrección |
|---|---|
| Al principio se recomendó un espejo para la brida derecha (error de la recomendación) | Corregido a giro de 180° antes de construir |
| Agujero B de la tapa como ranura de 0.3 mm (no concéntrico a la vista) y diámetros distintos en base y tapa (2.95 / 3.05) | Un único cilindro pasante común (Ø2.8), con escariado conjunto a Ø3.0 H7 |
| Dependencia de "copiar + unir" de Transform (nombres de copias, uniones) | Formas explícitas con nombre propio |
| M3 a 11.45 mm del eje, 6.5 mm fuera de la cavidad | M2.5 a 7.75 mm, con pared de 1.3 mm |
| Medida de holgura entre tuercas tomada entre caras planas cuando se enfrentaban las esquinas (1.1 mm reales, no 2.0) | Tuercas giradas 30° y medida corregida |
| Tuercas exteriores a 0.11 mm del disco que sobresalía | Primero, tornillos de esquina fuera del disco; en la v3 el bloque cubre el disco y el problema desaparece |
| Pasadores de 1/16" propios en una sola diagonal | 4 agujeros de Ø1.638 sin pasadores propios |
| Caras exteriores no planas (12 mm² de apoyo en la cama) | Bloque de caras planas |
| Rosca 4‑40 directamente en resina (se arranca con unos 0.2 N·m) | Tuerca 4‑40 cautiva |
| `Hhalf` dependía de parámetros declarados después | Reordenados: `Hhalf` va tras `Rdisc` (los parámetros se evalúan en orden) |

### 3.3 Cosas valoradas y descartadas a propósito

Se dejaron fuera por decisión, no por olvido:

- **Alto de 0.82 en lugar de 0.8255:** heredado del metálico; el escalón es despreciable, por debajo de −60 dB.
- **Rugosidad de la impresión:** se acepta un factor de 1.8–2 en pérdidas. No se corrige con el espesor de metal.
- **Tramo liso de unos 2.6 mm en cada boca:** decisión heredada del diseño original. Se protege con los tornillos extremos.
- **Ranura en B:** sustituida por el escariado conjunto.
- **Pasadores propios en la brida:** no se ponen.
- **Helicoils:** difíciles de conseguir; sustituidos por la tuerca cautiva.
- **Redondeos y chaflanes de aristas:** dependen de picks en CST, así que se hacen a mano o los compensa el proveedor (pie de elefante).
- **Nervios o vaciado interior:** no aportan (punto 13 de la sección 2).

---

## 4. Módulos usados y formato que funcionó

### 4.1 Herramientas

| Herramienta | Uso |
|---|---|
| Python 3 (biblioteca estándar: `pathlib`, `contextlib`, `os`, `sys`) | `gen_cst_macro.py`: genera la macro y la lista estructurada de operaciones `OPS` |
| `manifold3d` + `numpy` | `check_geometry.py`: geometría 3D (uniones, restas, intersecciones, cortes) para verificar sin CST |
| `matplotlib` | Cortes, superposiciones base/tapa y vista 3D con un renderizado propio por píxeles |
| `ezdxf` | Lectura de los cortes DXF exportados de CST (fase de diagnóstico) |
| Ajuste de modos propio (`numpy`) | Reflexión frente a desalineamiento de la boca (plano H con modos TE_m0, plano E con modos LSE^x_1n) |

### 4.2 Formato de la macro CST que funcionó

- Una macro `Sub Main` con:
  1. `StoreParameter "nombre", "expresión"` para cada parámetro, en orden de dependencia;
  2. cada paso como texto VBA de un bloque de historial, pasado a `AddToHistory "título", s`;
  3. el texto se construye línea a línea con `s = s & "…" & vbCrLf`, **duplicando las comillas**;
  4. archivo en **cp1252** con saltos de línea CRLF.
- Bloques de historial usados (sintaxis copiada del propio historial del usuario, CST 2025):
  - **Cuerpos:** `With Brick … .Xrange "a","b" … .Create End With` y `With Cylinder … .Axis "x"|"z" … .Segments "0" … End With`.
  - **Hexágonos:** `With Extrude … .Mode "Pointlist" … .Point … .LineTo … .Create End With`. Es el único bloque que no salía en el historial del usuario: si CST lo rechaza, es el primer sitio a revisar.
  - **Booleanas:** `Solid.Add`, `Solid.Subtract`, `With Solid .Version 10 .Intersect "a","b" .Version 1 End With` y `Solid.Rename`.
  - **Copia a otro componente:** `With Transform … .Vector "0","0","0" … .MultipleObjects "True" … .Destination "Tapa" … "Translate"`. Es la única transformación que se usa.
  - **Puertos:** `With Port … .Coordinates "Free" … .Orientation "xmin"|"xmax" … End With`.
  - **Plantilla y solver:** copiados del historial original (`WG6_Pins.cfg`, HF Time Domain).
- Varios comandos relacionados (los 316 pines, los taladros…) van en **una sola entrada del historial**, con comentarios `'` dentro.
- Nombres siempre `Componente:sólido`. Las herramientas de corte sobresalen 0.1 mm. Las booleanas conservan el nombre del primer sólido.

### 4.3 Formato de entrada que dio buenos resultados

Para futuras iteraciones o revisiones:

1. **Tres cortes DXF exportados de CST** (XY por el centro de la cavidad, ZX por y = 0 y ZY por la boca), con una capa por material.
2. **El historial completo exportado como `.txt`**, junto con **la lista de parámetros y sus valores**, porque el `.txt` no los incluye.
3. **Cotas de referencia explícitas:** brida estándar, guía WR, longitud de boca a boca y espesores.
4. **Datos del proceso del proveedor:** impresora, píxel, capa, resina, tipo de metalización y espesores.
5. **Restricciones y decisiones ya tomadas**, escritas, para no reabrirlas (sección 3.3).
6. **Ciclo de trabajo:** generador → macro → *Run Macro* en un proyecto vacío → exportar los tres DXF → comparar con la verificación → ajustar parámetros.

---

## Próximos pasos

1. Ejecutar `UPM_v3_macro.bas` en CST y reexportar los cortes XY/ZX/ZY para contrastarlos.
2. Simular la variante rectangular y ajustar `wpx`/`wpy` si la banda de bloqueo se desplaza.
3. Exportar los STEP de fabricación con `tpl = 0.005`, con base y tapa como sólidos separados.
4. Cerrar con el proveedor: capa de 10 µm, impresión maciza sin soportes en las caras críticas, probeta de metalización y última capa de Cu electrolítico.
