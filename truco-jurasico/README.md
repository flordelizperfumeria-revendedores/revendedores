# Truco Jurásico – Valles Calchaquíes (MVP)

Juego de Truco Argentino ambientado en unos Valles Calchaquíes donde los
dinosaurios nunca se extinguieron. Hecho en **Godot 4.4** (GDScript), sin
archivos de arte ni de audio externos: todo (cartas, personajes, escenario,
música y efectos) se genera por código. Pesa menos de 200 KB de código fuente.

## Cómo jugarlo ya (en tu computadora)

1. Descargá **Godot 4.4.1** (versión estándar, no la .NET) de
   https://godotengine.org/download/archive/4.4.1-stable/ — es un solo
   ejecutable, no hay que instalar nada.
2. Abrí Godot → **Importar** → elegí el archivo `truco-jurasico/project.godot`.
3. Apretá **F5** (o el botón ▶ arriba a la derecha).

## Qué tiene esta versión

| Funciona | Detalle |
|---|---|
| Reglas completas del truco (2 jugadores) | Mazo de 40, jerarquía, 3 bazas, pardas, truco / retruco / vale cuatro (con derecho a subir), envido / real envido / falta envido encadenados, "el envido está primero", irse al mazo, flor opcional (flor, contraflor, con flor me achico), partidas a 15 o 30 |
| Modos | Contra la máquina, o 2 personas en el mismo dispositivo (con pantalla para pasarse el celular sin ver las cartas del otro) |
| IA | 3 dificultades. Estima la probabilidad de ganar simulando cientos de manos posibles (Monte Carlo) con solo la información que tendría una persona. Cada personaje juega distinto |
| 3 personajes | **Don Rex** (T-Rex, agresivo), **Cirilo Amaicha** (gaucho, conservador), **Yanina "La Brava"** (cantora de peña, impredecible). Cada uno con ~60 frases propias, cargadas entre ellos y expresiones |
| Escenario | Pulpería Prehistórica de Tafí del Valle: Aconquija nevado, dique La Angostura, menhires, braquiosaurio y pterodáctilos animados |
| Animaciones | Reparto, cartas que vuelan a la mesa, carteles de TRUCO/ENVIDO, mesa que tiembla con el vale cuatro, T-Rex que ruge si le cantan falta envido, festejos y caras de bronca |
| Sonido | Loop de chacarera (bombo legüero, guitarra y quena) y efectos, sintetizados |
| Interfaz | Menú, selección de personajes y opciones, "Cómo se juega" (5 páginas), estadísticas guardadas, pausa, anotador con fósforos, ayudas para principiantes (fuerza de cada carta y tus tantos de envido) |
| Offline | No usa internet para nada |

**Todavía NO está** (próximas etapas): 4 y 6 jugadores, torneo, desbloqueables,
los otros 4 escenarios, tutorial guiado paso a paso, multijugador online y arte
final dibujado por un ilustrador. No hay botones falsos para esas cosas.

### Reglas de la casa (variantes que elegimos)
- **Falta envido** = lo que le falta al que va ganando para llegar al final.
- **Irse al mazo** en la primera baza sin haberse cantado envido: el rival suma 1 extra.
- **Flor**: 3 puntos; si ambos tienen, "contraflor" (gana 6 el mejor) o "con flor me achico" (4 al primero). La flor es obligatoria y anula el envido.
- Después de una parda, abre la siguiente baza el que es mano.
- Los puntos del envido se anotan en el momento (si alguien llega al final con el envido, termina la partida).

Están todas en `scripts/core/truco_match.gd`; cambiarlas es tocar una función.

## Arquitectura

```
truco-jurasico/
├── project.godot            Config (renderer "Compatibility": anda en equipos modestos y en web)
├── scenes/main.tscn         Única escena; todo lo demás se arma por código
├── scripts/
│   ├── core/                ← LÓGICA PURA, sin nodos ni pantallas
│   │   ├── cards.gd         Mazo, jerarquía, envido, flor, quién gana la mano
│   │   ├── truco_match.gd   Motor de reglas: acciones → estado → eventos
│   │   └── truco_ai.gd      IA (solo ve lo que vería una persona)
│   ├── data/
│   │   ├── characters.gd    Personajes, personalidad de juego y frases
│   │   └── save_data.gd     (autoload "Save") opciones y estadísticas en user://
│   ├── audio/
│   │   ├── synth.gd         Sintetizador: efectos y música
│   │   └── audio_manager.gd (autoload "Audio")
│   └── ui/                  Pantallas y dibujo (menú, selección, mesa, cartas, retratos…)
└── tests/
    ├── run_tests.gd         Tests de reglas + 120 partidas IA vs IA
    └── ui_smoke.gd          Juega partidas completas tocando la interfaz y saca capturas
```

**Principio clave:** la pantalla nunca decide reglas. Le manda al motor
`apply(jugador, {"type": "truco"})` y el motor devuelve eventos (`call`,
`play`, `baza`, `envido_result`, `hand_end`…) que la pantalla anima en orden.

**Multijugador online (etapa 2):** como el motor es determinístico y no
depende de la interfaz, se puede correr el mismo `truco_match.gd` en un
servidor (Godot headless o portado) que reciba acciones por WebSocket y
reenvíe a cada jugador su `get_view(p)` (que ya oculta las cartas del rival)
y los eventos. La UI no cambia: solo cambia de dónde salen los eventos.

**4 y 6 jugadores:** el motor hoy usa jugadores 0 y 1. Para equipos hay que
generalizar `hands/dealt/bazas` a N jugadores y sumar por equipo; la
resolución de bazas y la lógica de cantos se reutilizan.

**Arte final:** los personajes están dibujados con polígonos en
`scripts/ui/portrait.gd` (funciones `_draw_rex`, `_draw_cirilo`,
`_draw_yanina`). Para usar ilustraciones reales, reemplazar esas funciones
por un `TextureRect`/`AnimatedSprite2D` por expresión. Igual con las cartas
(`card_view.gd`) y el escenario (`scenery.gd`).

## Tests

```bash
# Reglas (362 verificaciones + 120 partidas completas IA vs IA)
godot --headless --path truco-jurasico --script res://tests/run_tests.gd

# Interfaz: 3 partidas jugadas tocando cartas/botones + modo 2 jugadores, con capturas
xvfb-run godot --path truco-jurasico --rendering-driver opengl3 --script res://tests/ui_smoke.gd -- /tmp/capturas
```

## Exportar a cada plataforma

En Godot: **Editor → Gestionar plantillas de exportación → Descargar e instalar**
(una sola vez). Después **Proyecto → Exportar → Añadir…**:

- **Windows / Linux**: agregar el preset y "Exportar proyecto". Sale un `.exe` (o binario) listo.
- **Mac**: preset macOS → exporta un `.app`/`.dmg`. Para distribuir sin advertencias hace falta firmar con cuenta de Apple Developer.
- **Android**: instalar Android SDK + JDK 17 (Godot explica cómo en *Editor → Configuración del editor → Exportar → Android*), crear un keystore de debug y exportar el `.apk`. Para Google Play, exportar `.aab` con keystore de release.
- **iOS**: necesita una Mac con Xcode. Godot exporta un proyecto Xcode; se compila y firma desde ahí (cuenta Apple Developer).
- **Web** (para probar rápido o compartir un link): preset "Web" → exportar `.html` y subir a cualquier hosting estático (itch.io, por ejemplo).

La orientación ya está fijada en horizontal y la interfaz se escala sola a
cualquier pantalla (`stretch mode = canvas_items`).
