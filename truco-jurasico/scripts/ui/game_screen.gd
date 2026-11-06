extends Control
## Mesa de truco: muestra el estado del motor (TrucoMatch), anima sus
## eventos en orden y traduce los toques del jugador en acciones.
## La lógica de reglas vive SOLO en scripts/core; acá no se decide nada.

const Cards = preload("res://scripts/core/cards.gd")
const Match = preload("res://scripts/core/truco_match.gd")
const AI = preload("res://scripts/core/truco_ai.gd")
const Chars = preload("res://scripts/data/characters.gd")
const UI = preload("res://scripts/ui/ui_kit.gd")
const CardView = preload("res://scripts/ui/card_view.gd")
const Portrait = preload("res://scripts/ui/portrait.gd")
const Scenery = preload("res://scripts/ui/scenery.gd")
const ScoreBoard = preload("res://scripts/ui/score_board.gd")

const CALL_TEXT := {
	"truco": "¡TRUCO!", "retruco": "¡QUIERO RETRUCO!", "vale_cuatro": "¡QUIERO VALE CUATRO!",
	"envido": "¡ENVIDO!", "real_envido": "¡REAL ENVIDO!", "falta_envido": "¡FALTA ENVIDO!",
	"flor": "¡FLOR!", "contraflor": "¡CONTRAFLOR!",
}
const CALL_NAMES := {
	"truco": "truco", "retruco": "retruco", "vale_cuatro": "vale cuatro",
	"envido": "envido", "real_envido": "real envido", "falta_envido": "falta envido",
}

var main
var cfg := {}
var m
var ais := [null, null]
var chars := ["cirilo", "rex"]
var names := ["", ""]
var viewer := 0               # jugador cuya mano se ve abajo
var revealed := true          # en 2 jugadores, la mano se tapa entre turnos
var busy := false
var human_turn := false
var queue: Array = []
var rng := RandomNumberGenerator.new()
var _stats_recorded := false

# Nodos
var scenery: Control
var layer: Control
var portrait_top: Control
var portrait_bottom: Control
var name_top: Label
var name_bottom: Label
var bubble_top: PanelContainer
var bubble_bottom: PanelContainer
var mano_tag: Label
var scoreboard: Control
var buttons_box: VBoxContainer
var status_label: Label
var stake_label: Label
var hint_label: Label
var banner: Label
var overlay: Control
var bottom_cards: Array = []
var top_cards: Array = []
var played_cards: Array = []
var _bubble_ids := {}


func _ready() -> void:
	UI.full_rect(self)   # tamaño real antes de calcular posiciones
	rng.randomize()
	chars = cfg.get("chars", ["cirilo", "rex"])
	for p in 2:
		names[p] = Chars.get_data(chars[p])["name"]
	if cfg.get("mode", "ai") == "ai":
		names[0] = "Vos"
		ais[1] = AI.new(Chars.get_data(chars[1])["personality"], int(cfg.get("difficulty", 1)))
	_build()
	resized.connect(_layout)
	_new_match.call_deferred()


func _new_match() -> void:
	m = Match.new(int(cfg.get("target", 30)), bool(cfg.get("flor", false)))
	_stats_recorded = false
	viewer = 0
	revealed = not _is_pvp()
	if overlay:
		overlay.queue_free()
		overlay = null
	m.start_match()
	_refresh()
	_queue_events()


func _is_pvp() -> bool:
	return cfg.get("mode", "ai") == "pvp"


func _is_human(p: int) -> bool:
	return ais[p] == null


# ================================================================== construcción

func _build() -> void:
	scenery = Scenery.new()
	add_child(scenery)
	UI.full_rect(scenery)
	layer = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	UI.full_rect(layer)

	portrait_top = Portrait.new()
	portrait_bottom = Portrait.new()
	add_child(portrait_top)
	add_child(portrait_bottom)
	name_top = UI.label("", 18)
	name_bottom = UI.label("", 18)
	for l in [name_top, name_bottom]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
	mano_tag = UI.label("MANO", 14, Color(1, 0.85, 0.3))
	add_child(mano_tag)
	bubble_top = _make_bubble()
	bubble_bottom = _make_bubble()

	scoreboard = ScoreBoard.new()
	scoreboard.target = int(cfg.get("target", 30))
	scoreboard.names = names.duplicate()
	scoreboard.colors = [Chars.get_data(chars[0])["color"], Chars.get_data(chars[1])["color"]]
	add_child(scoreboard)

	stake_label = UI.label("", 15, Color(1, 0.85, 0.5), 4)
	stake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(stake_label)

	buttons_box = VBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 6)
	add_child(buttons_box)

	status_label = UI.label("", 20, Color(1, 0.97, 0.85), 6)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

	hint_label = UI.label("", 17, Color(0.7, 1, 0.75), 5)
	add_child(hint_label)

	banner = UI.title("", 66)
	banner.visible = false
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)

	var menu_btn := UI.button("Menú", UI.GRAY, 16)
	menu_btn.name = "MenuButton"
	menu_btn.pressed.connect(_show_pause)
	add_child(menu_btn)
	_layout()


func _make_bubble() -> PanelContainer:
	var b := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.98, 0.92)
	sb.set_corner_radius_all(16)
	sb.border_color = Color(0.2, 0.1, 0.05)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 250
	l.add_theme_color_override("font_color", Color(0.15, 0.08, 0.05))
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_font_size_override("font_size", 18)
	b.add_child(l)
	b.visible = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(b)
	return b


# ================================================================== layout

func _area() -> Dictionary:
	var w := size.x
	var h := size.y
	var left := 205.0
	var right := w - 215.0
	return {"w": w, "h": h, "cx": (left + right) * 0.5, "right": right}


func _hand_card_size() -> Vector2:
	return Vector2(118, 177)


func _table_card_size() -> Vector2:
	return Vector2(88, 132)


func _slot_pos(baza: int, seat_bottom: bool) -> Vector2:
	var a := _area()
	var cs := _table_card_size()
	var x: float = a["cx"] + (baza - 1) * (cs.x + 18) - cs.x * 0.5
	var y := 122.0 if not seat_bottom else 122.0 + cs.y * 0.72
	return Vector2(x, y)


func _bottom_hand_pos(i: int, n: int) -> Vector2:
	var a := _area()
	var cs := _hand_card_size()
	var gap := cs.x + 12
	var x0: float = a["cx"] - (n - 1) * gap * 0.5 - cs.x * 0.5
	return Vector2(x0 + i * gap, a["h"] - cs.y - 12)


func _top_hand_pos(i: int, n: int) -> Vector2:
	var a := _area()
	var cs := Vector2(66, 99)
	var gap := 46.0
	var x0: float = a["cx"] - (n - 1) * gap * 0.5 - cs.x * 0.5
	return Vector2(x0 + i * gap, 14)


func _layout() -> void:
	if scoreboard == null:
		return
	var a := _area()
	var w: float = a["w"]
	var h: float = a["h"]
	var ps := 165.0
	portrait_top.position = Vector2(18, 12)
	portrait_top.size = Vector2(ps, ps)
	name_top.position = Vector2(8, 12 + ps)
	name_top.size = Vector2(ps + 20, 24)
	portrait_bottom.position = Vector2(18, h - ps - 38)
	portrait_bottom.size = Vector2(ps, ps)
	name_bottom.position = Vector2(8, h - 38)
	name_bottom.size = Vector2(ps + 20, 24)
	bubble_top.position = Vector2(190, 28)
	bubble_bottom.position = Vector2(190, h - 330)
	hint_label.position = Vector2(14, h - ps - 74)
	var sb_h := 330.0 if scoreboard.target == 30 else 210.0
	scoreboard.position = Vector2(w - 200, 58)
	scoreboard.size = Vector2(186, sb_h)
	stake_label.position = Vector2(w - 205, 62 + sb_h)
	stake_label.size = Vector2(196, 22)
	buttons_box.position = Vector2(w - 208, 92 + sb_h)
	buttons_box.size = Vector2(196, h - 100 - sb_h)
	var mb := get_node_or_null("MenuButton")
	if mb:
		mb.position = Vector2(w - 98, 10)
	var cs := _table_card_size()
	status_label.position = Vector2(a["cx"] - 300, 122 + cs.y * 1.72 + 4)
	status_label.size = Vector2(600, 30)
	banner.position = Vector2(0, h * 0.3)
	banner.size = Vector2(w, 100)
	banner.pivot_offset = Vector2(w * 0.5, 50)
	if m and not busy:
		_refresh()


# ================================================================== refresco

func _seat_bottom(p: int) -> bool:
	return p == viewer


func _portrait_of(p: int) -> Control:
	return portrait_bottom if _seat_bottom(p) else portrait_top


func _bubble_of(p: int) -> PanelContainer:
	return bubble_bottom if _seat_bottom(p) else bubble_top


func _refresh() -> void:
	var other := 1 - viewer
	portrait_bottom.character = chars[viewer]
	portrait_top.character = chars[other]
	name_bottom.text = names[viewer]
	name_top.text = names[other]
	mano_tag.visible = m.phase != Match.Phase.MATCH_OVER
	var mano_p: Control = _portrait_of(m.mano)
	mano_tag.position = mano_p.position + Vector2(mano_p.size.x - 34, 2)
	scoreboard.set_scores(m.scores)
	var stake := "Mano en juego: %d punto%s" % [m.truco_level, "" if m.truco_level == 1 else "s"]
	stake_label.text = stake

	for c in bottom_cards + top_cards + played_cards:
		c.queue_free()
	bottom_cards = []
	top_cards = []
	played_cards = []
	var hints: bool = cfg.get("hints", true)

	var mine: Array = m.hands[viewer]
	for i in mine.size():
		var cv := _new_card(mine[i], revealed, _bottom_hand_pos(i, mine.size()), _hand_card_size())
		cv.show_hint = hints and revealed
		cv.pressed.connect(_on_card_pressed)
		bottom_cards.append(cv)
	var theirs: Array = m.hands[other]
	for i in theirs.size():
		top_cards.append(_new_card(theirs[i], false, _top_hand_pos(i, theirs.size()), Vector2(66, 99)))
	for bi in m.bazas.size():
		var b: Dictionary = m.bazas[bi]
		for p in 2:
			var c: int = b["cards"][p]
			if c == -1:
				continue
			var cv2 := _new_card(c, true, _slot_pos(bi, _seat_bottom(p)), _table_card_size())
			cv2.show_hint = hints
			var wnr: int = b["winner"]
			cv2.glow = wnr == p
			cv2.dimmed = wnr != -1 and wnr != p and wnr != Cards.PARDA
			played_cards.append(cv2)
	# Las cartas del jugador de abajo se dibujan encima (como en la mesa).
	for cv3 in played_cards:
		if cv3.position.y > 130.0:
			layer.move_child(cv3, -1)

	hint_label.text = ""
	if hints and revealed and _is_human(viewer):
		var env := Cards.envido_points(m.dealt[viewer])
		hint_label.text = "Tu envido: %d" % env
		if m.flor_enabled and Cards.has_flor(m.dealt[viewer]):
			hint_label.text += "  ·  ¡Tenés FLOR!"


func _new_card(c: int, face: bool, pos: Vector2, sz: Vector2) -> Control:
	var cv := CardView.new()
	cv.setup(c, face)
	cv.position = pos
	cv.size = sz
	layer.add_child(cv)
	return cv


# ================================================================== flujo

func _apply(p: int, action: Dictionary) -> void:
	if not m.apply(p, action):
		push_warning("Acción ilegal ignorada: %s" % str(action))
		return
	_queue_events()


func _queue_events() -> void:
	queue.append_array(m.pop_events())
	if not busy:
		_run_queue()


func _run_queue() -> void:
	busy = true
	_set_human_input(false)
	while not queue.is_empty():
		var ev: Dictionary = queue.pop_front()
		await _show_event(ev)
	busy = false
	_refresh()
	_next_step()


func _next_step() -> void:
	if m.is_over():
		_show_match_end()
		return
	if m.phase == Match.Phase.HAND_OVER:
		_show_hand_over()
		return
	var a: int = m.actor
	if not _is_human(a):
		status_label.text = "%s está pensando…" % names[a]
		await _wait(rng.randf_range(0.55, 1.1))
		var act: Dictionary = ais[a].choose(m.get_view(a))
		_apply(a, act)
		return
	if _is_pvp() and (a != viewer or not revealed):
		_show_handoff(a)
		return
	_enable_human(a)


func _wait(seconds: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = maxf(0.01, seconds)
	add_child(t)
	t.start()
	await t.timeout
	t.queue_free()


# ================================================================== entrada humana

func _set_human_input(on: bool) -> void:
	human_turn = on
	for c in buttons_box.get_children():
		c.queue_free()
	for cv in bottom_cards:
		cv.selectable = false


func _enable_human(p: int) -> void:
	_set_human_input(false)
	human_turn = true
	var legal: Array = m.legal_actions(p)
	var can_play := false
	for a in legal:
		if a["type"] == "play":
			can_play = true
			continue
		_add_action_button(a["type"])
	for cv in bottom_cards:
		cv.selectable = can_play
	var opp := 1 - p
	var who: String = "" if not _is_pvp() else names[p] + ": "
	match m.phase:
		Match.Phase.PLAY:
			if m.must_sing_flor(p):
				status_label.text = who + "¡Tenés flor! Tenés que cantarla."
			else:
				status_label.text = who + "Te toca: tirá una carta o cantá."
		Match.Phase.RESPOND_TRUCO:
			if m.must_sing_flor(p):
				status_label.text = who + "Primero cantá tu flor."
			else:
				var lvl: int = m.pending_truco["level"]
				status_label.text = who + "%s cantó %s. ¿Querés?" % [names[opp], CALL_NAMES[Match.TRUCO_CALL_NAMES[lvl]]]
		Match.Phase.RESPOND_ENVIDO:
			if m.must_sing_flor(p):
				status_label.text = who + "¡Tenés flor! Cantala (anula el envido)."
			else:
				status_label.text = who + "%s cantó %s (en juego: %d). ¿Querés?" % [names[opp], CALL_NAMES[m.envido_chain.back()], m.envido_quiero_points()]
		Match.Phase.RESPOND_FLOR:
			status_label.text = who + "%s cantó flor y vos también tenés." % names[opp]


func _add_action_button(t: String) -> void:
	var text := ""
	var col := UI.GRAY
	match t:
		"truco":
			var lvl: int = m.truco_level + 1 if m.phase == Match.Phase.PLAY else int(m.pending_truco["level"]) + 1
			text = {2: "TRUCO", 3: "QUIERO RETRUCO", 4: "QUIERO VALE 4"}[lvl]
			col = UI.RED
		"envido": text = "ENVIDO"; col = UI.BLUE
		"real_envido": text = "REAL ENVIDO"; col = UI.BLUE
		"falta_envido": text = "FALTA ENVIDO"; col = UI.BLUE.darkened(0.2)
		"flor": text = "¡FLOR!"; col = UI.PURPLE
		"contraflor": text = "CONTRAFLOR"; col = UI.PURPLE
		"achico": text = "CON FLOR ME ACHICO"; col = UI.GRAY
		"quiero": text = "QUIERO"; col = UI.GREEN
		"no_quiero": text = "NO QUIERO"; col = Color(0.4, 0.3, 0.28)
		"mazo": text = "IRSE AL MAZO"; col = Color(0.25, 0.2, 0.18)
	var b := UI.button(text, col, 17, Vector2(196, 44))
	b.pressed.connect(func(): _on_action(t))
	buttons_box.add_child(b)


func _on_action(t: String) -> void:
	if busy or not human_turn:
		return
	var p: int = m.actor
	_set_human_input(false)
	_apply(p, {"type": t})


func _on_card_pressed(c: int) -> void:
	if busy or not human_turn:
		return
	var p: int = m.actor
	if p != viewer or not m.is_legal(p, {"type": "play", "card": c}):
		return
	_set_human_input(false)
	_apply(p, {"type": "play", "card": c})


# ================================================================== eventos

func _line(p: int, key: String) -> String:
	return Chars.line(chars[p], key, chars[1 - p], rng)


func _say(p: int, text: String, seconds: float = 2.4) -> void:
	if text == "":
		return
	var b := _bubble_of(p)
	var l: Label = b.get_child(0)
	l.text = text
	b.visible = true
	b.modulate.a = 0.0
	create_tween().tween_property(b, "modulate:a", 1.0, 0.12)
	_portrait_of(p).talk(minf(seconds, 1.4))
	var id: int = _bubble_ids.get(b, 0) + 1
	_bubble_ids[b] = id
	await _wait(seconds)
	if _bubble_ids.get(b, 0) == id:
		b.visible = false


func _show_banner(text: String, color: Color = Color(1, 0.82, 0.3), seconds: float = 1.1) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.modulate.a = 1.0
	banner.scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(seconds)
	t.tween_property(banner, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): banner.visible = false)


func _shake_screen(strength: float = 12.0) -> void:
	var t := create_tween()
	for i in 8:
		var k := 1.0 - i / 8.0
		t.tween_property(self, "position", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	t.tween_property(self, "position", Vector2.ZERO, 0.04)


func _set_expressions(winner: int, happy: String = "happy", sad: String = "sad") -> void:
	_portrait_of(winner).expression = happy
	_portrait_of(1 - winner).expression = sad


func _human_won(p: int) -> bool:
	return not _is_pvp() and p == 0


func _show_event(ev: Dictionary) -> void:
	match ev["type"]:
		"deal":
			await _ev_deal(ev)
		"play":
			await _ev_play(ev)
		"baza":
			_refresh()
			var w: int = ev["winner"]
			if w == Cards.PARDA:
				_show_banner("¡PARDA!", Color(0.9, 0.9, 1.0), 0.5)
				Audio.play("card", 0.8)
				await _wait(0.8)
			else:
				Audio.play("win_baza", 1.0 if w == viewer else 0.85)
				if rng.randf() < 0.35:
					_say(w, _line(w, "win_baza"), 1.4)
				await _wait(0.5)
		"call":
			await _ev_call(ev)
		"response":
			var p: int = ev["player"]
			var r: String = ev["response"]
			_say(p, _line(p, r), 1.8)
			Audio.play("quiero" if r == "quiero" else "no_quiero")
			if r == "quiero":
				_portrait_of(p).bounce()
			await _wait(1.0)
		"envido_result":
			await _ev_envido_result(ev)
		"flor_result":
			var w2: int = ev["winner"]
			var txt := "FLOR: +%d para %s" % [ev["awarded"], names[w2]]
			if ev["mode"] == "contraflor":
				txt = "Contraflor: %s %d – %s %d · +6 %s" % [names[0], ev["points"][0], names[1], ev["points"][1], names[w2]]
			_show_banner(txt, Color(1, 0.6, 0.9), 1.6)
			Audio.play("win_hand")
			if _human_won(w2):
				Save.add("flores")
			await _wait(2.0)
		"score":
			scoreboard.set_scores(ev["scores"])
			await _wait(0.25)
		"mazo":
			var pm: int = ev["player"]
			_say(pm, _line(pm, "mazo"), 1.8)
			Audio.play("no_quiero")
			await _wait(1.0)
		"hand_end":
			var w3: int = ev["winner"]
			_refresh()
			_set_expressions(w3)
			_portrait_of(w3).celebrate()
			_say(w3, _line(w3, "win_hand"), 2.2)
			if not _is_pvp():
				Audio.play("win_hand" if w3 == 0 else "lose_hand")
				Save.add("hands_won" if w3 == 0 else "hands_lost")
				if chars[1 - w3] == "rex":
					_portrait_of(1 - w3).expression = "angry"
					_portrait_of(1 - w3).shake(8.0, 0.4)
			else:
				Audio.play("win_hand")
			await _wait(1.6)
		"match_end":
			pass


func _ev_deal(ev: Dictionary) -> void:
	portrait_top.expression = "normal"
	portrait_bottom.expression = "normal"
	if _is_pvp():
		revealed = false
	_refresh()
	status_label.text = "Mano %d · es mano %s" % [int(ev["hand_number"]) + 1, names[ev["mano"]]]
	var a := _area()
	var deck := Vector2(a["right"] - 80, a["h"] * 0.42)
	var all: Array = []
	for i in 3:
		if i < top_cards.size():
			all.append(top_cards[i])
		if i < bottom_cards.size():
			all.append(bottom_cards[i])
	for cv in all:
		if not is_instance_valid(cv):
			continue
		var target_pos: Vector2 = cv.position
		cv.position = deck
		cv.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(cv, "modulate:a", 1.0, 0.05)
		t.parallel().tween_property(cv, "position", target_pos, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		Audio.play("deal", rng.randf_range(0.9, 1.15))
		await _wait(0.09)
	await _wait(0.35)


func _ev_play(ev: Dictionary) -> void:
	var p: int = ev["player"]
	var c: int = ev["card"]
	var from_pos: Vector2
	var from_size: Vector2
	var src: Control = null
	if _seat_bottom(p):
		for cv in bottom_cards:
			if cv.card == c:
				src = cv
		from_size = _hand_card_size()
	else:
		if not top_cards.is_empty():
			src = top_cards.back()
		from_size = Vector2(66, 99)
	if src:
		from_pos = src.position
		src.visible = false
	else:
		from_pos = Vector2(_area()["cx"], 0)
	var fly := CardView.new()
	fly.setup(c, true)
	fly.show_hint = cfg.get("hints", true)
	fly.position = from_pos
	fly.size = from_size
	fly.rotation = rng.randf_range(-0.25, 0.25)
	layer.add_child(fly)
	var to: Vector2 = _slot_pos(ev["baza"], _seat_bottom(p))
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fly, "position", to, 0.26).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(fly, "size", _table_card_size(), 0.26)
	t.tween_property(fly, "rotation", 0.0, 0.26)
	Audio.play("card", rng.randf_range(0.9, 1.1))
	await t.finished
	fly.queue_free()
	_refresh()
	await _wait(0.12)


func _ev_call(ev: Dictionary) -> void:
	var p: int = ev["player"]
	var call: String = ev["call"]
	var big := call == "vale_cuatro" or call == "falta_envido"
	var col := Color(1, 0.45, 0.3) if call in ["truco", "retruco", "vale_cuatro"] else Color(0.5, 0.8, 1.0)
	if call in ["flor", "contraflor"]:
		col = Color(1, 0.6, 0.9)
	_show_banner(CALL_TEXT.get(call, call.to_upper()), col, 1.0)
	_say(p, _line(p, call), 2.2)
	var por := _portrait_of(p)
	por.expression = "angry" if chars[p] == "rex" and big else ("smug" if chars[p] == "yanina" else "happy")
	por.bounce()
	if big:
		Audio.play("call_big")
		_shake_screen(14.0)
		if chars[p] == "rex":
			await _wait(0.3)
			Audio.play("bang")
			_shake_screen(18.0)
	elif call in ["envido", "real_envido", "flor", "contraflor"]:
		Audio.play("envido")
		Audio.play("call", 1.15, -4.0)
	else:
		Audio.play("call")
	if _human_won(p) and call in ["truco", "retruco", "vale_cuatro"]:
		Save.add("trucos_called")
	await _wait(1.5 if big else 1.25)
	# Al T-Rex no le gusta que le canten falta envido.
	if call == "falta_envido" and chars[1 - p] == "rex":
		var q := 1 - p
		_portrait_of(q).expression = "angry"
		_portrait_of(q).shake(14.0, 0.8)
		Audio.play("roar")
		_say(q, _line(q, "falta_received"), 2.2)
		_shake_screen(10.0)
		await _wait(1.6)
	por.expression = "normal"


func _ev_envido_result(ev: Dictionary) -> void:
	var w: int = ev["winner"]
	var award: int = ev["awarded"]
	if ev.get("refused", false):
		_show_banner("Envido no querido: +%d %s" % [award, names[w]], Color(0.6, 0.85, 1.0), 1.2)
		await _wait(1.4)
		return
	var pts: Array = ev["points"]
	var first: int = m.mano
	_say(first, "Tengo %d." % pts[first], 1.6)
	await _wait(0.8)
	var second := 1 - first
	if second == w:
		_say(second, "%d son mejores." % pts[second], 2.0)
	else:
		_say(second, _line(second, "envido_lose") + " (%d)" % pts[second], 2.0)
	await _wait(1.0)
	_show_banner("%s gana el envido: +%d" % [names[w], award], Color(0.5, 0.85, 1.0), 1.3)
	_set_expressions(w, "happy", "sad" if chars[1 - w] != "rex" else "angry")
	Audio.play("win_hand" if not _is_pvp() and w == 0 or _is_pvp() else "no_quiero")
	if _human_won(w):
		Save.add("envidos_won")
	await _wait(1.6)
	_say(w, _line(w, "envido_win"), 1.6)
	portrait_top.expression = "normal"
	portrait_bottom.expression = "normal"


# ================================================================== overlays

func _make_overlay(dark: float = 0.55) -> VBoxContainer:
	if overlay:
		overlay.queue_free()
	overlay = Control.new()
	add_child(overlay)
	UI.full_rect(overlay)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, dark)
	overlay.add_child(bg)
	UI.full_rect(bg)
	var center := CenterContainer.new()
	overlay.add_child(center)
	UI.full_rect(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	return v


func _close_overlay() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null


func _reason_text(r: String) -> String:
	match r:
		"envido": return "Envido"
		"envido_no_querido": return "Envido no querido"
		"flor", "contraflor": return "Flor"
		"truco": return "Truco (mano ganada)"
		"truco_no_querido": return "Truco no querido"
		"mazo": return "Se fue al mazo"
		"mano": return "Mano ganada"
	return r


func _show_hand_over() -> void:
	status_label.text = ""
	var v := _make_overlay(0.35)
	var w: int = m.hand_winner
	var t := UI.title("%s %s la mano" % [names[w], "ganaste" if _human_won(w) else "ganó"], 34)
	if _human_won(w):
		t.text = "¡Ganaste la mano!"
	v.add_child(t)
	for entry in m.hand_log:
		var l := UI.label("%s: +%d %s" % [_reason_text(entry["reason"]), entry["points"], names[entry["player"]]], 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var sc := UI.label("%s %d  ·  %s %d   (a %d)" % [names[0], m.scores[0], names[1], m.scores[1], m.target], 22, UI.GOLD)
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sc)
	var b := UI.button("SIGUIENTE MANO", UI.GREEN, 22, Vector2(0, 54))
	b.pressed.connect(func():
		_close_overlay()
		m.next_hand()
		_queue_events())
	v.add_child(b)
	b.grab_focus()


func _show_match_end() -> void:
	status_label.text = ""
	var w: int = m.match_winner
	if not _stats_recorded and not _is_pvp():
		_stats_recorded = true
		Save.record_match(w == 0, chars[1])
	Audio.play("win_match" if (_is_pvp() or w == 0) else "lose_hand")
	_set_expressions(w)
	_portrait_of(w).celebrate()
	_say(w, _line(w, "win_match"), 3.5)
	_say(1 - w, _line(1 - w, "lose_match"), 3.5)
	var v := _make_overlay(0.5)
	var title := "¡GANASTE LA PARTIDA!" if _human_won(w) else "Ganó %s" % names[w]
	if _is_pvp():
		title = "¡Ganó %s!" % names[w]
	v.add_child(UI.title(title, 42))
	var por := Portrait.new()
	por.character = chars[w]
	por.expression = "happy"
	por.custom_minimum_size = Vector2(150, 150)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(por)
	por.celebrate()
	var sc := UI.label("%s %d  ·  %s %d" % [names[0], m.scores[0], names[1], m.scores[1]], 24, UI.GOLD)
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sc)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	var again := UI.button("REVANCHA", UI.RED, 22, Vector2(200, 52))
	again.pressed.connect(_new_match)
	hb.add_child(again)
	var menu := UI.button("MENÚ", UI.GRAY, 22, Vector2(160, 52))
	menu.pressed.connect(func(): main.show_menu())
	hb.add_child(menu)
	v.add_child(hb)


func _show_handoff(p: int) -> void:
	revealed = false
	_refresh()
	status_label.text = ""
	var v := _make_overlay(0.92)
	v.add_child(UI.title("Turno de %s" % names[p], 40))
	var por := Portrait.new()
	por.character = chars[p]
	por.custom_minimum_size = Vector2(150, 150)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(por)
	var l := UI.label("Pasale el dispositivo a %s.\nQue el otro no mire las cartas." % names[p], 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var b := UI.button("VER MIS CARTAS", UI.GREEN, 22, Vector2(0, 54))
	b.pressed.connect(func():
		_close_overlay()
		viewer = p
		revealed = true
		_refresh()
		_enable_human(p))
	v.add_child(b)


func _show_pause() -> void:
	if overlay:
		return
	var v := _make_overlay(0.6)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	v.add_child(UI.title("PAUSA", 40))
	var resume := UI.button("SEGUIR JUGANDO", UI.GREEN, 20, Vector2(0, 50))
	resume.pressed.connect(func():
		get_tree().paused = false
		_close_overlay())
	v.add_child(resume)
	var music := UI.button("Música: " + ("Sí" if Save.settings["music"] else "No"), UI.GRAY, 18)
	music.pressed.connect(func():
		Audio.set_music_enabled(not Save.settings["music"])
		music.text = "Música: " + ("Sí" if Save.settings["music"] else "No"))
	v.add_child(music)
	var sfx := UI.button("Efectos: " + ("Sí" if Save.settings["sfx"] else "No"), UI.GRAY, 18)
	sfx.pressed.connect(func():
		Save.settings["sfx"] = not Save.settings["sfx"]
		Save.save()
		sfx.text = "Efectos: " + ("Sí" if Save.settings["sfx"] else "No"))
	v.add_child(sfx)
	var restart := UI.button("Reiniciar partida", UI.BLUE, 18)
	restart.pressed.connect(func():
		get_tree().paused = false
		main.start_game(cfg))
	v.add_child(restart)
	var quit := UI.button("Salir al menú", UI.RED, 18)
	quit.pressed.connect(func():
		get_tree().paused = false
		main.show_menu())
	v.add_child(quit)
