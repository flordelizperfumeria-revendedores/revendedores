#!/usr/bin/env python3
"""Actualiza los datos del panel de revendedores (index.html) desde el Sheet de stock.

Uso:
  python3 tools/actualizar.py --lista lista.json --combos combos.json --dolar 1580 --fecha 25/10/2026

lista.json  = valores de 'Lista completa'!A4:L (filas desde el encabezado para abajo, sin el encabezado)
combos.json = valores de 'Combos'!A4:F (nombre, perfume 1, 2, 3, precio, mostrar)

Solo reescribe el bloque entre /*DATOS:INICIO*/ y /*DATOS:FIN*/ y la fecha/dólar del encabezado.
El diseño, los textos, el pack de la semana y la escala no se tocan.
"""
import argparse, json, os, re, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HTML = os.path.join(RAIZ, "index.html")
CFG = os.path.join(RAIZ, "tools", "config.json")


def num(txt):
    """'U$S 63' -> 63 · '$ 159.000' -> 159000 · '1,5' -> 1.5"""
    t = re.sub(r"[^\d,.-]", "", str(txt or ""))
    if not t:
        return None
    if "," in t:  # formato es-AR: 1.234,5
        t = t.replace(".", "").replace(",", ".")
    elif t.count(".") >= 1 and len(t.split(".")[-1]) == 3:  # 159.000
        t = t.replace(".", "")
    try:
        v = float(t)
    except ValueError:
        return None
    return int(v) if v == int(v) else v


def limpiar_emoji(s):
    return re.sub(r"[^\w\s&+'’·.,()/-]", "", s, flags=re.UNICODE).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lista", required=True)
    ap.add_argument("--combos", required=True)
    ap.add_argument("--dolar", required=True, type=float)
    ap.add_argument("--fecha", required=True)
    a = ap.parse_args()

    cfg = json.load(open(CFG, encoding="utf-8"))
    lista = json.load(open(a.lista, encoding="utf-8"))
    combos_raw = json.load(open(a.combos, encoding="utf-8"))
    if isinstance(lista, dict):
        lista = lista.get("values", [])
    if isinstance(combos_raw, dict):
        combos_raw = combos_raw.get("values", [])

    fotos = {f[:-5] for f in os.listdir(os.path.join(RAIZ, "img")) if f.endswith(".webp")}
    productos, nuevos, sin_foto = [], [], []
    for r in lista:
        r = list(r) + [""] * (12 - len(r))
        cod, cat_s, marca, nom, stock, _, usd = r[0].strip(), r[1].strip(), r[2].strip(), r[3].strip(), num(r[4]), r[5], num(r[6])
        if not cod or cod in cfg["excluir"] or not stock or stock <= 0 or not usd:
            continue
        cat = cfg["categorias"].get(cat_s)
        if not cat:
            print("AVISO categoría desconocida:", cod, cat_s, file=sys.stderr)
            continue
        n = cfg["nombres"].get(cod)
        if n:
            m, nombre, cat = n["m"], n["n"], n.get("cat", cat)
        else:
            m, nombre = cfg["marcas"].get(marca, marca), nom
            nuevos.append(f"{cod} {m} {nom}")
        if cod not in fotos:
            sin_foto.append(f"{cod} {m} {nombre}")
        productos.append({"c": cod, "m": m, "n": nombre, "s": int(stock), "u": usd, "cat": cat,
                          "tag": r[9].strip(), "temp": r[10].strip()})

    codigos = {p["c"] for p in productos}
    combos = []
    for r in combos_raw:
        r = list(r) + [""] * (6 - len(r))
        nombre, items, precio, mostrar = r[0], [x.split("·")[0].strip() for x in r[1:4] if x and x.strip()], num(r[4]), str(r[5]).upper()
        if not nombre.strip() or not items or not precio or mostrar not in ("TRUE", "VERDADERO"):
            continue
        if not all(c in codigos for c in items):
            continue  # algún perfume sin stock: el combo no se muestra
        combos.append({"n": limpiar_emoji(nombre), "items": items, "ars": precio})

    img = {c: f"img/{c}.webp" for c in sorted(codigos & fotos)}
    dolar = int(a.dolar) if a.dolar == int(a.dolar) else a.dolar
    bloque = ("/*DATOS:INICIO*/\n"
              f"const DOLAR = {dolar}, WA = \"5491170644765\";\n"
              f"const PRODUCTOS = {json.dumps(productos, ensure_ascii=False)};\n"
              f"const COMBOS = {json.dumps(combos, ensure_ascii=False)};\n"
              f"const IMG = {json.dumps(img)};\n"
              f"const FIJO = new Set({json.dumps(cfg['precio_fijo'])});\n"
              "/*DATOS:FIN*/")

    html = open(HTML, encoding="utf-8").read()
    html, k = re.subn(r"/\*DATOS:INICIO\*/.*?/\*DATOS:FIN\*/", lambda _: bloque, html, flags=re.S)
    if k != 1:
        sys.exit("No encontré el bloque de datos en index.html")
    dol_txt = f"{dolar:,}".replace(",", ".")
    html, k = re.subn(r"Stock al \d{2}/\d{2}/\d{4}<br>Dólar \$[\d.]+", f"Stock al {a.fecha}<br>Dólar ${dol_txt}", html)
    if k != 1:
        sys.exit("No encontré la fecha del encabezado")
    open(HTML, "w", encoding="utf-8").write(html)

    print(f"OK: {len(productos)} productos, {sum(p['s'] for p in productos)} unidades, {len(combos)} combos")
    if nuevos:
        print("Productos nuevos (usan el nombre del Sheet):", *nuevos, sep="\n  ")
    if sin_foto:
        print("Sin foto:", *sin_foto, sep="\n  ")


if __name__ == "__main__":
    main()
