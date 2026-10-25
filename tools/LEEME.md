# Cómo se actualiza el panel

El panel (`index.html`) se publica en https://revendedores.flordelizperfumes.com con GitHub Pages.
Es independiente de la tienda web: no comparte nada con WordPress.

## Actualización automática (desde el Sheet de stock)

Fuente: Google Sheets "Flor De Liz Stock al por MAYOR" (ID `1NtSjFWNxGN9Ls6XtUogiPzvd3l7-rv2vw5l8LGMbX_4`). Solo se LEE, nunca se escribe.

1. Leer `'Lista completa'!A4:L700` → guardar como `lista.json`.
2. Leer `Combos!A4:F40` → guardar como `combos.json`.
3. Leer `Inicio!C5` (cotización del dólar).
4. Correr: `python3 tools/actualizar.py --lista lista.json --combos combos.json --dolar <cotización> --fecha <dd/mm/aaaa>`
5. Si `index.html` cambió: commit y push a `main`. GitHub Pages publica solo en 1–2 minutos.

El script solo reescribe el bloque `/*DATOS:INICIO*/ … /*DATOS:FIN*/` (stock, precios, combos, fotos) y la fecha/dólar del encabezado.
No toca el pack de la semana, los textos, la escala ni el diseño.

## Reglas

- Se muestran solo productos con stock > 0. `tools/config.json → excluir` deja afuera productos aunque tengan stock (ej.: CK-007 Kit Barbie).
- Combos: se muestran si "Mostrar" está tildado y todos sus perfumes tienen stock.
- Nombres prolijos por código en `tools/config.json → nombres`. Un producto nuevo usa el nombre del Sheet hasta que se agregue ahí.
- Fotos: `img/<CÓDIGO>.webp` (cuadradas, ~360 px). Si falta, el panel muestra el nombre en lugar de la foto.
- Precio fijo (sin descuento por escala): `tools/config.json → precio_fijo` (margen < 20 % según la planilla de costos).

## Encargos (precio estimado desde Compras Paraguai)

Lista en `tools/encargos.json`. Cada producto: código (`c`, el del Sheet o `PY-xxx`), marca, nombre, presentación, categoría (`arabe` / `disenador` / `nicho`), URL de la ficha en comprasparaguai.com.br, `ofertas` (las 4 más baratas en USD, sin atacado/tester/kit/otra variante) y `fecha`.

- Precio base: la oferta más barata; si está 20 % o más abajo de la segunda, se usa la segunda.
- Precio al revendedor (USD, redondeado hacia arriba): árabes base × 1,52 · diseñador base × 1,42 · nicho base × 1,17 + 20.
- Si el producto tiene stock en el Sheet, no aparece como encargo (está en la lista de stock).
- Suman unidades para la escala, sin descuento. Leyenda: "pueden tardar hasta 15 días hábiles".

Actualización semanal: para cada producto, abrir la URL con WebFetch (de a 3–4 por vez, con pausa si aparece 429) y reemplazar `ofertas` y `fecha`. Para sumar productos: buscar en `https://www.comprasparaguai.com.br/busca/?q=<nombre>`, abrir la ficha de la presentación correcta y agregarlo. Después correr `actualizar.py` como siempre.
