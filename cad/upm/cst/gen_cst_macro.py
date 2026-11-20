"""Genera la macro CST (VBA) que reconstruye el prototipo UPM v2 con un historial limpio.

Salidas (en esta carpeta):
  UPM_v2_macro.bas    -> Macros > Run Macro en un proyecto CST vacío.
                         Crea los parámetros y añade cada paso al History List.
  UPM_v2_history.txt  -> los mismos pasos en texto plano (para leerlos o pegarlos
                         a mano en History List > Edit).

Marco de referencia (centrado):
  x = 0 centro de la guía (bocas en x = ±Lwg/2), y = 0 eje del canal,
  z = 0 centro de la boca. Suelo en -bWR/2, techo = plano de partición zpart = bWR/2.

Todo es paramétrico y no hay ninguna selección a mano (picks), así que el
historial se puede reconstruir (Rebuild) sin errores al cambiar parámetros.
"""
from contextlib import contextmanager
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAT = "Ni_plated"

# (nombre, valor, descripción)
PARAMS = [
    ("Lwg", "68.24", "longitud boca a boca (cara del resalte a cara del resalte)"),
    ("Wbody", "40", "ancho del cuerpo en y (las dos mitades iguales)"),
    ("Hhalf", "6", "espesor de cada mitad medido desde el plano de partición"),
    ("aWR", "1.651", "ancho de la boca WR-6.5"),
    ("bWR", "0.82", "alto de la boca y de la cámara de pines"),
    ("zpart", "bWR/2", "plano de partición = techo de la cavidad (tapa plana)"),
    ("Lcav", "63", "largo de la cámara de pines"),
    ("Wcav", "9.997", "ancho de la cámara de pines"),
    ("dpin", "0.4", "diámetro nominal del pin"),
    ("hpin", "0.77", "altura del pin (gap 0.05 hasta la tapa)"),
    ("ppin", "0.8", "periodo de pines"),
    ("y1pin", "aWR/2+dpin/2", "fila interior (centrada respecto a la boca)"),
    ("x0pin", "-Lcav/2+0.3", "x del primer pin"),
    ("tpl", "0", "espesor de chapado: 0 para simular, 0.005 para fabricar"),
    ("tboss", "0.508", "espesor del resalte de la brida"),
    ("Rboss", "4.7625", "radio del resalte"),
    ("tdisc", "7.112", "espesor del disco de brida (dentro de Lwg)"),
    ("Rdisc", "9.525", "radio del disco de brida"),
    ("BCfl", "14.2875", "diámetro del círculo de tornillos de la brida"),
    ("r45", "5.051394", "BCfl/2 * cos(45)"),
    ("dtap", "2.2606", "taladro de rosca 4-40"),
    ("ltap", "6", "profundidad de rosca (ciega) desde la cara del disco"),
    ("dcb", "3.556", "avellanado de los 4-40"),
    ("lcb", "1.016", "profundidad del avellanado"),
    ("dprc", "1.638", "4 agujeros a 45° para los pasadores 1/16 in del extensor (valen en cualquier diagonal)"),
    ("lal", "3", "profundidad de los agujeros de alineación de brida"),
    ("xsc", "7.7", "paso de los tornillos de cierre en x (7 por fila)"),
    ("ysc", "7.75", "filas de tornillos en y = ±ysc (pared de 1.3 mm a la cavidad)"),
    ("xce", "29.8", "tornillos de esquina junto a cada boca: |x|"),
    ("yce", "10.5", "tornillos de esquina junto a cada boca: |y| (fuera del disco)"),
    ("dsc", "2.9", "agujero pasante M2.5 (ISO 273 medio)"),
    ("hexS", "5.2", "entrecaras del alojamiento de tuerca M2.5 (tuerca S5 + 0.2)"),
    ("hexH", "2.3", "profundidad del alojamiento de tuerca (tuerca m = 2.0 + 0.3)"),
    ("xab", "17.25", "pasadores de centrado A/B: |x|"),
    ("yab", "14.5", "pasadores de centrado A/B: |y|"),
    ("dab", "2.8", "agujero de centrado A/B pasante (mismo en base y tapa); escariar a 3.0 H7 con las dos mitades montadas"),
]

XDF = "(-Lwg/2+tboss)"          # cara del disco izquierdo
XDFR = "(Lwg/2-tboss)"          # cara del disco derecho
ZBOT = "(zpart-Hhalf)"
ZTOP = "(zpart+Hhalf)"

blocks = []                     # (caption, [líneas])
OPS = []                        # mismas operaciones en forma estructurada (para check_geometry.py)


def q(*vals):
    return ", ".join(f'"{v}"' for v in vals)


_group = None                   # entrada del historial abierta con group()


def add(caption, lines):
    if _group is not None:
        _group.extend(["", f"' {caption}", *lines])
    else:
        blocks.append((caption, lines))


@contextmanager
def group(caption):
    """Mete varios comandos en UNA entrada del historial (p. ej. los 316 pines)."""
    global _group
    _group = []
    yield
    blocks.append((caption, _group[1:]))
    _group = None


def brick(comp, name, xr, yr, zr):
    OPS.append(("brick", f"{comp}:{name}", xr, yr, zr))
    add(f"define brick: {comp}:{name}", [
        "With Brick", "     .Reset", f'     .Name "{name}"', f'     .Component "{comp}"',
        f'     .Material "{MAT}"', f"     .Xrange {q(*xr)}", f"     .Yrange {q(*yr)}",
        f"     .Zrange {q(*zr)}", "     .Create", "End With"])


def cyl(comp, name, axis, r, rng, c1, c2, seg="0"):
    """axis z: rng=Zrange, c1=Xcenter, c2=Ycenter · axis x: rng=Xrange, c1=Ycenter, c2=Zcenter."""
    OPS.append(("cyl", f"{comp}:{name}", axis, r, rng, c1, c2, seg))
    if axis == "z":
        span, cen = f"     .Zrange {q(*rng)}", [f'     .Xcenter "{c1}"', f'     .Ycenter "{c2}"']
    else:
        span, cen = f"     .Xrange {q(*rng)}", [f'     .Ycenter "{c1}"', f'     .Zcenter "{c2}"']
    add(f"define cylinder: {comp}:{name}", [
        "With Cylinder", "     .Reset", f'     .Name "{name}"', f'     .Component "{comp}"',
        f'     .Material "{MAT}"', f'     .OuterRadius "{r}"', '     .InnerRadius "0.0"',
        f'     .Axis "{axis}"', span, *cen, f'     .Segments "{seg}"', "     .Create", "End With"])


def _transform(shape, kind, geom, reps="1", copy=True, unite=True, dest=""):
    add(f"transform: {kind.lower()} {shape}", [
        "With Transform", "     .Reset", f'     .Name "{shape}"', *geom,
        f'     .MultipleObjects "{copy}"', f'     .GroupObjects "{unite}"',
        f'     .Repetitions "{reps}"', '     .MultipleSelection "False"',
        f'     .Destination "{dest}"', '     .Material ""',
        f'     .AutoDestination "{"False" if dest else "True"}"',
        f'     .Transform "Shape", "{kind}"', "End With"])


def translate(shape, vec, reps="1", unite=True, dest=""):
    OPS.append(("translate", shape, vec, reps, unite, dest))
    _transform(shape, "Translate", [f"     .Vector {q(*vec)}", '     .UsePickedPoints "False"',
                                    '     .InvertPickedPoints "False"'], reps, True, unite, dest)


def hexprism(comp, name, xc, yc, z0, h):
    """Prisma hexagonal regular (entrecaras hexS+2tpl) con caras planas mirando a ±x."""
    OPS.append(("hex", f"{comp}:{name}", xc, yc, z0, h))
    s, k1, k2 = "(hexS/2+tpl)", "0.5773503", "1.1547005"
    pts = [(s, f"{s}*{k1}"), ("0", f"{s}*{k2}"), (f"-{s}", f"{s}*{k1}"),
           (f"-{s}", f"-{s}*{k1}"), ("0", f"-{s}*{k2}"), (s, f"-{s}*{k1}")]
    add(f"define extrude: {comp}:{name}", [
        "With Extrude", "     .Reset", f'     .Name "{name}"', f'     .Component "{comp}"',
        f'     .Material "{MAT}"', '     .Mode "Pointlist"', f'     .Height "{h}"',
        '     .Twist "0.0"', '     .Taper "0.0"', f'     .Origin "{xc}", "{yc}", "{z0}"',
        '     .Uvector "1.0", "0.0", "0.0"', '     .Vvector "0.0", "1.0", "0.0"',
        f'     .Point "{pts[0][0]}", "{pts[0][1]}"',
        *[f'     .LineTo "{u}", "{v}"' for u, v in pts[1:]], f'     .LineTo "{pts[0][0]}", "{pts[0][1]}"',
        "     .Create", "End With"])


def boolean(op, a, b):
    OPS.append((op, a, b))
    add(f"boolean {op.lower()} shapes: {a}, {b}", [f'Solid.{op} "{a}", "{b}"'])


def rename(a, new):
    OPS.append(("rename", a, new))
    add(f"rename block: {a} to: {a.split(':')[0]}:{new}", [f'Solid.Rename "{a}", "{new}"'])


def intersect(a, b):
    OPS.append(("Intersect", a, b))
    add(f"boolean intersect shapes: {a}, {b}", [
        "With Solid", "     .Version 10", f'     .Intersect "{a}", "{b}"', "     .Version 1", "End With"])


# ── 1. Plantilla (copiada de tu WG6_Pins.cfg) ───────────────────────────────
add("use template: WG6_Pins (UPM v2)", """With Units
     .SetUnit "Length", "mm"
     .SetUnit "Frequency", "GHz"
     .SetUnit "Voltage", "V"
     .SetUnit "Resistance", "Ohm"
     .SetUnit "Inductance", "nH"
     .SetUnit "Temperature",  "degC"
     .SetUnit "Time", "ns"
     .SetUnit "Current", "A"
     .SetUnit "Conductance", "S"
     .SetUnit "Capacitance", "pF"
End With
ThermalSolver.AmbientTemperature "0"
Solver.FrequencyRange "110", "170"
Plot.DrawBox True
With Background
     .Type "Normal"
     .Epsilon "1.0"
     .Mu "1.0"
     .XminSpace "0.0"
     .XmaxSpace "0.0"
     .YminSpace "0.0"
     .YmaxSpace "0.0"
     .ZminSpace "0.0"
     .ZmaxSpace "0.0"
End With
With Boundary
     .Xmin "expanded open"
     .Xmax "expanded open"
     .Ymin "expanded open"
     .Ymax "expanded open"
     .Zmin "expanded open"
     .Zmax "expanded open"
     .Xsymmetry "none"
     .Ysymmetry "none"
     .Zsymmetry "none"
End With
FDSolver.ExtrudeOpenBC "True"
Mesh.FPBAAvoidNonRegUnite "True"
Mesh.ConsiderSpaceForLowerMeshLimit "False"
Mesh.MinimumStepNumber "5"
With MeshSettings
     .SetMeshType "Hex"
     .Set "RatioLimitGeometry", "20"
End With
With MeshSettings
     .SetMeshType "HexTLM"
     .Set "RatioLimitGeometry", "20"
End With
PostProcess1D.ActivateOperation "vswr", "true"
PostProcess1D.ActivateOperation "yz-matrices", "true"
With MeshSettings
     .SetMeshType "Hex"
     .Set "Version", 1%
End With
With Mesh
     .MeshType "PBA"
End With
ChangeSolverType("HF Time Domain")""".splitlines())

# ── 2. Materiales (Mu = 1: a 140 GHz el níquel no es magnético) ─────────────
for name, kappa, rgb in (("Ni_plated", "1.44e7", '"0", "0.501961", "0.25098"'),
                         ("Cu_plated", "5.8e7", '"1", "0.52", "0.2"')):
    add(f"define material: {name}", [
        "With Material", "     .Reset", f'     .Name "{name}"', '     .Folder ""',
        '     .FrqType "all"', '     .Type "Lossy metal"', '     .SetMaterialUnit "GHz", "mm"',
        '     .Mu "1"', f'     .Kappa "{kappa}"', f"     .Colour {rgb}", '     .Wireframe "False"',
        '     .Transparency "0"', "     .Create", "End With"])

# ── 3. Componentes ──────────────────────────────────────────────────────────
add("new component: Base", ['Component.New "Base"'])
add("new component: Tapa", ['Component.New "Tapa"'])

# ── 4-5. Material exterior: cuerpo + disco + resalte (una sola pieza) ───────
brick("Base", "mono", ("-Lwg/2+tboss", "Lwg/2-tboss"), ("-Wbody/2", "Wbody/2"), (ZBOT, ZTOP))
cyl("Base", "discL", "x", "Rdisc", (XDF, f"{XDF}+tdisc"), "0", "0")
cyl("Base", "discR", "x", "Rdisc", ("Lwg/2-tboss-tdisc", "Lwg/2-tboss"), "0", "0")
cyl("Base", "bossL", "x", "Rboss", ("-Lwg/2", XDF), "0", "0")
cyl("Base", "bossR", "x", "Rboss", ("Lwg/2-tboss", "Lwg/2"), "0", "0")
for s in ("discL", "discR", "bossL", "bossR"):
    boolean("Add", "Base:mono", f"Base:{s}")

# ── 6. Aire: cámara de pines y canal/boca de lado a lado ────────────────────
brick("Base", "cav", ("-Lcav/2", "Lcav/2"), ("-Wcav/2-tpl", "Wcav/2+tpl"), ("-bWR/2", "bWR/2"))
boolean("Subtract", "Base:mono", "Base:cav")
brick("Base", "chan", ("-Lwg/2-0.1", "Lwg/2+0.1"), ("-aWR/2-tpl", "aWR/2+tpl"), ("-bWR/2", "bWR/2"))
boolean("Subtract", "Base:mono", "Base:chan")

# ── 7. Pines: 316 cilindros explícitos (4 filas x 79) unidos al cuerpo ─────
ROWS = ("y1pin", "y1pin+ppin", "-y1pin", "-y1pin-ppin")
PINS = [(f"pin{r + 1}_{k:02d}", f"x0pin+{k}*ppin", y) for r, y in enumerate(ROWS) for k in range(79)]
with group("define cylinders: Base:pin (316)"):
    for name, xc, yc in PINS:
        cyl("Base", name, "z", "dpin/2-tpl", ("-bWR/2-0.01", "-bWR/2+hpin"), xc, yc)
with group("boolean add shapes: Base:mono, Base:pin (316)"):
    for name, _, _ in PINS:
        boolean("Add", "Base:mono", f"Base:{name}")

# ── 8. Taladros de brida: izquierda y derecha (= izquierda girada 180° en z) ─
FL = [("cbT", "dcb/2+tpl", "lcb", "0", "BCfl/2"),
      ("cbB", "dcb/2+tpl", "lcb", "0", "-BCfl/2"),
      ("tpT", "dtap/2+tpl", "ltap", "0", "BCfl/2"),
      ("tpB", "dtap/2+tpl", "ltap", "0", "-BCfl/2"),
      ("al1", "dprc/2+tpl", "lal", "r45", "r45"),
      ("al2", "dprc/2+tpl", "lal", "-r45", "-r45"),
      ("al3", "dprc/2+tpl", "lal", "-r45", "r45"),
      ("al4", "dprc/2+tpl", "lal", "r45", "-r45")]
FLT = []
for name, r, depth, yc, zc in FL:
    FLT.append((f"{name}L", r, (f"{XDF}-0.1", f"{XDF}+{depth}"), yc, zc))
    FLT.append((f"{name}R", r, (f"{XDFR}-{depth}", f"{XDFR}+0.1"), f"-({yc})", zc))   # giro 180°: y -> -y
with group("define cylinders: Base:taladros de brida (16)"):
    for name, r, xr, yc, zc in FLT:
        cyl("Base", name, "x", r, xr, yc, zc)
with group("boolean subtract shapes: Base:mono, taladros de brida"):
    for name, *_ in FLT:
        boolean("Subtract", "Base:mono", f"Base:{name}")

# ── 9. Pasantes que atraviesan las DOS mitades a la vez (antes de partir) ───
#    Tornillos M2.5 (14 en dos filas + 4 de esquina junto a las bocas) y centrado A/B:
#    un solo cilindro por agujero -> idéntico y concéntrico en base y tapa.
SCR = [(f"sc_{'ab'[s]}{k}", f"{k - 3}*xsc", "ysc" if s == 0 else "-ysc") for s in (0, 1) for k in range(7)]
SCR += [(f"sc_e{i}", f"{sx}xce", f"{sy}yce") for i, (sx, sy) in enumerate((("-", ""), ("", ""), ("-", "-"), ("", "-")))]
M3 = SCR
AB = [("abA", "-xab", "yab"), ("abB", "xab", "-yab")]
with group("define cylinders: Base:pasantes M2.5 (18) y centrado A/B (2)"):
    for name, xc, yc in SCR:
        cyl("Base", name, "z", "dsc/2+tpl", (f"{ZBOT}-0.1", f"{ZTOP}+0.1"), xc, yc)
    for name, xc, yc in AB:
        cyl("Base", name, "z", "dab/2", (f"{ZBOT}-0.1", f"{ZTOP}+0.1"), xc, yc)
with group("boolean subtract shapes: Base:mono, pasantes"):
    for name, *_ in M3 + AB:
        boolean("Subtract", "Base:mono", f"Base:{name}")

# ── 10. Partir: cada mitad (y cada media brida) en su componente ────────────
translate("Base:mono", ("0", "0", "0"), unite=False, dest="Tapa")
brick("Base", "cutB", ("-Lwg/2-1", "Lwg/2+1"), ("-Wbody/2-1", "Wbody/2+1"), ("-Rdisc-1", "zpart"))
brick("Tapa", "cutT", ("-Lwg/2-1", "Lwg/2+1"), ("-Wbody/2-1", "Wbody/2+1"), ("zpart", "Rdisc+1"))
intersect("Base:mono", "Base:cutB")
intersect("Tapa:mono", "Tapa:cutT")
rename("Base:mono", "base")
rename("Tapa:mono", "tapa")

# ── 11-12. Tapa: alojamientos hexagonales de tuerca (18), caras planas hacia ±x ─
HEX = [(f"hex{n[2:]}", xc, yc) for n, xc, yc in SCR]
with group("define extrudes: Tapa:hex (18)"):
    for name, xc, yc in HEX:
        hexprism("Tapa", name, xc, yc, f"{ZTOP}-hexH", "hexH+0.1")
with group("boolean subtract shapes: Tapa:tapa, hex"):
    for name, *_ in HEX:
        boolean("Subtract", "Tapa:tapa", f"Tapa:{name}")

# ── 13. Puertos en las caras del resalte (sin picks) ────────────────────────
for num, sx, ori in (("1", "-", "xmin"), ("2", "", "xmax")):
    add(f"define port: {num}", [
        "With Port", "     .Reset", f'     .PortNumber "{num}"', '     .Label ""', '     .Folder ""',
        '     .NumberOfModes "1"', '     .AdjustPolarization "False"', '     .PolarizationAngle "0.0"',
        '     .ReferencePlaneDistance "0"', '     .TextSize "50"', '     .TextMaxLimit "0"',
        '     .Coordinates "Free"', f'     .Orientation "{ori}"', '     .PortOnBound "False"',
        '     .ClipPickedPortToBound "False"', f'     .Xrange "{sx}Lwg/2", "{sx}Lwg/2"',
        '     .Yrange "-aWR/2-tpl", "aWR/2+tpl"', '     .Zrange "-bWR/2", "bWR/2"',
        '     .XrangeAdd "0.0", "0.0"', '     .YrangeAdd "0.0", "0.0"', '     .ZrangeAdd "0.0", "0.0"',
        '     .SingleEnded "False"', '     .WaveguideMonitor "False"', "     .Create", "End With"])

# ── 14. Solver (copiado de tu macro) ────────────────────────────────────────
add("define time domain solver parameters", """Mesh.SetCreator "High Frequency"
With Solver
     .Method "Hexahedral"
     .CalculationType "TD-S"
     .StimulationPort "All"
     .StimulationMode "All"
     .SteadyStateLimit "-40"
     .MeshAdaption "False"
     .AutoNormImpedance "False"
     .NormingImpedance "50"
     .CalculateModesOnly "False"
     .SParaSymmetry "False"
     .StoreTDResultsInCache  "False"
     .RunDiscretizerOnly "False"
     .FullDeembedding "False"
     .SuperimposePLWExcitation "False"
     .UseSensitivityAnalysis "False"
End With""".splitlines())


# ── Escritura ───────────────────────────────────────────────────────────────
def check(lines):
    opened = sum(l.strip().startswith("With ") for l in lines)
    closed = sum(l.strip() == "End With" for l in lines)
    assert opened == closed, lines


def vb_str(text):
    return text.replace('"', '""')


def main():
    hist = ["' UPM v2 - historial generado por gen_cst_macro.py (no editar a mano)", "' Parámetros:"]
    hist += [f"'   {n:<7} = {v:<14} ' {d}" for n, v, d in PARAMS]
    bas = ["' UPM v2 - macro generada por gen_cst_macro.py (no editar a mano)",
           "' Uso: proyecto CST nuevo y vacío -> Macros > Run Macro... -> este archivo.",
           "' Crea los parámetros y añade cada paso al History List.",
           "", "Option Explicit", "", "Sub Main ()", "    Dim s As String", ""]
    for n, v, d in PARAMS:
        bas.append(f'    StoreParameter "{n}", "{vb_str(v)}"')
    bas.append("")
    for i, (cap, lines) in enumerate(blocks, 1):
        check(lines)
        hist += ["", f"'## {i:02d} - {cap}", *lines]
        bas.append(f"    ' {i:02d} - {cap}")
        bas.append('    s = ""')
        bas += [f'    s = s & "{vb_str(l)}" & vbCrLf' for l in lines]
        bas.append(f'    AddToHistory "{vb_str(cap)}", s')
        bas.append("")
    bas += ['    MsgBox "UPM v2: ' + str(len(blocks)) + ' pasos añadidos al historial.", vbInformation', "End Sub", ""]

    (HERE / "UPM_v2_macro.bas").write_text("\r\n".join(bas), encoding="cp1252")
    (HERE / "UPM_v2_history.txt").write_text("\r\n".join(hist) + "\r\n", encoding="cp1252")
    print(f"{len(blocks)} bloques -> UPM_v2_macro.bas, UPM_v2_history.txt")


if __name__ == "__main__":
    main()
