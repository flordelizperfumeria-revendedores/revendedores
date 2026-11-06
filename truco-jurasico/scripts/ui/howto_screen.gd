extends Control
## "Cómo se juega": reglamento resumido en páginas, con las cartas dibujadas.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Scenery = preload("res://scripts/ui/scenery.gd")
const CardView = preload("res://scripts/ui/card_view.gd")
const Cards = preload("res://scripts/core/cards.gd")

var main
var page := 0
var _text: RichTextLabel
var _cards_row: HBoxContainer
var _page_label: Label

const PAGES := [
	{"title": "La jerarquía de las cartas", "cards": true, "text":
		"Se juega con el [b]mazo español de 40 cartas[/b] (sin 8 ni 9). Cada jugador recibe 3 cartas y se juegan hasta [b]3 bazas[/b]: en cada una, la carta más alta gana.\n\nDe mayor a menor: [color=#ffd060]ancho de espada, ancho de basto, siete de espada, siete de oro[/color], los 3, los 2, los anchos falsos (copa y oro), los 12, 11, 10, los sietes falsos (copa y basto), 6, 5 y 4.\n\nCon las [b]ayudas[/b] activadas, cada carta muestra una barra de fuerza."},
	{"title": "Ganar la mano", "cards": false, "text":
		"Gana la mano quien gana [b]2 bazas[/b]. El que gana una baza tira primero en la siguiente.\n\n[b]Pardas[/b] (empates):\n• Parda la primera: gana quien gane la segunda.\n• Parda la segunda o la tercera: gana quien ganó la primera.\n• Todo pardo: gana [b]la mano[/b] (el que jugó primero en esa ronda).\n\nUna mano sin truco vale [b]1 punto[/b]. La mano se alterna en cada ronda."},
	{"title": "El truco", "cards": false, "text":
		"En tu turno podés cantar [color=#ff8060][b]TRUCO[/b][/color]. El rival responde:\n• [b]Quiero[/b]: la mano pasa a valer 2.\n• [b]No quiero[/b]: ganás 1 punto y se termina la mano.\n• [b]Quiero retruco[/b] (vale 3) y después [b]quiero vale cuatro[/b] (vale 4).\n\nSolo puede subir la apuesta quien [i]aceptó[/i] la última. Si no se quiere, se cobra lo que valía antes (retruco no querido = 2, vale cuatro no querido = 3).\n\n[b]Irse al mazo[/b]: abandonás la mano y el rival cobra lo que esté en juego (+1 si fue en la primera baza sin cantar envido)."},
	{"title": "El envido", "cards": false, "text":
		"Se canta en la [b]primera baza[/b], antes de tirar tu primera carta. Tus [b]tantos[/b]: dos cartas del mismo palo suman [b]20 + sus valores[/b] (las figuras valen 0). Sin dos del mismo palo, vale tu carta más alta. Máximo: 33.\n\n• [b]Envido[/b] = 2 · [b]Real envido[/b] = 3 · [b]Falta envido[/b] = lo que le falta al que va ganando para terminar.\n• Se pueden encadenar: envido-envido (4), envido-real (5), envido-envido-real (7)…\n• Si no se quiere, quien cantó cobra lo acumulado antes (mínimo 1).\n• Empate: gana la mano.\n\n[b]El envido está primero[/b]: si te cantan truco en la primera baza, podés contestar con envido. Una vez querido el truco ya no hay envido."},
	{"title": "Flor (opcional) y puntos", "cards": false, "text":
		"Con la [b]flor[/b] activada, quien tiene [b]tres cartas del mismo palo[/b] debe cantarla antes de jugar: vale [b]3 puntos[/b] y anula el envido.\n\nSi el rival también tiene flor puede responder:\n• [b]Contraflor[/b]: se comparan (20 + las tres cartas) y el mejor gana 6.\n• [b]Con flor me achico[/b]: el primero cobra 4.\n\nLas partidas son a [b]15[/b] o [b]30[/b] puntos (a 30: las primeras 15 son \"malas\" y las otras \"buenas\"). Los puntos se anotan con fósforos, de a cinco."},
]


func _ready() -> void:
	var sc := Scenery.new()
	sc.show_table = false
	add_child(sc)
	UI.full_rect(sc)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	add_child(margin)
	UI.full_rect(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	_page_label = UI.title("", 38)
	v.add_child(_page_label)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", -10)
	v.add_child(_cards_row)
	var order := [Cards.make(1, 0), Cards.make(1, 1), Cards.make(7, 0), Cards.make(7, 2), Cards.make(3, 3), Cards.make(2, 2), Cards.make(1, 3), Cards.make(12, 1), Cards.make(11, 0), Cards.make(10, 2), Cards.make(7, 3), Cards.make(6, 1), Cards.make(5, 0), Cards.make(4, 3)]
	for c in order:
		var cv := CardView.new()
		cv.setup(c, true)
		cv.show_hint = true
		cv.custom_minimum_size = Vector2(78, 117)
		_cards_row.add_child(cv)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_text)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	v.add_child(nav)
	var back := UI.button("Menú", UI.GRAY, 18)
	back.pressed.connect(func(): main.show_menu())
	nav.add_child(back)
	var prev := UI.button("◀ Anterior", UI.BLUE, 18)
	prev.pressed.connect(func(): _go(page - 1))
	nav.add_child(prev)
	var nxt := UI.button("Siguiente ▶", UI.GREEN, 18)
	nxt.pressed.connect(func(): _go(page + 1))
	nav.add_child(nxt)
	_go(0)


func _go(p: int) -> void:
	page = clampi(p, 0, PAGES.size() - 1)
	var d: Dictionary = PAGES[page]
	_page_label.text = "%d/%d · %s" % [page + 1, PAGES.size(), d["title"]]
	_cards_row.visible = d["cards"]
	_text.text = d["text"]
