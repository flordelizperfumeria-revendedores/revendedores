extends SceneTree
## Tests de reglas. Ejecutar:
##   godot --headless --path . --script res://tests/run_tests.gd

const Cards = preload("res://scripts/core/cards.gd")
const Match = preload("res://scripts/core/truco_match.gd")
const AI = preload("res://scripts/core/truco_ai.gd")

var failures := 0
var checks := 0


func _init() -> void:
	test_hierarchy()
	test_envido_points()
	test_flor_points()
	test_hand_winner()
	test_simple_hand()
	test_truco_flow()
	test_truco_refused()
	test_envido_flow()
	test_envido_refused_chain()
	test_envido_esta_primero()
	test_envido_not_after_truco_accepted()
	test_falta_envido()
	test_mazo()
	test_flor()
	test_contraflor()
	test_flor_cancels_envido()
	test_raise_rights()
	test_match_end()
	var stress_ok: bool = test_ai_matches()
	check(stress_ok, "el test de estrés terminó sin errores de script")
	print("\n%d verificaciones, %d fallas" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		push_error("FALLA: " + msg)
		print("  FALLA: ", msg)


func C(n: int, s: int) -> int:
	return Cards.make(n, s)


const E := 0
const B := 1
const O := 2
const K := 3  # copa


func test_hierarchy() -> void:
	print("jerarquía")
	var order := [C(1, E), C(1, B), C(7, E), C(7, O), C(3, K), C(2, O), C(1, K), C(12, B), C(11, E), C(10, O), C(7, K), C(6, E), C(5, B), C(4, O)]
	for i in order.size() - 1:
		check(Cards.rank(order[i]) > Cards.rank(order[i + 1]), "%s > %s" % [Cards.card_name(order[i]), Cards.card_name(order[i + 1])])
	check(Cards.rank(C(1, K)) == Cards.rank(C(1, O)), "1 copa == 1 oro")
	check(Cards.rank(C(7, K)) == Cards.rank(C(7, B)), "7 copa == 7 basto")
	check(Cards.rank(C(3, E)) == Cards.rank(C(3, K)), "los 3 empatan")
	check(Cards.full_deck().size() == 40, "mazo de 40")


func test_envido_points() -> void:
	print("envido")
	check(Cards.envido_points([C(7, E), C(6, E), C(1, O)]) == 33, "7+6 de espada = 33")
	check(Cards.envido_points([C(12, O), C(11, O), C(4, B)]) == 20, "dos figuras = 20")
	check(Cards.envido_points([C(12, O), C(5, O), C(4, B)]) == 25, "figura + 5 = 25")
	check(Cards.envido_points([C(7, E), C(6, B), C(1, O)]) == 7, "sin palo: carta más alta")
	check(Cards.envido_points([C(10, E), C(11, B), C(12, O)]) == 0, "tres figuras distintas = 0")
	check(Cards.envido_points([C(7, E), C(6, E), C(5, E)]) == 33, "flor: mejor par = 33")


func test_flor_points() -> void:
	print("flor")
	check(Cards.has_flor([C(7, E), C(6, E), C(5, E)]), "tiene flor")
	check(not Cards.has_flor([C(7, E), C(6, E), C(5, O)]), "no tiene flor")
	check(Cards.flor_points([C(7, E), C(6, E), C(5, E)]) == 38, "flor 38")


func test_hand_winner() -> void:
	print("definición de la mano")
	var P := Cards.PARDA
	check(Cards.hand_winner([0, 0], 1) == 0, "gana 2 bazas")
	check(Cards.hand_winner([0, 1], 1) == -1, "1-1 sin definir")
	check(Cards.hand_winner([0, 1, 1], 0) == 1, "gana 2 de 3")
	check(Cards.hand_winner([P, 1], 0) == 1, "parda primera: define la segunda")
	check(Cards.hand_winner([0, P], 1) == 0, "parda segunda: gana la primera")
	check(Cards.hand_winner([P, P], 0) == -1, "dos pardas: va a la tercera")
	check(Cards.hand_winner([P, P, 1], 0) == 1, "dos pardas, define la tercera")
	check(Cards.hand_winner([P, P, P], 1) == 1, "todo pardo: gana la mano")
	check(Cards.hand_winner([1, 0, P], 0) == 1, "parda en tercera: gana el de la primera")


func _new(target := 30, flor := false) -> Object:
	var m = Match.new(target, flor, 1)
	m.scores = [0, 0]
	return m


func test_simple_hand() -> void:
	print("mano simple")
	var m = _new()
	m.setup_hand([C(1, E), C(4, K), C(5, K)], [C(3, O), C(2, B), C(6, B)], 0)
	check(m.actor == 0, "empieza la mano")
	check(m.apply(0, {"type": "play", "card": C(4, K)}), "juega 4 copa")
	check(not m.apply(0, {"type": "play", "card": C(5, K)}), "no puede jugar dos veces")
	check(m.apply(1, {"type": "play", "card": C(6, B)}), "1 juega 6 basto")
	check(m.bazas[0]["winner"] == 1, "6 le gana al 4")
	check(m.actor == 1, "el ganador abre la siguiente")
	m.apply(1, {"type": "play", "card": C(3, O)})
	m.apply(0, {"type": "play", "card": C(1, E)})
	check(m.actor == 0, "gana 0 la segunda y abre")
	m.apply(0, {"type": "play", "card": C(5, K)})
	m.apply(1, {"type": "play", "card": C(2, B)})
	check(m.phase == Match.Phase.HAND_OVER, "mano terminada")
	check(m.hand_winner == 1, "gana 1 (2 bazas)")
	check(m.scores == [0, 1], "1 punto sin truco")


func test_truco_flow() -> void:
	print("truco / retruco / vale cuatro")
	var m = _new()
	m.setup_hand([C(1, E), C(1, B), C(7, E)], [C(4, K), C(4, O), C(5, B)], 0)
	m.apply(0, {"type": "play", "card": C(7, E)})
	check(m.apply(1, {"type": "truco"}), "1 canta truco")
	check(m.actor == 0 and m.phase == Match.Phase.RESPOND_TRUCO, "0 responde")
	check(m.apply(0, {"type": "truco"}), "0 quiere retruco")
	check(m.truco_level == 2, "retruco implica truco querido")
	check(m.apply(1, {"type": "truco"}), "1 quiere vale cuatro")
	check(m.apply(0, {"type": "quiero"}), "0 quiere")
	check(m.truco_level == 4, "vale cuatro querido")
	check(not m.is_legal(0, {"type": "truco"}) and not m.is_legal(1, {"type": "truco"}), "no se puede subir más")
	check(m.actor == 1, "vuelve el turno a quien debía jugar")
	m.apply(1, {"type": "play", "card": C(4, K)})
	m.apply(0, {"type": "play", "card": C(1, E)})
	m.apply(0, {"type": "play", "card": C(1, B)})
	m.apply(1, {"type": "play", "card": C(4, O)})
	check(m.scores == [4, 0], "vale cuatro = 4 puntos")


func test_truco_refused() -> void:
	print("truco no querido")
	var m = _new()
	m.setup_hand([C(1, E), C(1, B), C(7, E)], [C(4, K), C(4, O), C(5, B)], 0)
	m.apply(0, {"type": "truco"})
	m.apply(1, {"type": "truco"})
	m.apply(0, {"type": "no_quiero"})
	check(m.scores == [0, 2], "retruco no querido = 2 para quien cantó retruco")
	var m2 = _new()
	m2.setup_hand([C(1, E), C(1, B), C(7, E)], [C(4, K), C(4, O), C(5, B)], 0)
	m2.apply(0, {"type": "truco"})
	m2.apply(1, {"type": "no_quiero"})
	check(m2.scores == [1, 0], "truco no querido = 1")


func test_envido_flow() -> void:
	print("envido querido")
	var m = _new()
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	check(m.apply(0, {"type": "envido"}), "canta envido")
	check(m.apply(1, {"type": "envido"}), "envido envido")
	check(not m.is_legal(0, {"type": "envido"}), "no hay tercer envido")
	check(m.apply(0, {"type": "real_envido"}), "real envido")
	check(m.apply(1, {"type": "quiero"}), "quiero")
	check(m.scores == [7, 0], "E+E+R = 7 para 33 vs 29")
	check(m.actor == 0 and m.phase == Match.Phase.PLAY, "vuelve a jugar la mano")
	check(not m.is_legal(0, {"type": "envido"}), "envido cerrado")
	# Empate: gana la mano
	var m2 = _new()
	m2.setup_hand([C(7, E), C(6, E), C(4, K)], [C(7, O), C(6, O), C(1, B)], 1)
	m2.apply(1, {"type": "envido"})
	m2.apply(0, {"type": "quiero"})
	check(m2.scores == [0, 2], "empate 33-33: gana la mano")


func test_envido_refused_chain() -> void:
	print("envido no querido")
	var cases := [
		[["envido"], 1], [["real_envido"], 1], [["falta_envido"], 1],
		[["envido", "envido"], 2], [["envido", "real_envido"], 2],
		[["envido", "envido", "real_envido"], 4], [["envido", "envido", "real_envido", "falta_envido"], 7],
		[["real_envido", "falta_envido"], 3],
	]
	for cs in cases:
		var m = _new()
		m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
		var p := 0
		for k in cs[0]:
			check(m.apply(p, {"type": k}), "cantar %s" % k)
			p = 1 - p
		var caller := 1 - p
		m.apply(p, {"type": "no_quiero"})
		check(m.scores[caller] == cs[1], "%s no querido = %d (dio %d)" % [str(cs[0]), cs[1], m.scores[caller]])


func test_envido_esta_primero() -> void:
	print("el envido está primero")
	var m = _new()
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m.apply(0, {"type": "truco"})
	check(m.is_legal(1, {"type": "envido"}), "puede responder envido al truco")
	m.apply(1, {"type": "envido"})
	m.apply(0, {"type": "quiero"})
	check(m.scores == [2, 0], "envido se resuelve primero")
	check(m.phase == Match.Phase.RESPOND_TRUCO and m.actor == 1, "vuelve a la respuesta del truco")
	check(not m.is_legal(1, {"type": "envido"}), "ya no hay envido")
	m.apply(1, {"type": "quiero"})
	check(m.truco_level == 2 and m.actor == 0, "truco querido, juega la mano")


func test_envido_not_after_truco_accepted() -> void:
	print("sin envido después de querer el truco")
	var m = _new()
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m.apply(0, {"type": "truco"})
	m.apply(1, {"type": "quiero"})
	check(not m.is_legal(0, {"type": "envido"}), "no se puede cantar envido")
	m.apply(0, {"type": "play", "card": C(4, K)})
	check(not m.is_legal(1, {"type": "envido"}), "el pie tampoco")
	var m2 = _new()
	m2.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m2.apply(0, {"type": "play", "card": C(4, K)})
	check(not m2.is_legal(0, {"type": "envido"}), "la mano ya jugó: no canta")
	check(m2.is_legal(1, {"type": "envido"}), "el pie sí puede antes de jugar")
	m2.apply(1, {"type": "play", "card": C(1, B)})
	check(not m2.is_legal(1, {"type": "envido"}), "segunda baza: no hay envido")


func test_falta_envido() -> void:
	print("falta envido")
	var m = _new(30)
	m.scores = [20, 12]
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m.apply(0, {"type": "falta_envido"})
	check(m.envido_quiero_points() == 10, "falta = 30 - 20")
	m.apply(1, {"type": "quiero"})
	check(m.scores[0] == 30 and m.is_over() and m.match_winner == 0, "falta gana la partida")


func test_mazo() -> void:
	print("irse al mazo")
	var m = _new()
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m.apply(0, {"type": "mazo"})
	check(m.scores == [0, 2], "mazo en primera sin envido: 2")
	var m2 = _new()
	m2.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m2.apply(0, {"type": "truco"})
	m2.apply(1, {"type": "quiero"})
	m2.apply(0, {"type": "play", "card": C(4, K)})
	m2.apply(1, {"type": "play", "card": C(1, B)})
	m2.apply(1, {"type": "mazo"})
	check(m2.scores == [2, 0], "mazo con truco querido: 2")


func test_flor() -> void:
	print("flor")
	var m = _new(30, true)
	m.setup_hand([C(7, E), C(6, E), C(4, E)], [C(5, O), C(4, O), C(1, B)], 0)
	var legal: Array = m.legal_actions(0)
	check(legal.size() == 1 and legal[0]["type"] == "flor", "con flor hay que cantarla")
	m.apply(0, {"type": "flor"})
	check(m.scores == [3, 0], "flor = 3")
	check(not m.is_legal(1, {"type": "envido"}) and not m.is_legal(0, {"type": "envido"}), "flor anula envido")
	check(m.actor == 0 and m.phase == Match.Phase.PLAY, "sigue jugando la mano")
	var m2 = _new(30, false)
	m2.setup_hand([C(7, E), C(6, E), C(4, E)], [C(5, O), C(4, O), C(1, B)], 0)
	check(m2.is_legal(0, {"type": "envido"}), "sin flor habilitada: envido normal")


func test_contraflor() -> void:
	print("contraflor / me achico")
	var m = _new(30, true)
	m.setup_hand([C(7, E), C(6, E), C(4, E)], [C(5, O), C(4, O), C(1, O)], 0)
	m.apply(0, {"type": "flor"})
	check(m.phase == Match.Phase.RESPOND_FLOR and m.actor == 1, "el otro tiene flor y responde")
	m.apply(1, {"type": "contraflor"})
	check(m.scores == [6, 0], "contraflor: gana 37 vs 30 -> 6")
	var m2 = _new(30, true)
	m2.setup_hand([C(7, E), C(6, E), C(4, E)], [C(5, O), C(4, O), C(1, O)], 0)
	m2.apply(0, {"type": "flor"})
	m2.apply(1, {"type": "achico"})
	check(m2.scores == [4, 0], "con flor me achico: 4")


func test_flor_cancels_envido() -> void:
	print("flor responde a envido")
	var m = _new(30, true)
	m.setup_hand([C(7, B), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, O)], 0)
	m.apply(0, {"type": "envido"})
	var legal: Array = m.legal_actions(1)
	check(legal.size() == 1 and legal[0]["type"] == "flor", "debe cantar flor")
	m.apply(1, {"type": "flor"})
	check(m.scores == [0, 3], "flor 3, envido anulado")
	check(m.phase == Match.Phase.PLAY and m.actor == 0, "vuelve al turno de la mano")
	# Flor en respuesta al truco
	var m2 = _new(30, true)
	m2.setup_hand([C(7, B), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, O)], 0)
	m2.apply(0, {"type": "truco"})
	m2.apply(1, {"type": "flor"})
	check(m2.phase == Match.Phase.RESPOND_TRUCO and m2.actor == 1, "después de la flor responde el truco")


func test_raise_rights() -> void:
	print("derecho a subir el truco")
	var m = _new()
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 0)
	m.apply(0, {"type": "truco"})
	m.apply(1, {"type": "quiero"})
	check(not m.is_legal(0, {"type": "truco"}), "quien cantó no puede subir su propio truco")
	m.apply(0, {"type": "play", "card": C(4, K)})
	check(m.is_legal(1, {"type": "truco"}), "quien quiso puede cantar retruco")


func test_match_end() -> void:
	print("fin de partida")
	var m = _new(15)
	m.scores = [14, 0]
	m.setup_hand([C(7, E), C(6, E), C(4, K)], [C(5, O), C(4, O), C(1, B)], 1)
	m.apply(1, {"type": "envido"})
	m.apply(0, {"type": "quiero"})
	check(m.is_over() and m.match_winner == 0, "el envido cierra la partida")
	check(m.legal_actions(0).is_empty() and m.legal_actions(1).is_empty(), "sin acciones al terminar")


func test_ai_matches() -> bool:
	print("IA vs IA (estrés)")
	var t0 := Time.get_ticks_msec()
	var wins := [0, 0]
	var hands_played := 0
	var bad := 0
	for g in 120:
		var flor := g % 3 == 0
		var target := 15 if g % 2 == 0 else 30
		var m = Match.new(target, flor, 1000 + g)
		var ais := [AI.new({"aggression": 0.8, "bluff": 0.3, "envido_bold": 0.7}, g % 3, g),
			AI.new({"aggression": 0.3, "bluff": 0.1, "envido_bold": 0.3, "chaos": 0.3}, (g + 1) % 3, g + 7)]
		m.start_match()
		var steps := 0
		while not m.is_over() and steps < 5000:
			steps += 1
			if m.phase == Match.Phase.HAND_OVER:
				hands_played += 1
				m.next_hand()
				continue
			var p: int = m.actor
			var a: Dictionary = ais[p].choose(m.get_view(p))
			if not m.apply(p, a):
				bad += 1
				m.apply(p, m.legal_actions(p)[0])
			# Invariantes
			if m.phase != Match.Phase.MATCH_OVER and m.phase != Match.Phase.HAND_OVER:
				if m.legal_actions(m.actor).is_empty():
					bad += 1
					break
			var total: int = m.hands[0].size() + m.hands[1].size()
			for b in m.bazas:
				for c in b["cards"]:
					if c != -1:
						total += 1
			if total != 6:
				bad += 1
		m.pop_events()
		check(m.is_over(), "partida %d terminó" % g)
		if m.is_over():
			wins[m.match_winner] += 1
			check(m.scores[m.match_winner] >= target, "ganador llegó al objetivo")
	check(bad == 0, "la IA solo hizo jugadas legales y nunca hubo bloqueos (%d errores)" % bad)
	print("  120 partidas, %d manos, ganadas %s, %d ms" % [hands_played, str(wins), Time.get_ticks_msec() - t0])
	return true
