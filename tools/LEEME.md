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
