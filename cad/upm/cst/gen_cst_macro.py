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
    ("dpst", "1.5875", "agujero para pasador de 1/16 in"),
    ("dprc", "1.638", "agujero de alineación de la otra diagonal"),
    ("lal", "3", "profundidad de los agujeros de alineación de brida"),
    ("chir", "1", "1 o -1: intercambia las diagonales pasador/agujero"),
    ("xm3", "11.5", "paso de los tornillos M3 en x"),
    ("ym3", "11.45", "posición de los M3 en y"),
    ("dm3", "3.4", "agujero pasante M3"),
    ("hexS", "5.7", "entrecaras del alojamiento de tuerca M3"),
    ("hexH", "2.6", "profundidad del alojamiento de tuerca"),
    ("xab", "17.25", "pasadores de centrado A/B: |x|"),
    ("yab", "7.8", "pasadores de centrado A/B: |y|"),
    ("dpress", "2.95", "agujero en la base para pasador Ø3 a presión"),
    ("dslip", "3.05", "agujero/ranura en la tapa para pasador Ø3 (deslizante)"),
    ("lab", "5", "profundidad del pasador en la base"),
    ("slotL", "0.3", "alargamiento de la ranura B (en dirección A-B)"),
]

# Dirección unitaria B -> A para la ranura B (A = (-xab, yab), B = (xab, -yab)).
_ax, _ay = -2 * 17.25, 2 * 7.8
_n = (_ax ** 2 + _ay ** 2) ** 0.5
UX, UY = f"{_ax / _n:.6f}", f"{_ay / _n:.6f}"

XDF = "(-Lwg/2+tboss)"          # cara del disco (izquierda)
ZBOT = "(zpart-Hhalf)"
ZTOP = "(zpart+Hhalf)"

blocks = []                     # (caption, [líneas])
OPS = []                        # mismas operaciones en forma estructurada (para check_geometry.py)


def q(*vals):
    return ", ".join(f'"{v}"' for v in vals)


def add(caption, lines):
    blocks.append((caption, lines))


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


def mirror_y(shape):
    """Copia simétrica respecto al plano y = 0 y la une al original."""
    OPS.append(("mirror_y", shape))
    _transform(shape, "Mirror", ['     .Origin "Free"', '     .Center "0", "0", "0"',
                                 '     .PlaneNormal "0", "1", "0"'])


def rotate_z180(shape):
    """Copia girada 180° alrededor del eje z (NO espejo: la brida es quiral) y unida."""
    OPS.append(("rotate_z180", shape))
    _transform(shape, "Rotate", ['     .Origin "Free"', '     .Center "0", "0", "0"',
                                 '     .Angle "0", "0", "180"'])


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

# ── 7. Pines: 1 pin -> 2 (fila exterior) -> 4 (espejo) -> 316 (79 en x) ────
cyl("Base", "pins", "z", "dpin/2-tpl", ("-bWR/2-0.01", "-bWR/2+hpin"), "x0pin", "y1pin")
translate("Base:pins", ("0", "ppin", "0"))
mirror_y("Base:pins")
translate("Base:pins", ("ppin", "0", "0"), reps="78")
boolean("Add", "Base:mono", "Base:pins")

# ── 8. Taladros de la brida izquierda, copia girada 180° a la derecha ───────
cyl("Base", "fl", "x", "dcb/2+tpl", (f"{XDF}-0.1", f"{XDF}+lcb"), "0", "BCfl/2")
tools = [("cbB", "dcb/2+tpl", f"{XDF}+lcb", "0", "-BCfl/2"),
         ("tpT", "dtap/2+tpl", f"{XDF}+ltap", "0", "BCfl/2"),
         ("tpB", "dtap/2+tpl", f"{XDF}+ltap", "0", "-BCfl/2"),
         ("al1", "dpst/2+tpl", f"{XDF}+lal", "chir*r45", "r45"),
         ("al2", "dpst/2+tpl", f"{XDF}+lal", "-chir*r45", "-r45"),
         ("al3", "dprc/2+tpl", f"{XDF}+lal", "-chir*r45", "r45"),
         ("al4", "dprc/2+tpl", f"{XDF}+lal", "chir*r45", "-r45")]
for name, r, x1, yc, zc in tools:
    cyl("Base", name, "x", r, (f"{XDF}-0.1", x1), yc, zc)
    boolean("Add", "Base:fl", f"Base:{name}")
rotate_z180("Base:fl")
boolean("Subtract", "Base:mono", "Base:fl")

# ── 9. Agujeros pasantes M3 (10) ────────────────────────────────────────────
cyl("Base", "m3", "z", "dm3/2+tpl", (f"{ZBOT}-0.1", f"{ZTOP}+0.1"), "-2*xm3", "ym3")
mirror_y("Base:m3")
translate("Base:m3", ("xm3", "0", "0"), reps="4")
boolean("Subtract", "Base:mono", "Base:m3")

# ── 10. Partir: cada mitad (y cada media brida) en su componente ────────────
translate("Base:mono", ("0", "0", "0"), unite=False, dest="Tapa")
brick("Base", "cutB", ("-Lwg/2-1", "Lwg/2+1"), ("-Wbody/2-1", "Wbody/2+1"), ("-Rdisc-1", "zpart"))
brick("Tapa", "cutT", ("-Lwg/2-1", "Lwg/2+1"), ("-Wbody/2-1", "Wbody/2+1"), ("zpart", "Rdisc+1"))
intersect("Base:mono", "Base:cutB")
intersect("Tapa:mono", "Tapa:cutT")
rename("Base:mono", "base")
rename("Tapa:mono", "tapa")

# ── 11. Base: agujeros ciegos para los pasadores A y B (a presión) ──────────
cyl("Base", "pA", "z", "dpress/2", ("zpart-lab", "zpart+0.1"), "-xab", "yab")
cyl("Base", "pB", "z", "dpress/2", ("zpart-lab", "zpart+0.1"), "xab", "-yab")
boolean("Add", "Base:pA", "Base:pB")
boolean("Subtract", "Base:base", "Base:pA")

# ── 12. Tapa: A redondo, B ranura (hacia A), alojamientos de tuerca ─────────
cyl("Tapa", "hA", "z", "dslip/2+tpl", ("zpart-0.1", f"{ZTOP}+0.1"), "-xab", "yab")
cyl("Tapa", "hB", "z", "dslip/2+tpl", ("zpart-0.1", f"{ZTOP}+0.1"),
    f"xab-({UX})*slotL/2", f"-yab-({UY})*slotL/2")
translate("Tapa:hB", (f"({UX})*slotL/2", f"({UY})*slotL/2", "0"), reps="2")
boolean("Add", "Tapa:hA", "Tapa:hB")
boolean("Subtract", "Tapa:tapa", "Tapa:hA")
cyl("Tapa", "hex", "z", "(hexS/2+tpl)/0.8660254", (f"{ZTOP}-hexH", f"{ZTOP}+0.1"),
    "-2*xm3", "ym3", seg="6")
mirror_y("Tapa:hex")
translate("Tapa:hex", ("xm3", "0", "0"), reps="4")
boolean("Subtract", "Tapa:tapa", "Tapa:hex")

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
