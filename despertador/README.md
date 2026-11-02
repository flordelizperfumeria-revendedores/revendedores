# Kiai · despertador con motivación

App Android (Kotlin, sin librerías externas) que te despierta con un sonido que sube de a poco
y un mensaje pensado para tu día: filosofía, gym, karate, abogacía, perfumería y Flor de Liz.

## Cómo funciona

1. Suena la alarma (taiko, épico, amanecer o tu propia canción) con volumen creciente.
2. Aparece el mensaje del día, elegido según lo que te toca ese día (pestaña **Semana**).
3. A los 7 segundos aparece un minijuego fácil (orden de números, cuenta o palabra del mensaje).
   No hay posponer.
4. Si en 5 minutos no lo resolviste, una voz te dice un mensaje directo y exigente, y se repite cada 2 minutos y medio.
5. Al resolverlo, la voz lee el mensaje del día y escribís tu intención para hoy.
6. La racha suma un día cada vez que te levantás antes del mensaje duro.

## Instalar

Cada cambio en `despertador/` compila el APK en GitHub Actions y lo publica en la sección
**Releases** del repo como `kiai.apk`. Se descarga desde el celular, se permite
"instalar apps desconocidas" para el navegador, y listo. Las versiones nuevas se instalan
encima sin perder datos (siempre se firman con la misma llave: `app/despertador.keystore`).

## Sonidos

Generados por código, originales: `python3 tools/generar_sonidos.py app/src/main/res/raw`.

## Mensajes

Están en `app/src/main/java/com/flordeliz/despertador/Mensajes.kt`. Para sumar uno,
agregá una línea con un id nuevo y su categoría.
