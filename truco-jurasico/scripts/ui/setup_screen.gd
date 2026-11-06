extends Control
## Selección de personajes, escenario y opciones de la partida.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Scenery = preload("res://scripts/ui/scenery.gd")
const Portrait = preload("res://scripts/ui/portrait.gd")
const Chars = preload("res://scripts/data/characters.gd")

var main
var mode := "ai"
var sel := ["cirilo", "rex"]
var _cards := [[], []]
var _bio: Label


func _ready() -> void:
	sel = [Save.settings["p0"], Save.settings["p1"]]
	if sel[0] == sel[1]:
		sel[1] = Chars.LIST[(Chars.LIST.find(sel[0]) + 1) % Chars.LIST.size()]
	var sc := Scenery.new()
	sc.show_table = false
	add_child(sc)
	UI.full_rect(sc)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	add_child(shade)
	UI.full_rect(shade)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	UI.full_rect(margin)
	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 18)
	margin.add_child(main_row)

	# Columna izquierda: personajes
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	main_row.add_child(left)
	left.add_child(UI.title("ELEGÍ LOS JUGADORES", 40))
	var labels := ["VOS", "TU RIVAL (MÁQUINA)"] if mode == "ai" else ["JUGADOR 1", "JUGADOR 2"]
	for p in 2:
		left.add_child(UI.label(labels[p], 22, UI.GOLD))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		left.add_child(row)
		for id in Chars.LIST:
			var card := _char_card(p, id)
			row.add_child(card)
			_cards[p].append(card)
	_bio = UI.label("", 17, UI.CREAM, 4)
	_bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bio.custom_minimum_size = Vector2(600, 50)
	left.add_child(_bio)

	# Columna derecha: opciones
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 380
	main_row.add_child(panel)
	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 8)
	panel.add_child(opts)
	opts.add_child(UI.label("ESCENARIO", 18, UI.GOLD))
	var scen := UI.label("Pulpería Prehistórica\nTafí del Valle", 19)
	opts.add_child(scen)
	opts.add_child(UI.label("PARTIDA A", 18, UI.GOLD))
	opts.add_child(UI.toggle_group(["15 puntos", "30 puntos"], [15, 30], Save.settings["target"], func(v): Save.settings["target"] = v))
	opts.add_child(UI.label("FLOR", 18, UI.GOLD))
	opts.add_child(UI.toggle_group(["Sin flor", "Con flor"], [false, true], Save.settings["flor"], func(v): Save.settings["flor"] = v))
	if mode == "ai":
		opts.add_child(UI.label("DIFICULTAD", 18, UI.GOLD))
		opts.add_child(UI.toggle_group(["Fácil", "Normal", "Difícil"], [0, 1, 2], Save.settings["difficulty"], func(v): Save.settings["difficulty"] = v))
	opts.add_child(UI.label("AYUDAS (fuerza de cartas, envido)", 16, UI.GOLD))
	opts.add_child(UI.toggle_group(["Sí", "No"], [true, false], Save.settings["hints"], func(v): Save.settings["hints"] = v))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opts.add_child(spacer)
	var play := UI.button("¡A JUGAR!", UI.GREEN, 28, Vector2(0, 62))
	play.pressed.connect(_start)
	opts.add_child(play)
	var back := UI.button("Volver", UI.GRAY, 18)
	back.pressed.connect(func(): main.show_menu())
	opts.add_child(back)
	_refresh()


func _char_card(p: int, id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(196, 196)
	b.toggle_mode = false
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(v)
	UI.full_rect(v)
	var por := Portrait.new()
	por.character = id
	por.custom_minimum_size = Vector2(120, 120)
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(por)
	var d: Dictionary = Chars.get_data(id)
	var n := UI.label(d["name"], 17)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var st := UI.label(d["style"], 14, UI.GOLD, 3)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	b.set_meta("id", id)
	b.set_meta("portrait", por)
	b.pressed.connect(func():
		Audio.play("click")
		if sel[1 - p] == id:
			sel[1 - p] = sel[p]   # intercambiar
		sel[p] = id
		por.bounce()
		_refresh()
		_bio.text = "%s — %s. %s" % [d["name"], d["title"], d["bio"]])
	return b


func _refresh() -> void:
	for p in 2:
		for b in _cards[p]:
			var on: bool = b.get_meta("id") == sel[p]
			UI.color_button(b, Color(0.55, 0.3, 0.1) if on else Color(0.18, 0.12, 0.08, 0.85))
			b.modulate = Color.WHITE if on else Color(1, 1, 1, 0.7)
	if _bio.text == "":
		var d: Dictionary = Chars.get_data(sel[1])
		_bio.text = "%s — %s. %s" % [d["name"], d["title"], d["bio"]]


func _start() -> void:
	Save.settings["p0"] = sel[0]
	Save.settings["p1"] = sel[1]
	Save.save()
	main.start_game({
		"mode": mode, "chars": sel.duplicate(), "target": Save.settings["target"],
		"flor": Save.settings["flor"], "difficulty": Save.settings["difficulty"],
		"hints": Save.settings["hints"], "scenario": "tafi",
	})
