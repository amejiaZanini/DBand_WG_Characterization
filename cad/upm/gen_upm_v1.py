"""Planos DXF del prototipo UPM v1 (impresión LCD/SLA + electrodeposición).

Uso:    python cad/upm/gen_upm_v1.py
Salida: UPM_v1_layout.dxf, UPM_v1_layout.png y UPM_v1_vs_actual.png en esta carpeta.

Cotas en mm.  Ejes: x a lo largo de la guía (origen en el centro), y transversal,
z vertical con z = 0 en el plano de partición (cara de la tapa = cara de los raíles).
Los valores marcados VERIFICAR dependen de la brida del extensor del VNA.
"""
import math
from pathlib import Path

import ezdxf
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from ezdxf.addons.drawing import matplotlib as ezmpl
from ezdxf.enums import TextEntityAlignment
from matplotlib.patches import Circle, Polygon, Rectangle

OUT = Path(__file__).resolve().parent

# ── Parámetros ────────────────────────────────────────────────────────────────
T_PLATE = 0.005                     # espesor de chapado de diseño (5 µm)

X_FACE = 68.24 / 2                  # cara del resalte de contacto (boca)
T_FLANGE = 7.62
X_FL_BACK = X_FACE - T_FLANGE       # 26.50
BOSS_D, BOSS_H = 9.525, 0.508       # resalte de contacto (STEP actual)
X_DISC_FACE = X_FACE - BOSS_H       # 33.612
R_FLANGE = 19.1 / 2
Z_AXIS = -0.41                      # centro de la boca (la cavidad va de z=-0.82 a 0)
H_HALF = 6.0

SPINE_HW = 11.0                     # semiancho del cuerpo de la guía (raíles 5..11)
BLOCK_HX, BLOCK_HY = 17.5, 35.0
CAV_HX, CAV_HY, CAV_D = 31.5, 5.0, 0.82
WR_HW = 1.651 / 2 + T_PLATE         # canal y boca compensados: 1.661
RELIEF = 0.20

PIN_D = 0.400 - 2 * T_PLATE         # 0.390 en resina → 0.400 tras chapar
PIN_H = 0.77
PITCH = 0.80
ROWS_Y = (1.0255, 1.8255)
X_PIN0 = -CAV_HX + 0.30
N_PER_ROW = 79
PIN_XS = [X_PIN0 + PITCH * k for k in range(N_PER_ROW)]

ALIGN_Y = 15.028
ALIGN_D = 3.000

M3_XS = (-23.0, -11.5, 0.0, 11.5, 23.0)
M3_Y = 7.8
M3_HOLE = 3.4
M3_HEAD = 5.5
M3_HEAD_H = 3.0
NUT_AF = 5.7
NUT_H = 2.6

BC_FLANGE = 14.288                  # 4-40 y alineamiento en el mismo círculo (STEP)
D_FL_ALIGN = 1.778                  # 4x a 45°
TAP_4_40 = 2.261                    # broca de roscar 4-40 (#43)
THREAD_4_40 = 2.845                 # diámetro nominal 4-40
TAP_DEPTH = 6.0                     # ciego: no sale por detrás del disco

# Diseño actual (STEP FV4_EBG_C_raw) para la comparativa
OLD_SPINE_HW = 10.0
OLD_FLANGE_HW = 12.5
OLD_ALIGN = [(x, s * 15.0145) for x in (-12.0, 0.0, 13.5) for s in (1, -1)]
OLD_M3 = [(x, s * 25.0185) for x in (-6.0, 5.875) for s in (1, -1)]

assert len(PIN_XS) * 2 * len(ROWS_Y) == 316
assert abs(PIN_XS[-1] - (CAV_HX - 0.30)) < 1e-9


def outline(spine_hw=SPINE_HW, flange_hw=R_FLANGE):
    b = BOSS_D / 2
    pts = [(-X_FACE, -b), (-X_DISC_FACE, -b), (-X_DISC_FACE, -flange_hw),
           (-X_FL_BACK, -flange_hw), (-X_FL_BACK, -spine_hw),
           (-BLOCK_HX, -spine_hw), (-BLOCK_HX, -BLOCK_HY), (BLOCK_HX, -BLOCK_HY),
           (BLOCK_HX, -spine_hw), (X_FL_BACK, -spine_hw), (X_FL_BACK, -flange_hw),
           (X_DISC_FACE, -flange_hw), (X_DISC_FACE, -b), (X_FACE, -b)]
    return pts + [(x, -y) for x, y in reversed(pts)]


def tapped_hole_plan(v):
    for sx in (1, -1):
        x0, x1 = sorted((sx * X_DISC_FACE, sx * (X_DISC_FACE - TAP_DEPTH)))
        v.rect(x0, -TAP_4_40 / 2, x1, TAP_4_40 / 2, "HIDDEN")


def hexagon(cx, cy, af):
    r = af / math.sqrt(3)
    return [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
            for a in range(0, 360, 60)]


# ── DXF ───────────────────────────────────────────────────────────────────────
class View:
    def __init__(self, msp, ox, oy, s=1.0):
        self.msp, self.ox, self.oy, self.s = msp, ox, oy, s

    def p(self, x, y):
        return (self.ox + self.s * x, self.oy + self.s * y)

    def poly(self, pts, layer, close=True):
        self.msp.add_lwpolyline([self.p(*q) for q in pts], close=close,
                                dxfattribs={"layer": layer})

    def rect(self, x0, y0, x1, y1, layer):
        self.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], layer)

    def circle(self, x, y, d, layer):
        self.msp.add_circle(self.p(x, y), self.s * d / 2, dxfattribs={"layer": layer})

    def line(self, a, b, layer):
        self.msp.add_line(self.p(*a), self.p(*b), dxfattribs={"layer": layer})

    def text(self, s, x, y, h=1.2, layer="TEXT",
             align=TextEntityAlignment.MIDDLE_CENTER, rot=0):
        self.msp.add_text(s, height=h, rotation=rot, dxfattribs={"layer": layer}) \
            .set_placement(self.p(x, y), align=align)

    def hatch(self, pts, layer, color, scale=0.6):
        h = self.msp.add_hatch(color=color, dxfattribs={"layer": layer})
        h.set_pattern_fill("ANSI31", scale=scale)
        h.paths.add_polyline_path([self.p(*q) for q in pts], is_closed=True)

    def dim(self, p1, p2, base, angle=0, h=1.0, text="<>"):
        self.msp.add_linear_dim(
            base=self.p(*base), p1=self.p(*p1), p2=self.p(*p2), angle=angle, text=text,
            override={"dimtxt": h, "dimasz": 0.8 * h, "dimlfac": 1 / self.s,
                      "dimdec": 3, "dimzin": 8, "dimexe": 0.6, "dimexo": 0.6,
                      "dimgap": 0.3 * h},
            dxfattribs={"layer": "DIMS"}).render()


def view_bottom_plan(v):
    v.text("MITAD INFERIOR - planta (desde arriba)", 0, BLOCK_HY + 8, h=2.4)
    v.poly(outline(), "OUTLINE")
    for sy in (1, -1):
        wing = [(-BLOCK_HX, sy * SPINE_HW), (BLOCK_HX, sy * SPINE_HW),
                (BLOCK_HX, sy * BLOCK_HY), (-BLOCK_HX, sy * BLOCK_HY)]
        v.hatch(wing, "RELIEF", color=4)
        v.text("Rebaje 0.20 (sin contacto)", 0, sy * 29, h=1.5)
        for sx in (1, -1):
            v.text("raíl", sx * 17.25, sy * 10.1, h=0.8)
    v.rect(-CAV_HX, -CAV_HY, CAV_HX, CAV_HY, "CAVITY")
    for sx in (1, -1):
        for sy in (1, -1):
            v.line((sx * CAV_HX, sy * WR_HW), (sx * X_FACE, sy * WR_HW), "CAVITY")
    for y in ROWS_Y:
        for sy in (1, -1):
            for x in PIN_XS:
                v.circle(x, sy * y, PIN_D, "PINS")
    for x in M3_XS:
        for sy in (1, -1):
            v.circle(x, sy * M3_Y, M3_HOLE, "HOLES")
            v.poly(hexagon(x, sy * M3_Y, NUT_AF), "HIDDEN")
    for sy, tag in ((1, "A: pasador cilíndrico Ø3"), (-1, "B: pasador rómbico Ø3")):
        v.circle(0, sy * ALIGN_Y, ALIGN_D, "ALIGN")
        v.text(tag, 0, sy * (ALIGN_Y + 3.0), h=1.3, layer="ALIGN")
    tapped_hole_plan(v)
    v.line((-X_FACE - 2, 0), (X_FACE + 2, 0), "CENTER")
    v.line((0, -BLOCK_HY - 2), (0, BLOCK_HY + 2), "CENTER")

    v.dim((-X_FACE, -R_FLANGE), (X_FACE, -R_FLANGE), (0, -BLOCK_HY - 5))
    v.dim((-CAV_HX, -CAV_HY), (CAV_HX, -CAV_HY), (0, -BLOCK_HY - 10))
    v.dim((-BLOCK_HX, BLOCK_HY), (BLOCK_HX, BLOCK_HY), (0, BLOCK_HY + 3))
    v.dim((-X_FL_BACK, -SPINE_HW), (-X_FL_BACK, SPINE_HW), (-42, 0), angle=90)
    v.dim((-CAV_HX, -CAV_HY), (-CAV_HX, CAV_HY), (-38, 0), angle=90)
    v.dim((X_FACE, -R_FLANGE), (X_FACE, R_FLANGE), (40, 0), angle=90, text="Ø<>")
    v.dim((X_FL_BACK, R_FLANGE), (X_FACE, R_FLANGE), (0, SPINE_HW + 1.5))
    v.dim((0, 0), (0, ALIGN_Y), (4, 0), angle=90)
    v.dim((23, 0), (23, M3_Y), (28.5, 0), angle=90)
    v.dim((0, M3_Y), (11.5, M3_Y), (0, 13.5))
    v.dim((11.5, M3_Y), (23, M3_Y), (0, 13.5))


def view_top_plan(v):
    v.text("MITAD SUPERIOR (tapa plana) - planta (desde arriba)", 0, BLOCK_HY + 8, h=2.4)
    v.poly(outline(), "OUTLINE")
    v.rect(-CAV_HX, -CAV_HY, CAV_HX, CAV_HY, "HIDDEN")
    for x in M3_XS:
        for sy in (1, -1):
            v.circle(x, sy * M3_Y, M3_HOLE, "HOLES")
            v.circle(x, sy * M3_Y, M3_HEAD, "HARDWARE")
    v.circle(0, ALIGN_Y, ALIGN_D, "ALIGN")
    v.circle(0, -ALIGN_Y, ALIGN_D, "ALIGN")
    v.text("A: Ø3.000 H7 (escariar tras chapado)", 0, ALIGN_Y + 3.0, h=1.3, layer="ALIGN")
    v.text("B: Ø3.000 H7 (escariar; pasador rómbico)", 0, -ALIGN_Y - 3.0, h=1.3,
           layer="ALIGN")
    tapped_hole_plan(v)
    v.text("M3 ISO 4762 (10x), par bajo ~0.3 N·m", 0, -24, h=1.3)
    v.line((-X_FACE - 2, 0), (X_FACE + 2, 0), "CENTER")
    v.line((0, -BLOCK_HY - 2), (0, BLOCK_HY + 2), "CENTER")


def view_section_x0(v):
    v.text("SECCIÓN A-A (x = 0)", 0, 12, h=2.4)
    bottom = [(-BLOCK_HY, -H_HALF), (BLOCK_HY, -H_HALF), (BLOCK_HY, -RELIEF),
              (SPINE_HW, -RELIEF), (SPINE_HW, 0), (CAV_HY, 0), (CAV_HY, -CAV_D),
              (-CAV_HY, -CAV_D), (-CAV_HY, 0), (-SPINE_HW, 0), (-SPINE_HW, -RELIEF),
              (-BLOCK_HY, -RELIEF)]
    v.poly(bottom, "OUTLINE")
    v.rect(-BLOCK_HY, 0, BLOCK_HY, H_HALF, "OUTLINE")
    for y in ROWS_Y:
        for sy in (1, -1):
            v.rect(sy * y - PIN_D / 2, -CAV_D, sy * y + PIN_D / 2, -CAV_D + PIN_H, "PINS")
    for sy in (1, -1):
        yc = sy * M3_Y
        for e in (-M3_HOLE / 2, M3_HOLE / 2):
            v.line((yc + e, -H_HALF), (yc + e, H_HALF), "HOLES")
        v.rect(yc - NUT_AF / 2, -H_HALF, yc + NUT_AF / 2, -H_HALF + NUT_H, "HOLES")
        v.rect(yc - M3_HEAD / 2, H_HALF, yc + M3_HEAD / 2, H_HALF + M3_HEAD_H, "HARDWARE")
        ya = sy * ALIGN_Y
        for e in (-ALIGN_D / 2, ALIGN_D / 2):
            v.line((ya + e, -H_HALF), (ya + e, H_HALF), "ALIGN")
        v.rect(ya - ALIGN_D / 2 + 0.1, -H_HALF + 1, ya + ALIGN_D / 2 - 0.1, H_HALF - 1, "ALIGN")
    v.text("Mitad superior (tapa plana)", -26, 3, h=1.3)
    v.text("Mitad inferior", -26, -3.5, h=1.3)
    v.text("raíl", 8, 0.9, h=0.8)
    v.text("rebaje 0.20", 24, 0.9, h=0.8)
    v.text("M3 + tuerca", M3_Y, -7.6, h=0.9)
    v.text("pasador Ø3", ALIGN_Y, -7.6, h=0.9)
    v.dim((-BLOCK_HY, -H_HALF), (-BLOCK_HY, 0), (-38, 0), angle=90)
    v.dim((-BLOCK_HY, 0), (-BLOCK_HY, H_HALF), (-38, 0), angle=90)
    v.dim((-SPINE_HW, 0), (SPINE_HW, 0), (0, 10))


def view_detail(v):
    v.text("DETALLE B (x10): cavidad, gap y pines - cotas reales", 0, 1.35, h=2.4)
    v.poly([(-5.6, 0), (-CAV_HY, 0), (-CAV_HY, -CAV_D), (CAV_HY, -CAV_D), (CAV_HY, 0),
            (5.6, 0)], "OUTLINE", close=False)
    lid = [(-5.6, 0), (5.6, 0), (5.6, 0.12), (-5.6, 0.12)]
    v.hatch(lid, "TEXT", color=8, scale=0.4)
    v.text("tapa (mitad superior)", -3.7, 0.2, h=1.4)
    for y in ROWS_Y:
        for sy in (1, -1):
            v.rect(sy * y - PIN_D / 2, -CAV_D, sy * y + PIN_D / 2, -CAV_D + PIN_H, "PINS")
    y_out = ROWS_Y[1] + PIN_D / 2
    y_in = ROWS_Y[0] - PIN_D / 2
    v.dim((y_out, -CAV_D + PIN_H), (y_out, 0), (2.6, 0), angle=90, h=2.0)
    v.dim((-y_out, -CAV_D), (-y_out, -CAV_D + PIN_H), (-2.6, 0), angle=90, h=2.0)
    v.dim((CAV_HY, -CAV_D), (CAV_HY, 0), (5.45, 0), angle=90, h=2.0)
    v.dim((y_in, -CAV_D), (y_in + PIN_D, -CAV_D), (0, -0.98), h=2.0)
    v.dim((ROWS_Y[0], -0.05), (ROWS_Y[1], -0.05), (0, 0.32), h=2.0)
    v.dim((-y_in, -0.05), (y_in, -0.05), (0, 0.32), h=2.0)
    v.dim((-CAV_HY, 0), (CAV_HY, 0), (0, 0.62), h=2.0)


def view_flange(v):
    v.text("CARA DE BRIDA (x3): lapear el resalte con las mitades montadas, antes del chapado",
           0, R_FLANGE + 4, h=2.0)
    v.circle(0, Z_AXIS, 2 * R_FLANGE, "OUTLINE")
    v.circle(0, Z_AXIS, BOSS_D, "OUTLINE")
    half = math.sqrt(R_FLANGE ** 2 - Z_AXIS ** 2)
    v.line((-half, 0), (half, 0), "OUTLINE")
    v.rect(-WR_HW, -CAV_D, WR_HW, 0, "CAVITY")
    v.circle(0, Z_AXIS, BC_FLANGE, "CENTER")
    rs = BC_FLANGE / 2
    for z in (Z_AXIS + rs, Z_AXIS - rs):
        v.circle(0, z, TAP_4_40, "HOLES")
        v.circle(0, z, THREAD_4_40, "HIDDEN")
    for a in (45, 135, 225, 315):
        v.circle(rs * math.cos(math.radians(a)), Z_AXIS + rs * math.sin(math.radians(a)),
                 D_FL_ALIGN, "ALIGN")
    v.text("2x 4-40 UNC roscado arriba/abajo, ciego prof. 6 (broca Ø2.261)", 0,
           -R_FLANGE - 2.0, h=1.4)
    v.text("4x Ø1.778 a 45°, prof. 3;  todo en BC Ø14.288 (como el CAD actual)", 0,
           -R_FLANGE - 3.6, h=1.4)
    v.text(f"resalte de contacto Ø{BOSS_D} x {BOSS_H}", 0, Z_AXIS - 2.9, h=1.2)
    v.text("partición z=0 (techo de la cavidad, 0.41 sobre el eje)", R_FLANGE + 1, 0.6, h=1.2,
           align=TextEntityAlignment.MIDDLE_LEFT)
    v.dim((-R_FLANGE, Z_AXIS), (R_FLANGE, Z_AXIS), (0, -R_FLANGE - 6.5), h=2.0, text="Ø<>")
    v.dim((-WR_HW, -CAV_D), (WR_HW, -CAV_D), (0, -2.6), h=2.0)


def view_coupons(v_bar, v_patch):
    v_bar.text("PROBETA 1: contracción (medir c/c tras imprimir y tras chapar)", 0, 6, h=1.6)
    v_bar.rect(-32, -3, 32, 3, "OUTLINE")
    for x in (-30, 30):
        v_bar.circle(x, 0, ALIGN_D, "ALIGN")
    v_bar.dim((-30, 0), (30, 0), (0, -6), h=1.4)

    v_patch.text("PROBETA 2 (x3): 5x5 pines + raíl -> gap y espesor de chapado (corte)",
                 0, 6.0, h=1.6)
    v_patch.rect(-4, -4, 4, 4, "OUTLINE")
    v_patch.rect(-2.5, -2.5, 2.5, 2.5, "CAVITY")
    for i in range(5):
        for j in range(5):
            v_patch.circle(-1.6 + 0.8 * i, -1.6 + 0.8 * j, PIN_D, "PINS")
    v_patch.dim((-2.5, -2.5), (2.5, -2.5), (0, -5.0), h=1.4)


NOTES = [
    "NOTAS (UPM v1)",
    "1. Cotas en mm. Diseño para chapado t = 5 µm: pines Ø0.390 (0.400 - 2t), canal y boca 1.661 (1.651 + 2t).",
    "   Las alturas NO se compensan: con tapa plana, el gap y la altura de boca no cambian con un chapado uniforme.",
    "2. Gap = raíl - pin = 0.820 - 0.770 = 0.050 ± 0.015. Se mide en la mitad inferior antes de montar.",
    "3. Capas de 10 µm en Z (0.77, 0.82 y 0.05 múltiplos exactos). Raíles y pines sin soportes.",
    "4. Alineamiento: solo A (cilíndrico) + B (rómbico). Imprimir Ø2.90 y escariar Ø3.000 H7 tras chapar.",
    "   Pasadores de acero Ø3; pegados en la mitad inferior. Holgura diametral máx. 0.03 (ideal <= 0.02).",
    "5. M3 pasantes Ø3.4 con tuerca alojada (sin roscas en resina). Las alas van rebajadas 0.20.",
    "6. Brida estándar Ø19.1 con el patrón del CAD actual (BC Ø14.288). Los 4-40 son ciegos (prof. 6):",
    "   ya no salen por detrás del disco rozando la cara del cuerpo. Roscar tras chapar (o helicoil).",
    "7. CAMBIO vs CAD actual: la partición pasa de media altura de la cavidad (z = 0.41) al techo",
    "   (tapa plana). El gap queda definido y medible en una sola pieza.",
]


def build_dxf():
    doc = ezdxf.new("R2018", setup=True)
    doc.units = ezdxf.units.MM
    doc.header["$LTSCALE"] = 0.4
    for name, color, lt in (("OUTLINE", 7, "CONTINUOUS"), ("HIDDEN", 8, "DASHED"),
                            ("CENTER", 8, "CENTER"), ("CAVITY", 5, "CONTINUOUS"),
                            ("PINS", 6, "CONTINUOUS"), ("HOLES", 1, "CONTINUOUS"),
                            ("ALIGN", 3, "CONTINUOUS"), ("RELIEF", 4, "CONTINUOUS"),
                            ("HARDWARE", 8, "CONTINUOUS"), ("DIMS", 7, "CONTINUOUS"),
                            ("TEXT", 7, "CONTINUOUS")):
        doc.layers.add(name, color=color, linetype=lt)
    msp = doc.modelspace()

    view_bottom_plan(View(msp, 0, 0))
    view_top_plan(View(msp, 0, 100))
    view_section_x0(View(msp, 130, 0, s=1.5))
    view_detail(View(msp, 130, 45, s=10))
    view_flange(View(msp, 130, -64, s=3))
    view_coupons(View(msp, 245, 30), View(msp, 245, 5, s=3))
    vt = View(msp, -40, -62)
    for i, line in enumerate(NOTES):
        vt.text(line, 0, -2.4 * i, h=1.6 if i else 2.0,
                align=TextEntityAlignment.MIDDLE_LEFT)

    path = OUT / "UPM_v1_layout.dxf"
    doc.saveas(path)
    ezmpl.qsave(msp, str(OUT / "UPM_v1_layout.png"), bg="#FFFFFF", dpi=170,
                size_inches=(26, 17))
    return path


# ── Comparativa actual vs propuesto (PNG) ────────────────────────────────────
def _plan(ax, new):
    spine = SPINE_HW if new else OLD_SPINE_HW
    fl = R_FLANGE if new else OLD_FLANGE_HW
    ax.add_patch(Polygon(outline(spine, fl), closed=True, fc="#f3efe2", ec="k", lw=1.2))
    if new:
        for sy in (1, -1):
            y0 = SPINE_HW if sy > 0 else -BLOCK_HY
            ax.add_patch(Rectangle((-BLOCK_HX, y0), 2 * BLOCK_HX, BLOCK_HY - SPINE_HW,
                                   fc="none", ec="#7aa7c7", hatch="///", lw=0))
            y0r = CAV_HY if sy > 0 else -SPINE_HW
            ax.add_patch(Rectangle((-X_FL_BACK, y0r), 2 * X_FL_BACK, SPINE_HW - CAV_HY,
                                   fc="#cfe8cf", ec="none", alpha=0.9))
    ax.add_patch(Rectangle((-CAV_HX, -CAV_HY), 2 * CAV_HX, 2 * CAV_HY,
                           fc="white", ec="#3a5ba0", lw=1.0))
    xs = [x for x in PIN_XS for _ in range(4)]
    ys = [s * y for _ in PIN_XS for y in ROWS_Y for s in (1, -1)]
    ax.scatter(xs, ys, s=1.2, c="#9c4f96", lw=0)
    if new:
        for x in M3_XS:
            for sy in (1, -1):
                ax.add_patch(Circle((x, sy * M3_Y), M3_HOLE / 2, fc="#5b84c4", ec="k", lw=0.6))
        ax.add_patch(Circle((0, ALIGN_Y), ALIGN_D / 2, fc="#3f9b5a", ec="k", lw=0.8))
        ax.add_patch(Circle((0, -ALIGN_Y), ALIGN_D / 2, fc="#9bd1a8", ec="k", lw=0.8))
        ax.text(0, ALIGN_Y + 3.4, "A cilíndrico", ha="center", fontsize=8)
        ax.text(0, -ALIGN_Y - 4.6, "B rómbico", ha="center", fontsize=8)
    else:
        for x, y in OLD_ALIGN:
            ax.add_patch(Circle((x, y), 1.5, fc="white", ec="k", lw=0.8))
            ax.add_patch(Circle((x, y), 1.4, fc="#c0504d", ec="none"))
        for x, y in OLD_M3:
            ax.add_patch(Circle((x, y), 1.7, fc="#5b84c4", ec="k", lw=0.6))
    ax.set_xlim(-40, 40)
    ax.set_ylim(-40, 40)
    ax.set_aspect("equal")
    ax.axis("off")


def build_comparison():
    fig, axs = plt.subplots(1, 2, figsize=(17, 9.2))
    _plan(axs[0], new=False)
    _plan(axs[1], new=True)
    axs[0].set_title("ACTUAL (STEP FV4_EBG_C_raw)", fontsize=14, fontweight="bold")
    axs[1].set_title("PROPUESTO UPM v1", fontsize=14, fontweight="bold")
    box = dict(boxstyle="round,pad=0.4", fc="white", ec="0.6", alpha=0.95)
    for txt, xy, xyt in (
            ("6 pasadores Ø3.0 en Ø3.2\n→ juego ±100 µm y sobre-restringido\n(se agarrota si la resina contrae)",
             (13.5, 15.0), (19, 25)),
            ("4 M3 a 25 mm del eje\n→ nada aprieta la tapa junto al canal\n(combadura → gap fuera de ±20 µm)",
             (-6.0, -25.0), (-39, -37)),
            ("Brida Ø25 moleteada\n4-40 pasante: sale a ~10 µm\nde la cara del cuerpo", (31, 11), (17, 32))):
        axs[0].annotate(txt, xy, xyt, fontsize=8.5, bbox=box,
                        arrowprops=dict(arrowstyle="->", color="0.3"))
    for txt, xy, xyt in (
            ("2 pasadores: A fija posición, B solo giro\nØ3 H7 escariado → ±10 µm, sin agarrotamiento",
             (0, ALIGN_Y), (8, 27)),
            ("10 M3 sobre los raíles (y = ±7.8)\naprietan la tapa junto a la cavidad",
             (11.5, M3_Y), (21, 15)),
            ("Raíles de apoyo (verde)\nalas rebajadas 0.20 (rayado)\n→ la tapa solo apoya junto al canal",
             (-14, -14), (-39, -37)),
            ("Brida estándar Ø19.1, mismo patrón\n4-40 ciego (prof. 6): sin conflicto", (31, 6), (16, -30))):
        axs[1].annotate(txt, xy, xyt, fontsize=8.5, bbox=box,
                        arrowprops=dict(arrowstyle="->", color="0.3"))
    fig.tight_layout()
    path = OUT / "UPM_v1_vs_actual.png"
    fig.savefig(path, dpi=160, facecolor="white")
    plt.close(fig)
    return path


if __name__ == "__main__":
    print(build_dxf())
    print(build_comparison())
