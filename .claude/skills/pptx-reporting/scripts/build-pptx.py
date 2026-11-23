#!/usr/bin/env python3
"""
build-pptx.py — Generate a Zanini-style results deck (.pptx) with python-pptx.

Geometry and colors mirror style-template.md (13.33 x 7.5 in). Slide numbers are
LIVE PowerPoint fields (auto-renumber); the cover title and date are ordinary
editable text, never the literal "Title".

Usage:
    python3 build-pptx.py <content.json> [out.pptx]
    python3 build-pptx.py --demo [out.pptx]

content.json schema (minimal):
{
  "title": "Radome reuse: E- to D-band",
  "date": "November 2026",
  "results": [
     {"header":"RLA001 – RR45", "section":"Transmission Measurements",
      "columns":[{"file":"S1 ...", "figures":[path,path,path,path,path,path]},
                 {"file":"S2 ...", "figures":[...]}]}
  ],
  "table": {"title":"Measured radome penalty (|θ| ≤ 30°)",
            "header":["Sample","Band","Mean IL (dB)","Range loss (%)",
                      "DoA in mask (%)","ΔDoA in mask (%)","Status"],
            "rows":[["S1 Monolithic","77 GHz","-1.13","6","87","93","Reuse OK"], ...],
            "ok":[[0,5],[0,6], ...]},          # [row, col] cells to mark green
  "thanks": {"lead":"Empowering auto brands to lead",
             "sub":"Automotive trim ...", }
}
Figures left empty -> a dashed "TIFF" placeholder is drawn.
"""
import json, os, sys, uuid
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml import parse_xml
from pptx.oxml.ns import nsdecls

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.path.dirname(HERE)
ASSETS = os.path.join(SKILL, "assets")

# ---- palette (style-template.md) -------------------------------------------
RED   = RGBColor(0xC0, 0x0D, 0x1E)
DARK2 = RGBColor(0x44, 0x54, 0x6A)
LIGHT2= RGBColor(0xE7, 0xE6, 0xE6)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
BLACK = RGBColor(0x00, 0x00, 0x00)
OKFILL= RGBColor(0xC6, 0xEF, 0xCE)
OKTEXT= RGBColor(0x00, 0x61, 0x00)
F_TITLE = "Calibri Light"
F_BODY  = "Calibri"

def _txt(slide, x, y, w, h, text, size, *, bold=False, color=BLACK, font=F_BODY,
         align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame; tf.word_wrap = True; tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    p = tf.paragraphs[0]; p.alignment = align
    r = p.add_run(); r.text = text
    r.font.size = Pt(size); r.font.bold = bold; r.font.name = font
    r.font.color.rgb = color
    return tb

def _rect(slide, x, y, w, h, fill, *, shape=MSO_SHAPE.RECTANGLE, line=None):
    sp = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    sp.fill.solid(); sp.fill.fore_color.rgb = fill
    if line is None:
        sp.line.fill.background()
    else:
        sp.line.color.rgb = line; sp.line.width = Pt(1)
    sp.shadow.inherit = False
    return sp

def _slide(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])  # blank

def _slidenum(slide):
    """Live slide-number field (PowerPoint auto-numbers). Well-formed a:fld so
    PowerPoint accepts it: canonical GUID id and correct rPr child order."""
    tb = slide.shapes.add_textbox(Inches(5.17), Inches(6.95), Inches(3.0), Inches(0.40))
    tf = tb.text_frame; tf.margin_top = tf.margin_bottom = 0
    pr = tf.paragraphs[0]; pr.alignment = PP_ALIGN.CENTER
    guid = "{%s}" % str(uuid.uuid4()).upper()
    xml = (
        '<a:fld %s id="%s" type="slidenum">'
        '<a:rPr lang="en-US" sz="1300" b="0">'
        '<a:solidFill><a:srgbClr val="44546A"/></a:solidFill>'
        '<a:latin typeface="%s"/></a:rPr>'
        '<a:t>1</a:t></a:fld>' % (nsdecls('a'), guid, F_BODY)
    )
    pr._p.append(parse_xml(xml))
    return tb

def _fixed(slide):
    """footer rule, logo, Restricted pill, live slide number — on every slide."""
    ln = slide.shapes.add_connector(2, Inches(0.39), Inches(6.85), Inches(12.96), Inches(6.85))
    ln.line.color.rgb = DARK2; ln.line.width = Pt(0.75)
    logo = os.path.join(ASSETS, "logo.png")
    if os.path.exists(logo):
        slide.shapes.add_picture(logo, Inches(0.39), Inches(7.04), height=Inches(0.30))
    # Restricted pill, flush to the bottom-right corner (single line)
    pill = _rect(slide, 11.03, 7.18, 2.30, 0.32, RED, shape=MSO_SHAPE.ROUNDED_RECTANGLE)
    tf = pill.text_frame; tf.word_wrap = False
    tf.margin_left = Inches(0.06); tf.margin_right = Inches(0.06); tf.margin_top = tf.margin_bottom = 0
    p = tf.paragraphs[0]; p.alignment = PP_ALIGN.CENTER
    r = p.add_run(); r.text = "Confidentiality: Restricted"
    r.font.size = Pt(11); r.font.bold = True; r.font.name = F_BODY; r.font.color.rgb = WHITE
    _slidenum(slide)

def _header(slide, title, section):
    _rect(slide, -0.09, 0.42, 4.64, 0.52, RED, shape=MSO_SHAPE.ROUNDED_RECTANGLE)
    ln = slide.shapes.add_connector(2, Inches(4.68), Inches(0.72), Inches(12.82), Inches(0.72))
    ln.line.color.rgb = DARK2; ln.line.width = Pt(0.75)
    _txt(slide, 0.30, 0.50, 4.2, 0.4, title, 18, bold=True, color=WHITE, font=F_TITLE)
    if section:
        _txt(slide, 8.3, 0.50, 4.5, 0.35, section, 13, color=DARK2, font=F_BODY, align=PP_ALIGN.RIGHT)

# ---- slide builders ---------------------------------------------------------
def cover(prs, title, date):
    s = _slide(prs)
    _rect(s, 0, 0, 13.33, 1.61, RED, shape=MSO_SHAPE.ROUNDED_RECTANGLE)
    car = os.path.join(ASSETS, "car.png")
    if os.path.exists(car):
        s.shapes.add_picture(car, Inches(1.16), Inches(1.9), width=Inches(11.0))
    _txt(s, 4.6, 0.30, 8.3, 0.7, title, 26, bold=True, color=WHITE, font=F_TITLE, align=PP_ALIGN.RIGHT)
    _txt(s, 4.6, 1.18, 8.3, 0.4, date, 16, color=WHITE, font=F_BODY, align=PP_ALIGN.RIGHT)
    _fixed(s)
    return s

def results(prs, header, section, columns):
    s = _slide(prs)
    _header(s, header, section)
    col_x = [0.35, 6.94]
    sub_x = [0.0, 2.77]        # within a 5.83in column
    lab_y = [1.20, 3.07, 4.95]
    for ci, col in enumerate(columns[:2]):
        cx = col_x[ci]
        _txt(s, cx, 0.92, 5.83, 0.25, col.get("file",""), 10, bold=True, align=PP_ALIGN.CENTER)
        labels = ["Attenuation","Phase","Attenuation Horizontal","Phase Horizontal",
                  "Attenuation Vertical","Phase Vertical"]
        figs = col.get("figures", [None]*6)
        for i in range(6):
            r, c = divmod(i, 2)
            lx = cx + sub_x[c]; ly = lab_y[r]
            _txt(s, lx, ly, 2.77, 0.2, labels[i], 8, color=DARK2, align=PP_ALIGN.CENTER)
            fx, fy, fw, fh = lx, ly+0.2, 2.69, 1.55
            path = figs[i] if i < len(figs) else None
            if path and os.path.exists(path):
                s.shapes.add_picture(path, Inches(fx), Inches(fy), width=Inches(fw), height=Inches(fh))
            else:
                ph = _rect(s, fx, fy, fw, fh, WHITE, line=RGBColor(0xA5,0xA5,0xA5))
                p = ph.text_frame.paragraphs[0]; p.alignment = PP_ALIGN.CENTER
                rr = p.add_run(); rr.text = "TIFF"; rr.font.size = Pt(9); rr.font.color.rgb = RGBColor(0xA5,0xA5,0xA5)
    _fixed(s)
    return s

def table_slide(prs, spec):
    s = _slide(prs)
    _header(s, "Summary", "Measured radome penalty")
    if spec.get("title"):
        _txt(s, 0.92, 2.45, 11.5, 0.3, spec["title"], 15, bold=True)
    header = spec["header"]; rows = spec["rows"]
    widths = [3.80, 1.48, 1.34, 1.00, 0.87, 1.37, 1.64]
    nrow, ncol = len(rows)+1, len(header)
    gt = s.shapes.add_table(nrow, ncol, Inches(0.92), Inches(2.87), Inches(11.5), Inches(0.3*nrow)).table
    gt.first_row = False; gt.horz_banding = False
    for j, w in enumerate(widths[:ncol]):
        gt.columns[j].width = Inches(w)
    ok = {(r, c) for r, c in spec.get("ok", [])}
    for j, h in enumerate(header):
        cell = gt.cell(0, j); cell.text = h
        pr = cell.text_frame.paragraphs[0]; pr.alignment = PP_ALIGN.CENTER
        pr.runs[0].font.size = Pt(10); pr.runs[0].font.bold = True; pr.runs[0].font.name = F_BODY
        cell.fill.solid(); cell.fill.fore_color.rgb = LIGHT2
    for i, row in enumerate(rows, start=1):
        for j, val in enumerate(row):
            cell = gt.cell(i, j); cell.text = str(val)
            pr = cell.text_frame.paragraphs[0]; pr.alignment = PP_ALIGN.CENTER
            pr.runs[0].font.size = Pt(10); pr.runs[0].font.name = F_BODY
            if (i-1, j) in ok:
                cell.fill.solid(); cell.fill.fore_color.rgb = OKFILL
                pr.runs[0].font.color.rgb = OKTEXT
            else:
                cell.fill.solid(); cell.fill.fore_color.rgb = WHITE
    _fixed(s)
    return s

def thanks(prs, spec):
    s = _slide(prs)
    _txt(s, 0, 1.2, 13.33, 0.9, "Thank you", 54, bold=True, align=PP_ALIGN.CENTER, font=F_TITLE)
    _txt(s, 0, 2.9, 13.33, 0.6, spec.get("lead",""), 40, align=PP_ALIGN.CENTER, font=F_TITLE)
    _txt(s, 0, 3.7, 13.33, 0.4, spec.get("sub",""), 18, align=PP_ALIGN.CENTER, font=F_BODY)
    emb = os.path.join(ASSETS, "emblem.png")
    if os.path.exists(emb):
        s.shapes.add_picture(emb, Inches(5.9), Inches(4.3), height=Inches(1.6))
    _fixed(s)
    return s

def _bullets(slide, x, y, w, h, bullets, size=18):
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame; tf.word_wrap = True
    for i, b in enumerate(bullets):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = PP_ALIGN.LEFT; p.space_after = Pt(6)
        r = p.add_run(); r.text = "•  " + b
        r.font.size = Pt(size); r.font.name = F_BODY; r.font.color.rgb = BLACK
    return tb

def _action(slide, title):
    """Full-width action-title line under the header rule."""
    if title:
        _txt(slide, 0.7, 1.00, 11.9, 0.5, title, 18, bold=True, color=DARK2, font=F_TITLE)

def content_slide(prs, header, section, bullets, action=None):
    s = _slide(prs); _header(s, header, section); _action(s, action)
    _bullets(s, 0.7, 1.7, 11.9, 4.6, bullets, size=20)
    _fixed(s); return s

def figure_slide(prs, header, section, image, bullets=None, caption=None, action=None):
    s = _slide(prs); _header(s, header, section); _action(s, action)
    from PIL import Image as _Img
    iw, ih = _Img.open(image).size; ar = iw / ih
    top = 1.55 if action else 1.3
    box_w, box_h = 11.6, (3.5 if bullets else (5.9 - top))
    w = box_w; h = w / ar
    if h > box_h: h = box_h; w = h * ar
    x = (13.333 - w) / 2.0; y = top
    s.shapes.add_picture(image, Inches(x), Inches(y), width=Inches(w), height=Inches(h))
    if caption:
        _txt(s, 0.7, y + h + 0.05, 11.9, 0.3, caption, 11, color=DARK2, align=PP_ALIGN.CENTER)
    if bullets:
        _bullets(s, 0.9, y + h + 0.2, 11.5, 6.6 - (y + h), bullets, size=16)
    _fixed(s); return s

def build(spec, out):
    prs = Presentation()
    prs.slide_width = Inches(13.333); prs.slide_height = Inches(7.5)
    cover(prs, spec.get("title", "Report title"), spec.get("date", ""))
    # ordered, typed slide list (preferred)
    for sl in spec.get("slides", []):
        t = sl.get("type")
        if t == "context":
            content_slide(prs, sl.get("header", ""), sl.get("section", ""), sl.get("bullets", []),
                          action=sl.get("action"))
        elif t == "figure":
            figure_slide(prs, sl.get("header", ""), sl.get("section", ""), sl["image"],
                         sl.get("bullets"), sl.get("caption"), action=sl.get("action"))
        elif t == "table":
            table_slide(prs, sl["table"])
        elif t == "thanks":
            thanks(prs, sl)
    # legacy keys
    for r in spec.get("results", []):
        results(prs, r.get("header", ""), r.get("section", ""), r.get("columns", []))
    if spec.get("table"):
        table_slide(prs, spec["table"])
    if spec.get("thanks"):
        thanks(prs, spec["thanks"])
    prs.save(out)
    return out

DEMO = {
    "title": "Radome reuse: E- to D-band", "date": "November 2026",
    "results": [{"header": "RLA001 – RR45 – TPR L12.2", "section": "Transmission Measurements",
                 "columns": [{"file": "R_RLA00110101-03S.4C01-26092112041_OK"},
                             {"file": "R_RLA00110101-03S.4C01-26092113016_OK"}]}],
    "table": {"title": "Measured radome penalty per band (|θ| ≤ 30°)",
              "header": ["Sample","Band","Mean IL (dB)","Range loss (%)","DoA in mask (%)","ΔDoA in mask (%)","Status"],
              "rows": [["S1 Monolithic","77 GHz","-1.13","6","87","93","Reuse OK"],
                       ["S1 Monolithic","140 GHz","-3.04","16","92","49","Needs layer"],
                       ["S2 2K PVD","77 GHz","-0.96","5","100","97","Reuse OK"],
                       ["S2 2K PVD","140 GHz","-3.26","17","98","85","Near miss"],
                       ["S3 Heated","77 GHz","-1.28","7","98","100","Reuse OK"],
                       ["S3 Heated","140 GHz","-6.01","29","69","52","Redesign"]],
              "ok": [[0,5],[0,6],[2,5],[2,6],[3,5],[4,5],[4,6]]},
    "thanks": {"lead": "Empowering auto brands to lead",
               "sub": "Automotive trim that takes style and function to the next level"},
}

if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        print(__doc__); sys.exit(0)
    if args[0] == "--demo":
        out = args[1] if len(args) > 1 else "deck.pptx"
        print("built", build(DEMO, out))
    else:
        spec = json.load(open(args[0], encoding="utf-8"))
        out = args[1] if len(args) > 1 else "deck.pptx"
        print("built", build(spec, out))
