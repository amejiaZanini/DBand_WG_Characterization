#!/usr/bin/env python3
"""
build-html.py — Build the HTML version of a results deck from the same spec.json
that build-pptx.py uses. Self-contained output (CSS inline, images base64) so the
file renders standalone. Slide numbers auto via JS; cover title is editable.

Usage: python3 build-html.py <spec.json> <out.html>
Images referenced in the spec are embedded; cover/logo/emblem come from ../assets.
"""
import base64, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.path.dirname(HERE)
ASSETS = os.path.join(SKILL, "assets")

def b64(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()

def esc(s):
    return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

CSS = """
:root{--red:#C00D1E;--dark1:#000;--light1:#fff;--dark2:#44546A;--light2:#E7E6E6;
--okfill:#C6EFCE;--oktext:#006100;--accent3:#A5A5A5;
--ft:"Calibri Light","Carlito","Segoe UI",sans-serif;--fb:"Calibri","Carlito","Segoe UI",sans-serif;}
*{margin:0;padding:0;box-sizing:border-box;}
body{background:#2b2b2b;font-family:var(--fb);}
.deck{display:flex;flex-direction:column;align-items:center;gap:18px;padding:18px;}
.wrap{width:min(1280px,96vw);}
.slide{position:relative;width:1280px;height:720px;background:#fff;overflow:hidden;box-shadow:0 6px 24px rgba(0,0,0,.4);transform-origin:top left;}
.footer-rule{position:absolute;left:37px;top:658px;width:1207px;height:1px;background:var(--dark2);}
.logo{position:absolute;left:37px;top:674px;height:28px;}.logo img{height:100%;}
.slide-number{position:absolute;left:496px;top:667px;width:288px;height:38px;display:flex;align-items:center;justify-content:center;font:13px var(--fb);color:var(--dark2);}
.restricted{position:absolute;right:0;bottom:0;height:30px;background:var(--red);border-radius:6px 0 0 0;display:flex;align-items:center;gap:6px;padding:0 12px 0 10px;font:700 13px var(--fb);color:#fff;}
.restricted .box{border:1px solid #fff;border-radius:3px;padding:1px 7px;}
.header{position:absolute;left:-9px;top:40px;width:445px;height:50px;background:var(--red);border-radius:0 14px 14px 0;}
.header-rule{position:absolute;left:449px;top:69px;width:782px;height:1px;background:var(--dark2);}
.slide-title{position:absolute;left:28px;top:49px;font:700 24px var(--ft);color:#fff;}
.section-sub{position:absolute;right:40px;top:48px;font:17px var(--fb);color:var(--dark2);text-decoration:underline;text-underline-offset:3px;}
.action{position:absolute;left:67px;top:100px;right:67px;font:700 24px var(--ft);color:var(--dark2);}
.body{position:absolute;left:67px;top:165px;right:67px;bottom:72px;}
.bullets li{font:20px var(--fb);color:#000;margin:10px 0 10px 22px;}
.fig{display:flex;flex-direction:column;align-items:center;height:100%;}
.fig img{max-width:1150px;max-height:430px;object-fit:contain;}
.caption{font:12px var(--fb);color:var(--dark2);margin-top:8px;text-align:center;}
.figbul li{font:16px var(--fb);color:#000;margin:6px 0 6px 22px;}
.cover-band{position:absolute;left:0;top:0;width:1280px;height:155px;background:var(--red);border-radius:0 0 18px 18px;}
.cover-title{position:absolute;right:40px;top:34px;font:700 40px var(--ft);color:#fff;text-align:right;}
.cover-date{position:absolute;right:40px;top:108px;font:20px var(--fb);color:#fff;text-align:right;}
.cover-car{position:absolute;left:50%;top:180px;transform:translateX(-50%);width:1060px;}.cover-car img{width:100%;display:block;}
.tbl-title{position:absolute;left:88px;top:150px;right:67px;font:700 20px var(--fb);color:#000;}
.rtable{position:absolute;left:88px;top:210px;border-collapse:collapse;font:14px var(--fb);color:#000;}
.rtable th,.rtable td{border:1px solid #000;padding:5px 10px;text-align:center;}
.rtable th{font-weight:700;background:var(--light2);}
.rtable td.ok{background:var(--okfill);color:var(--oktext);}
.ty{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;padding-top:120px;}
.ty h1{font:700 54px var(--ft);color:#000;}
.ty .lead{margin-top:90px;font:40px var(--ft);color:#000;}
.ty .sub{margin-top:6px;font:18px var(--fb);color:#000;}
.ty img{margin-top:40px;height:150px;}
"""

def furniture(logo):
    return (f'<div class="footer-rule"></div><div class="logo"><img src="{logo}"/></div>'
            '<div class="restricted">Confidentiality:<span class="box">Restricted</span></div>'
            '<div class="slide-number"></div>')

def slide(inner):
    return f'<div class="wrap"><div class="slide">{inner}</div></div>'

def header(h, sec):
    s = f'<div class="header"></div><div class="header-rule"></div><div class="slide-title">{esc(h)}</div>'
    if sec:
        s += f'<div class="section-sub">{esc(sec)}</div>'
    return s

def main(spec_path, out):
    spec = json.load(open(spec_path, encoding="utf-8"))
    logo = b64(os.path.join(ASSETS, "logo.png"))
    car = b64(os.path.join(ASSETS, "car.png"))
    emb = b64(os.path.join(ASSETS, "emblem.png"))
    S = []
    # cover
    S.append(slide(
        '<div class="cover-band"></div>'
        f'<div class="cover-title" contenteditable="true">{esc(spec.get("title",""))}</div>'
        f'<div class="cover-date" contenteditable="true">{esc(spec.get("date",""))}</div>'
        f'<div class="cover-car"><img src="{car}"/></div>' + furniture(logo)))
    for sl in spec.get("slides", []):
        t = sl.get("type")
        if t == "context":
            lis = "".join(f"<li>{esc(b)}</li>" for b in sl.get("bullets", []))
            S.append(slide(header(sl.get("header",""), sl.get("section","")) +
                f'<div class="action">{esc(sl.get("action",""))}</div>'
                f'<div class="body"><ul class="bullets">{lis}</ul></div>' + furniture(logo)))
        elif t == "figure":
            img = b64(sl["image"])
            cap = f'<div class="caption">{esc(sl.get("caption",""))}</div>' if sl.get("caption") else ""
            bul = ""
            if sl.get("bullets"):
                lis = "".join(f"<li>{esc(b)}</li>" for b in sl["bullets"])
                bul = f'<ul class="figbul">{lis}</ul>'
            S.append(slide(header(sl.get("header",""), sl.get("section","")) +
                f'<div class="action">{esc(sl.get("action",""))}</div>'
                f'<div class="body"><div class="fig"><img src="{img}"/>{cap}{bul}</div></div>' + furniture(logo)))
        elif t == "table":
            tb = sl["table"]; th = "".join(f"<th>{esc(x)}</th>" for x in tb["header"])
            ok = {(r, c) for r, c in tb.get("ok", [])}
            rows = ""
            for i, row in enumerate(tb["rows"]):
                tds = "".join(f'<td class="ok">{esc(str(v))}</td>' if (i, j) in ok else f"<td>{esc(str(v))}</td>"
                              for j, v in enumerate(row))
                rows += f"<tr>{tds}</tr>"
            S.append(slide(header("Summary", "Measured radome penalty") +
                f'<div class="tbl-title">{esc(tb.get("title",""))}</div>'
                f'<table class="rtable"><tr>{th}</tr>{rows}</table>' + furniture(logo)))
        elif t == "thanks":
            S.append(slide(
                '<div class="ty"><h1>Thank you</h1>'
                f'<div class="lead">{esc(sl.get("lead",""))}</div>'
                f'<div class="sub">{esc(sl.get("sub",""))}</div>'
                f'<img src="{emb}"/></div>' + furniture(logo)))
    js = ("function fit(){document.querySelectorAll('.wrap').forEach(w=>{var s=w.clientWidth/1280;"
          "var sl=w.querySelector('.slide');sl.style.transform='scale('+s+')';w.style.height=(720*s)+'px';});}"
          "window.addEventListener('resize',fit);fit();"
          "document.querySelectorAll('.slide').forEach(function(sl,i){var n=sl.querySelector('.slide-number');"
          "if(n)n.textContent=(i===0?'':String(i+1));});")
    html = (f'<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/>'
            f'<meta name="viewport" content="width=device-width, initial-scale=1.0"/>'
            f'<title>{esc(spec.get("title","deck"))}</title><style>{CSS}</style></head>'
            f'<body><div class="deck">{"".join(S)}</div><script>{js}</script></body></html>')
    open(out, "w", encoding="utf-8").write(html)
    return out

if __name__ == "__main__":
    print("built", main(sys.argv[1], sys.argv[2]))
