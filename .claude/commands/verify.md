---
description: Quick sanity pass before committing in this repo (MATLAB + paper). MATLAB is not installed here, so verification is read-based, not execution-based.
---

# Verify

Revisión rápida del estado actual **leyendo**, no ejecutando (MATLAB no está
instalado en este contenedor). Úsalo antes de commitear.

## Argumentos
`$ARGUMENTS`:
- `quick` (por defecto) — árbol git + config única + sincronía con origin
- `code` — lo de `quick` + revisión de los `.m` cambiados
- `paper` — lo de `quick` + revisión del texto contra `rules/paper-format.md`

## Pasos

### quick (siempre)
1. **Git** — `git status --short` (árbol limpio) y rama/sincronía con origin.
2. **Config única** — ningún `.m` cambiado introduce rutas/máscaras/estilo
   hardcodeados fuera de `config_Article.m`.

### code (si procede)
3. **Lectura de los `.m` cambiados** — sintaxis y estilo según
   `rules/matlab-coding-standards.md`; se respetan bloques `arguments`,
   carpetas `private/` y `cfgget`.
4. **Trazabilidad numérica** — toda cifra de resultados citada cuadra con
   `Results/Metrics_77vs140.csv`. Ninguna inventada ni redondeada a la baja.
5. **Figuras** — siguen pasando por `makeAllFigures` (modos `byBand`/`split`/`compare`).

### paper (si procede)
6. **Formato** — cumple `rules/paper-format.md` (abstract sin símbolos, ≤5 pág.,
   citas IEEE, Index Terms, captions, ejes con palabras no símbolos…).
7. **Registro** — impersonal y verificable; sin citas inventadas; sin "sabor IA".

## Salida
```
VERIFY: [OK / PROBLEMAS]
Git:     [limpio / N cambios · ahead A / behind B]
Config:  [OK / hardcode fuera de config_Article.m]
Código:  [OK / N avisos]        (solo code)
Datos:   [cuadran con CSV / N discrepancias]   (solo code)
Paper:   [OK / N desvíos de formato]           (solo paper)
Listo para commit: [SÍ / NO]
```
Si hay algo crítico, lístalo con el archivo y la corrección sugerida.
