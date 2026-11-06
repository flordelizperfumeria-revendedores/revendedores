extends RefCounted
## Inteligencia artificial del truco.
##
## Decide solo con la "vista" del jugador (get_view), nunca mira las cartas
## ocultas del rival. Estima la chance de ganar la mano con Monte Carlo:
## reparte al rival cartas posibles al azar (de las que no vio) y simula.
##
## Personalidad (0..1):
##   aggression  -> cuánto canta truco y sube
##   bluff       -> cuánto miente (canta sin cartas)
##   envido_bold -> cuánto se anima con el envido
##   chaos       -> cuánto hace jugadas impredecibles
## Dificultad: 0 fácil, 1 normal, 2 difícil.

const Cards = preload("res://scripts/core/cards.gd")
const PARDA := Cards.PARDA

var aggression := 0.5
var bluff := 0.2
var envido_bold := 0.5
var chaos := 0.1
var difficulty := 1
var rng := RandomNumberGenerator.new()


func _init(personality: Dictionary = {}, p_difficulty: int = 1, p_seed: int = -1) -> void:
	aggression = personality.get("aggression", 0.5)
	bluff = personality.get("bluff", 0.2)
	envido_bold = personality.get("envido_bold", 0.5)
	chaos = personality.get("chaos", 0.1)
	difficulty = p_difficulty
	if p_seed >= 0:
		rng.seed = p_seed
	else:
		rng.randomize()


func _samples() -> int:
	return [30, 70, 160][difficulty]


func _noise() -> float:
	return [0.22, 0.08, 0.0][difficulty]


func _env_noise() -> float:
	return [3.0, 1.0, 0.0][difficulty]


static func _has(legal: Array, t: String) -> bool:
	for a in legal:
		if a["type"] == t:
			return true
	return false


func choose(view: Dictionary) -> Dictionary:
	var legal: Array = view["legal"]
	if legal.is_empty():
		return {}
	if legal.size() == 1:
		return legal[0]
	if _has(legal, "flor"):
		return {"type": "flor"}
	if _has(legal, "contraflor"):
		var fp := Cards.flor_points(view["dealt"])
		var thr := 31.0 - envido_bold * 3.0 + rng.randf_range(-_env_noise(), _env_noise())
		return {"type": "contraflor"} if fp >= thr else {"type": "achico"}

	match int(view["phase"]):
		0: return _decide_play(view, legal)          # PLAY
		1: return _decide_truco_response(view, legal) # RESPOND_TRUCO
		2: return _decide_envido_response(view, legal) # RESPOND_ENVIDO
	return legal[0]


# ------------------------------------------------------------------ envido

func _my_envido(view: Dictionary) -> float:
	var pts := float(Cards.envido_points(view["dealt"]))
	pts += rng.randf_range(-_env_noise(), _env_noise())
	if view["mano"] == view["me"]:
		pts += 1.0   # la mano gana los empates
	return pts


func _envido_call(view: Dictionary, legal: Array) -> String:
	if not _has(legal, "envido"):
		return ""
	var me: int = view["me"]
	var opp := 1 - me
	var eff := _my_envido(view)
	var opp_close: bool = view["target"] - view["scores"][opp] <= 4
	if eff >= 33.0 - envido_bold * 2.0 or (opp_close and eff >= 29.0):
		return "falta_envido"
	if eff >= 30.5 - envido_bold * 2.0:
		return "real_envido" if rng.randf() < 0.5 + envido_bold * 0.3 else "envido"
	if eff >= 27.0 - envido_bold * 3.0:
		return "envido"
	if rng.randf() < bluff * 0.15:
		return "envido"   # mentira
	return ""


func _decide_envido_response(view: Dictionary, legal: Array) -> Dictionary:
	var me: int = view["me"]
	var opp := 1 - me
	var eff := _my_envido(view)
	var quiero_pts: int = view["envido_quiero_points"]
	var refused_pts: int = view["envido_refused_points"]
	var chain: Array = view["envido_chain"]
	var thr := 24.0 + minf(quiero_pts, 6.0)
	if chain.has("falta_envido"):
		thr = 30.0
	thr -= envido_bold * 2.0
	# Si no querer le da la partida al rival, hay que querer.
	if view["scores"][opp] + refused_pts >= view["target"]:
		return {"type": "quiero"}
	if eff >= thr + 4.0:
		if _has(legal, "falta_envido") and (eff >= 32.5 or view["target"] - view["scores"][me] <= quiero_pts + 3):
			return {"type": "falta_envido"}
		if _has(legal, "real_envido") and rng.randf() < 0.6:
			return {"type": "real_envido"}
		return {"type": "quiero"}
	if eff >= thr:
		return {"type": "quiero"}
	if rng.randf() < chaos * 0.15:
		return {"type": "quiero"}
	return {"type": "no_quiero"}


# ------------------------------------------------------------------ truco

func _decide_truco_response(view: Dictionary, legal: Array) -> Dictionary:
	var me: int = view["me"]
	var opp := 1 - me
	# El envido está primero.
	var ec := _envido_call(view, legal)
	if ec != "":
		return {"type": ec}
	var p := estimate_win(view)
	var level: int = view["pending_truco"]["level"]
	if view["scores"][opp] + view["truco_level"] >= view["target"]:
		return {"type": "quiero"}  # no querer = perder la partida
	var accept_thr := 0.47 - aggression * 0.15 + (level - 2) * 0.05
	var raise_thr := 0.80 - aggression * 0.12
	if _has(legal, "truco") and (p >= raise_thr or rng.randf() < bluff * 0.08):
		return {"type": "truco"}
	if p >= accept_thr:
		return {"type": "quiero"}
	if rng.randf() < chaos * 0.2:
		return {"type": "quiero"}
	return {"type": "no_quiero"}


# ------------------------------------------------------------------ jugar

func _decide_play(view: Dictionary, legal: Array) -> Dictionary:
	var ec := _envido_call(view, legal)
	if ec != "" and rng.randf() < 0.9:
		return {"type": ec}
	if _has(legal, "truco"):
		var p := estimate_win(view)
		var thr: float = 0.72 - aggression * 0.2 + (int(view["truco_level"]) - 1) * 0.06
		# Cantar en la primera baza revela; los cautos esperan.
		if view["bazas"].size() == 1 and rng.randf() > aggression:
			thr += 0.1
		if p >= thr or (p > 0.25 and rng.randf() < bluff * 0.1):
			return {"type": "truco"}
	return {"type": "play", "card": choose_card(view)}


func choose_card(view: Dictionary) -> int:
	var me: int = view["me"]
	var opp := 1 - me
	var hand: Array = view["hand"].duplicate()
	hand.sort_custom(func(a, b): return Cards.rank(a) < Cards.rank(b))
	if difficulty == 0 and rng.randf() < 0.2:
		return hand[rng.randi_range(0, hand.size() - 1)]
	var bazas: Array = view["bazas"]
	var cur: Dictionary = bazas.back()
	var idx := bazas.size() - 1
	var prev_results: Array = []
	for i in idx:
		prev_results.append(bazas[i]["winner"])
	var opp_card: int = cur["cards"][opp]

	if opp_card != -1:
		# Respondo a una carta.
		var r := Cards.rank(opp_card)
		var lowest_win := -1
		var tie := -1
		for c in hand:
			if Cards.rank(c) > r and lowest_win == -1:
				lowest_win = c
			if Cards.rank(c) == r and tie == -1:
				tie = c
		if idx == 0:
			if lowest_win != -1:
				return lowest_win
			# Empardar si me queda una carta brava para definir.
			if tie != -1 and Cards.rank(hand.back()) >= 10 and hand.back() != tie:
				return tie
			return hand[0]
		var i_won_first: bool = prev_results.size() > 0 and prev_results[0] == me
		if i_won_first:
			if tie != -1:
				return tie if lowest_win == -1 or Cards.rank(lowest_win) > Cards.rank(tie) else lowest_win
			return lowest_win if lowest_win != -1 else hand[0]
		if lowest_win != -1:
			return lowest_win
		if tie != -1 and prev_results.size() > 0 and prev_results[0] == PARDA:
			return tie
		return hand[0]

	# Abro la baza.
	if hand.size() == 1:
		return hand[0]
	if idx == 0:
		if rng.randf() < chaos * 0.4:
			return hand[rng.randi_range(0, hand.size() - 1)]
		# Con buena mano, abro con la del medio; si no, con la más baja.
		if hand.size() == 3 and Cards.rank(hand[2]) >= 10:
			return hand[1]
		return hand[0]
	var won_first: bool = prev_results[0] == me
	var parda_first: bool = prev_results[0] == PARDA
	if parda_first:
		return hand.back()
	if won_first:
		return hand.back() if Cards.rank(hand.back()) >= 10 else hand[0]
	return hand.back()


# ------------------------------------------------------------------ Monte Carlo

## Probabilidad estimada de ganar la mano desde el estado actual.
func estimate_win(view: Dictionary) -> float:
	var me: int = view["me"]
	var opp := 1 - me
	var known := {}
	for c in view["dealt"]:
		known[c] = true
	var opp_played: Array = []
	for b in view["bazas"]:
		for i in 2:
			var c: int = b["cards"][i]
			if c != -1:
				known[c] = true
				if i == opp:
					opp_played.append(c)
	var unknown: Array = []
	for c in Cards.full_deck():
		if not known.has(c):
			unknown.append(c)
	var need := 3 - opp_played.size()
	var opp_env: int = view["envido_revealed"][opp] if difficulty >= 2 else -1
	var n := _samples()
	var wins := 0
	for s in n:
		var pick: Array = []
		for attempt in 15:
			pick = _random_pick(unknown, need)
			if opp_env < 0 or Cards.envido_points(opp_played + pick) == opp_env:
				break
		if simulate(view, view["hand"].duplicate(), pick) == me:
			wins += 1
	var p := float(wins) / float(n)
	p += rng.randf_range(-_noise(), _noise())
	return clampf(p, 0.0, 1.0)


func _random_pick(pool: Array, k: int) -> Array:
	var a := pool.duplicate()
	var out: Array = []
	for i in k:
		var j := rng.randi_range(i, a.size() - 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
		out.append(a[i])
	return out


## Simula el resto de la mano con una política simple para ambos.
static func simulate(view: Dictionary, my_cards: Array, opp_cards: Array) -> int:
	var me: int = view["me"]
	var mano: int = view["mano"]
	var hands := [[], []]
	hands[me] = my_cards
	hands[1 - me] = opp_cards.duplicate()
	var bz: Array = []
	for b in view["bazas"]:
		bz.append([b["cards"][0], b["cards"][1], b["lead"]])
	for guard in 8:
		var cur: Array = bz.back()
		if cur[0] != -1 and cur[1] != -1:
			var results: Array = []
			for x in bz:
				results.append(Cards.baza_result(x[0], x[1]))
			var w := Cards.hand_winner(results, mano)
			if w != -1:
				return w
			var last: int = results.back()
			bz.append([-1, -1, last if last != PARDA else mano])
			continue
		var lead: int = cur[2]
		var who: int = lead if cur[lead] == -1 else 1 - lead
		var h: Array = hands[who]
		if h.is_empty():
			return mano
		var c := _greedy(h, cur[1 - who])
		h.erase(c)
		cur[who] = c
	return mano


static func _greedy(hand: Array, other: int) -> int:
	var best := -1
	var lowest := -1
	var lowest_win := -1
	for c in hand:
		var r := Cards.rank(c)
		if best == -1 or r > Cards.rank(best):
			best = c
		if lowest == -1 or r < Cards.rank(lowest):
			lowest = c
		if other != -1 and r > Cards.rank(other) and (lowest_win == -1 or r < Cards.rank(lowest_win)):
			lowest_win = c
	if other == -1:
		return best
	return lowest_win if lowest_win != -1 else lowest
