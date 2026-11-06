extends RefCounted
## Mazo español de 40 cartas y reglas puras (sin dependencias de UI).
## Una carta es un int: palo * 16 + número  (número 1..7, 10, 11, 12).

const ESPADA := 0
const BASTO := 1
const ORO := 2
const COPA := 3
const SUIT_NAMES := ["Espada", "Basto", "Oro", "Copa"]
const SUIT_PLURAL := ["Espadas", "Bastos", "Oros", "Copas"]
const NUMBERS := [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]
const PARDA := 2
const NONE := -1


static func make(n: int, s: int) -> int:
	return s * 16 + n


static func number(c: int) -> int:
	return c & 15


static func suit(c: int) -> int:
	return c >> 4


static func full_deck() -> Array:
	var d: Array = []
	for s in 4:
		for n in NUMBERS:
			d.append(make(n, s))
	return d


## Jerarquía del truco: 14 = ancho de espada ... 1 = cuatros.
static func rank(c: int) -> int:
	var n := number(c)
	var s := suit(c)
	if n == 1 and s == ESPADA:
		return 14
	if n == 1 and s == BASTO:
		return 13
	if n == 7 and s == ESPADA:
		return 12
	if n == 7 and s == ORO:
		return 11
	match n:
		3: return 10
		2: return 9
		1: return 8
		12: return 7
		11: return 6
		10: return 5
		7: return 4
		6: return 3
		5: return 2
		4: return 1
	return 0


static func envido_value(c: int) -> int:
	var n := number(c)
	return 0 if n >= 10 else n


## Tanto de envido de una mano (2 o 3 cartas). Máximo 33.
static func envido_points(hand: Array) -> int:
	var best := 0
	for c in hand:
		best = maxi(best, envido_value(c))
	for i in hand.size():
		for j in range(i + 1, hand.size()):
			if suit(hand[i]) == suit(hand[j]):
				best = maxi(best, 20 + envido_value(hand[i]) + envido_value(hand[j]))
	return best


static func has_flor(hand: Array) -> bool:
	return hand.size() == 3 and suit(hand[0]) == suit(hand[1]) and suit(hand[1]) == suit(hand[2])


static func flor_points(hand: Array) -> int:
	var t := 20
	for c in hand:
		t += envido_value(c)
	return t


## Resultado de una baza: 0, 1 o PARDA.
static func baza_result(c0: int, c1: int) -> int:
	var r0 := rank(c0)
	var r1 := rank(c1)
	if r0 > r1:
		return 0
	if r1 > r0:
		return 1
	return PARDA


## Decide el ganador de la mano a partir de los resultados de las bazas jugadas.
## Devuelve 0/1, o NONE si todavía no está definida.
static func hand_winner(results: Array, mano: int) -> int:
	var wins := [0, 0]
	for r in results:
		if r != PARDA:
			wins[r] += 1
	for p in 2:
		if wins[p] >= 2:
			return p
	var n := results.size()
	if n >= 2:
		var r0: int = results[0]
		var r1: int = results[1]
		if r0 == PARDA and r1 != PARDA:
			return r1          # parda la primera: gana el que gana la segunda
		if r0 != PARDA and r1 == PARDA:
			return r0          # parda la segunda: gana el que ganó la primera
	if n == 3:
		var r0b: int = results[0]
		var r2: int = results[2]
		if r2 != PARDA:
			return r2          # (parda, parda, X) o (X, Y, X)
		if r0b != PARDA:
			return r0b         # (X, Y, parda): gana el que ganó la primera
		return mano            # todo pardo: gana la mano
	return NONE


static func card_name(c: int) -> String:
	return "%d de %s" % [number(c), SUIT_PLURAL[suit(c)]]


static func nickname(c: int) -> String:
	match rank(c):
		14: return "Ancho de espada"
		13: return "Ancho de basto"
		12: return "Siete de espada"
		11: return "Siete de oro"
	return ""


static func figure_name(n: int) -> String:
	match n:
		10: return "SOTA"
		11: return "CABALLO"
		12: return "REY"
	return ""
