extends RefCounted
## Motor de reglas del Truco Argentino para 2 jugadores (0 y 1).
##
## Es lógica pura: no sabe nada de nodos, pantallas ni sonido. La UI (o un
## servidor online en el futuro) le manda acciones con apply() y lee los
## eventos generados con pop_events(). Eso permite testearlo headless y, más
## adelante, correrlo como servidor autoritativo para multijugador.
##
## Acciones (Dictionary con "type"):
##   play (con "card"), truco (canta truco / retruco / vale cuatro),
##   envido, real_envido, falta_envido, flor, contraflor, achico,
##   quiero, no_quiero, mazo

const Cards = preload("res://scripts/core/cards.gd")

enum Phase { PLAY, RESPOND_TRUCO, RESPOND_ENVIDO, RESPOND_FLOR, HAND_OVER, MATCH_OVER }

const PARDA := Cards.PARDA
const ENVIDO_VALUE := {"envido": 2, "real_envido": 3}
const TRUCO_CALL_NAMES := {2: "truco", 3: "retruco", 4: "vale_cuatro"}

var target := 30
var flor_enabled := false
var rng := RandomNumberGenerator.new()

var scores := [0, 0]
var hand_number := 0
var mano := 0
var dealt := [[], []]         # cartas repartidas (para envido/flor)
var hands := [[], []]         # cartas que quedan en la mano
var bazas: Array = []         # [{cards:[c0,c1], lead:p, winner:-1/0/1/PARDA}]
var turn := 0                 # a quién le toca tirar carta
var phase: int = Phase.PLAY
var actor := 0                # quién tiene que decidir ahora (-1 = nadie)

var truco_level := 1          # 1 sin truco, 2 truco, 3 retruco, 4 vale cuatro (querido)
var truco_raise_right := -1   # quién puede subir el truco (-1 = cualquiera)
var pending_truco := {}       # {caller, level} mientras se espera respuesta

var envido_open := true
var envido_chain: Array = []
var envido_caller := -1
var envido_revealed := [-1, -1]

var flor_sung := [false, false]
var flor_caller := -1
var flor_done := false

var _saved_phase: int = Phase.PLAY
var _saved_actor := 0

var hand_winner := -1
var match_winner := -1
var hand_log: Array = []      # resumen de puntos de la mano: [{player, points, reason}]
var events: Array = []


func _init(p_target: int = 30, p_flor: bool = false, p_seed: int = -1) -> void:
	target = p_target
	flor_enabled = p_flor
	if p_seed >= 0:
		rng.seed = p_seed
	else:
		rng.randomize()


# ---------------------------------------------------------------- partida

func start_match(first_mano: int = -1) -> void:
	scores = [0, 0]
	hand_number = 0
	match_winner = -1
	mano = first_mano if first_mano >= 0 else rng.randi_range(0, 1)
	_start_hand()


func next_hand() -> void:
	if phase != Phase.HAND_OVER:
		return
	hand_number += 1
	mano = 1 - mano
	_start_hand()


## Solo para tests / tutorial: reparte manos fijas.
func setup_hand(h0: Array, h1: Array, p_mano: int) -> void:
	mano = p_mano
	_reset_hand_state()
	dealt = [h0.duplicate(), h1.duplicate()]
	hands = [h0.duplicate(), h1.duplicate()]
	_emit({"type": "deal", "mano": mano, "hand_number": hand_number})


func _start_hand() -> void:
	var deck := Cards.full_deck()
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
	var d := [[], []]
	for k in 3:
		d[mano].append(deck.pop_back())
		d[1 - mano].append(deck.pop_back())
	_reset_hand_state()
	dealt = d
	hands = [d[0].duplicate(), d[1].duplicate()]
	_emit({"type": "deal", "mano": mano, "hand_number": hand_number})


func _reset_hand_state() -> void:
	bazas = [_new_baza(mano)]
	turn = mano
	actor = mano
	phase = Phase.PLAY
	truco_level = 1
	truco_raise_right = -1
	pending_truco = {}
	envido_open = true
	envido_chain = []
	envido_caller = -1
	envido_revealed = [-1, -1]
	flor_sung = [false, false]
	flor_caller = -1
	flor_done = false
	hand_winner = -1
	hand_log = []


func _new_baza(lead: int) -> Dictionary:
	return {"cards": [-1, -1], "lead": lead, "winner": -1}


# ---------------------------------------------------------------- consultas

func pop_events() -> Array:
	var e := events
	events = []
	return e


func is_over() -> bool:
	return phase == Phase.MATCH_OVER


func baza_index() -> int:
	return bazas.size() - 1


func has_played_first(p: int) -> bool:
	return bazas[0]["cards"][p] != -1


func falta_points() -> int:
	return target - maxi(scores[0], scores[1])


func envido_quiero_points() -> int:
	if envido_chain.has("falta_envido"):
		return falta_points()
	var t := 0
	for k in envido_chain:
		t += ENVIDO_VALUE[k]
	return t


func envido_refused_points() -> int:
	if envido_chain.size() <= 1:
		return 1
	var t := 0
	for i in envido_chain.size() - 1:
		t += ENVIDO_VALUE[envido_chain[i]]
	return t


func must_sing_flor(p: int) -> bool:
	return flor_enabled and phase != Phase.RESPOND_FLOR and not flor_sung[p] \
		and Cards.has_flor(dealt[p]) and bazas.size() == 1 and not has_played_first(p)


func can_sing_envido(p: int) -> bool:
	if not envido_open or bazas.size() != 1 or has_played_first(p) or actor != p:
		return false
	if flor_enabled and Cards.has_flor(dealt[p]):
		return false
	if phase == Phase.PLAY:
		return truco_level == 1
	if phase == Phase.RESPOND_TRUCO:
		# "El envido está primero": solo como respuesta al primer truco.
		return truco_level == 1 and int(pending_truco["level"]) == 2
	return false


func can_call_truco(p: int) -> bool:
	if phase != Phase.PLAY or actor != p or truco_level >= 4:
		return false
	return truco_raise_right == -1 or truco_raise_right == p


func legal_actions(p: int) -> Array:
	var acts: Array = []
	if p != actor or phase == Phase.HAND_OVER or phase == Phase.MATCH_OVER:
		return acts
	if must_sing_flor(p):
		acts.append({"type": "flor"})
		return acts
	match phase:
		Phase.PLAY:
			for c in hands[p]:
				acts.append({"type": "play", "card": c})
			if can_call_truco(p):
				acts.append({"type": "truco"})
			if can_sing_envido(p):
				acts.append({"type": "envido"})
				acts.append({"type": "real_envido"})
				acts.append({"type": "falta_envido"})
			acts.append({"type": "mazo"})
		Phase.RESPOND_TRUCO:
			acts.append({"type": "quiero"})
			acts.append({"type": "no_quiero"})
			if int(pending_truco["level"]) < 4:
				acts.append({"type": "truco"})
			if can_sing_envido(p):
				acts.append({"type": "envido"})
				acts.append({"type": "real_envido"})
				acts.append({"type": "falta_envido"})
		Phase.RESPOND_ENVIDO:
			acts.append({"type": "quiero"})
			acts.append({"type": "no_quiero"})
			if envido_chain == ["envido"]:
				acts.append({"type": "envido"})
			if not envido_chain.has("real_envido") and not envido_chain.has("falta_envido"):
				acts.append({"type": "real_envido"})
			if not envido_chain.has("falta_envido"):
				acts.append({"type": "falta_envido"})
		Phase.RESPOND_FLOR:
			acts.append({"type": "contraflor"})
			acts.append({"type": "achico"})
	return acts


func is_legal(p: int, action: Dictionary) -> bool:
	for a in legal_actions(p):
		if a["type"] == action.get("type", "") and (a["type"] != "play" or a["card"] == action.get("card", -99)):
			return true
	return false


## Vista de la partida desde los ojos de un jugador (lo que usa la IA).
## No incluye las cartas ocultas del rival.
func get_view(p: int) -> Dictionary:
	var bz: Array = []
	for b in bazas:
		bz.append({"cards": b["cards"].duplicate(), "lead": b["lead"], "winner": b["winner"]})
	return {
		"me": p, "hand": hands[p].duplicate(), "dealt": dealt[p].duplicate(),
		"bazas": bz, "scores": scores.duplicate(), "target": target, "mano": mano,
		"phase": phase, "truco_level": truco_level, "pending_truco": pending_truco.duplicate(),
		"truco_raise_right": truco_raise_right, "envido_chain": envido_chain.duplicate(),
		"envido_open": envido_open, "envido_revealed": envido_revealed.duplicate(),
		"envido_quiero_points": envido_quiero_points() if not envido_chain.is_empty() else 0,
		"envido_refused_points": envido_refused_points() if not envido_chain.is_empty() else 0,
		"falta_points": falta_points(), "flor_enabled": flor_enabled,
		"flor_sung": flor_sung.duplicate(), "legal": legal_actions(p),
	}


# ---------------------------------------------------------------- acciones

func apply(p: int, action: Dictionary) -> bool:
	if not is_legal(p, action):
		return false
	match action["type"]:
		"play": _do_play(p, action["card"])
		"truco": _do_truco(p)
		"envido", "real_envido", "falta_envido": _do_envido(p, action["type"])
		"flor": _do_flor(p)
		"contraflor": _do_contraflor(p)
		"achico": _do_achico(p)
		"quiero": _do_quiero(p)
		"no_quiero": _do_no_quiero(p)
		"mazo": _do_mazo(p)
	return true


func _do_play(p: int, c: int) -> void:
	hands[p].erase(c)
	var b: Dictionary = bazas.back()
	b["cards"][p] = c
	_emit({"type": "play", "player": p, "card": c, "baza": baza_index()})
	if b["cards"][1 - p] == -1:
		turn = 1 - p
		actor = turn
		return
	b["winner"] = Cards.baza_result(b["cards"][0], b["cards"][1])
	_emit({"type": "baza", "baza": baza_index(), "winner": b["winner"]})
	var results: Array = []
	for bb in bazas:
		results.append(bb["winner"])
	var w := Cards.hand_winner(results, mano)
	if w != -1:
		_end_hand(w, truco_level, "truco" if truco_level > 1 else "mano")
		return
	var lead: int = b["winner"] if b["winner"] != PARDA else mano
	bazas.append(_new_baza(lead))
	turn = lead
	actor = lead


func _do_truco(p: int) -> void:
	var level: int
	if phase == Phase.PLAY:
		level = truco_level + 1
	else:
		# Subir el truco implica querer el anterior.
		truco_level = int(pending_truco["level"])
		level = truco_level + 1
	pending_truco = {"caller": p, "level": level}
	if phase == Phase.PLAY:
		phase = Phase.RESPOND_TRUCO
	actor = 1 - p
	_emit({"type": "call", "player": p, "call": TRUCO_CALL_NAMES[level]})


func _do_envido(p: int, kind: String) -> void:
	if phase == Phase.PLAY or phase == Phase.RESPOND_TRUCO:
		_save_context()
		envido_chain = []
	envido_chain.append(kind)
	envido_caller = p
	phase = Phase.RESPOND_ENVIDO
	actor = 1 - p
	_emit({"type": "call", "player": p, "call": kind})


func _do_flor(p: int) -> void:
	if phase == Phase.PLAY or phase == Phase.RESPOND_TRUCO:
		_save_context()
	var cancelled := not envido_chain.is_empty()
	flor_sung[p] = true
	envido_open = false
	envido_chain = []
	_emit({"type": "call", "player": p, "call": "flor", "cancels_envido": cancelled})
	var q := 1 - p
	if Cards.has_flor(dealt[q]) and not flor_sung[q]:
		flor_caller = p
		phase = Phase.RESPOND_FLOR
		actor = q
		return
	flor_done = true
	_emit({"type": "flor_result", "winner": p, "points": [-1, -1], "awarded": 3, "mode": "flor"})
	_add_points(p, 3, "flor")
	_restore_context()


func _do_contraflor(q: int) -> void:
	_emit({"type": "call", "player": q, "call": "contraflor"})
	flor_sung[q] = true
	flor_done = true
	var pts := [Cards.flor_points(dealt[0]), Cards.flor_points(dealt[1])]
	var w: int = mano if pts[0] == pts[1] else (0 if pts[0] > pts[1] else 1)
	_emit({"type": "flor_result", "winner": w, "points": pts, "awarded": 6, "mode": "contraflor"})
	_add_points(w, 6, "contraflor")
	_restore_context()


func _do_achico(q: int) -> void:
	_emit({"type": "response", "player": q, "response": "achico"})
	flor_sung[q] = true
	flor_done = true
	_emit({"type": "flor_result", "winner": flor_caller, "points": [-1, -1], "awarded": 4, "mode": "achico"})
	_add_points(flor_caller, 4, "flor")
	_restore_context()


func _do_quiero(p: int) -> void:
	_emit({"type": "response", "player": p, "response": "quiero"})
	if phase == Phase.RESPOND_TRUCO:
		truco_level = int(pending_truco["level"])
		truco_raise_right = p
		pending_truco = {}
		phase = Phase.PLAY
		actor = turn
	elif phase == Phase.RESPOND_ENVIDO:
		var pts := [Cards.envido_points(dealt[0]), Cards.envido_points(dealt[1])]
		envido_revealed = pts.duplicate()
		var w: int = mano if pts[0] == pts[1] else (0 if pts[0] > pts[1] else 1)
		var award := envido_quiero_points()
		_emit({"type": "envido_result", "winner": w, "points": pts, "awarded": award,
			"chain": envido_chain.duplicate()})
		envido_open = false
		envido_chain = []
		_add_points(w, award, "envido")
		_restore_context()


func _do_no_quiero(p: int) -> void:
	_emit({"type": "response", "player": p, "response": "no_quiero"})
	if phase == Phase.RESPOND_TRUCO:
		var caller: int = pending_truco["caller"]
		pending_truco = {}
		_end_hand(caller, truco_level, "truco_no_querido")
	elif phase == Phase.RESPOND_ENVIDO:
		var award := envido_refused_points()
		_emit({"type": "envido_result", "winner": envido_caller, "points": [-1, -1],
			"awarded": award, "chain": envido_chain.duplicate(), "refused": true})
		envido_open = false
		envido_chain = []
		_add_points(envido_caller, award, "envido_no_querido")
		_restore_context()


func _do_mazo(p: int) -> void:
	var pts := truco_level
	# Irse al mazo en la primera baza sin que se haya cantado envido: +1 al rival.
	if envido_open and bazas.size() == 1 and not flor_done:
		pts += 1
	_emit({"type": "mazo", "player": p})
	_end_hand(1 - p, pts, "mazo")


# ---------------------------------------------------------------- internos

func _save_context() -> void:
	_saved_phase = phase
	_saved_actor = actor


func _restore_context() -> void:
	if phase == Phase.MATCH_OVER:
		return
	phase = _saved_phase
	actor = _saved_actor


func _end_hand(w: int, pts: int, reason: String) -> void:
	hand_winner = w
	_emit({"type": "hand_end", "winner": w, "points": pts, "reason": reason})
	_add_points(w, pts, reason)
	if phase != Phase.MATCH_OVER:
		phase = Phase.HAND_OVER
		actor = -1


func _add_points(p: int, pts: int, reason: String) -> void:
	if phase == Phase.MATCH_OVER:
		return
	scores[p] += pts
	hand_log.append({"player": p, "points": pts, "reason": reason})
	_emit({"type": "score", "player": p, "points": pts, "reason": reason, "scores": scores.duplicate()})
	if scores[p] >= target:
		match_winner = p
		phase = Phase.MATCH_OVER
		actor = -1
		_emit({"type": "match_end", "winner": p, "scores": scores.duplicate()})


func _emit(e: Dictionary) -> void:
	events.append(e)
