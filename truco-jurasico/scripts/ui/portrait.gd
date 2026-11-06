extends Control
## Retrato animado de un personaje, dibujado por código (placeholder de arte).
## Expresiones: normal, happy, angry, sad, smug. Animaciones: bounce, shake,
## celebrate, talk. Para usar arte final: reemplazar _draw_* por sprites.

var character := "rex":
	set(v):
		character = v
		queue_redraw()
var expression := "normal":
	set(v):
		expression = v
		queue_redraw()
var frame := true
var _t := 0.0
var _offset := Vector2.ZERO
var _squash := 1.0
var _talk := 0.0
var _rot := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _talk > 0.0:
		_talk = maxf(0.0, _talk - delta)
	queue_redraw()


func talk(seconds: float = 1.2) -> void:
	_talk = seconds


func bounce() -> void:
	var t := create_tween()
	t.tween_method(func(v): _offset.y = v, 0.0, -size.y * 0.12, 0.12).set_ease(Tween.EASE_OUT)
	t.tween_method(func(v): _offset.y = v, -size.y * 0.12, 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func shake(strength: float = 10.0, time: float = 0.5) -> void:
	var t := create_tween()
	var steps := int(time / 0.05)
	for i in steps:
		var k := 1.0 - float(i) / steps
		t.tween_method(func(v): _offset.x = v, _offset.x, randf_range(-strength, strength) * k, 0.05)
	t.tween_method(func(v): _offset.x = v, _offset.x, 0.0, 0.05)


func celebrate() -> void:
	var t := create_tween()
	for i in 3:
		t.tween_method(func(v): _offset.y = v; _rot = v * -0.004, 0.0, -size.y * 0.15, 0.13).set_ease(Tween.EASE_OUT)
		t.tween_method(func(v): _offset.y = v; _rot = v * 0.004, -size.y * 0.15, 0.0, 0.13).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): _rot = 0.0)


func _draw() -> void:
	var s := minf(size.x, size.y) / 200.0
	var bob := sin(_t * 2.2) * 2.0
	var center := size * 0.5
	if frame:
		var col: Color = _char_color()
		draw_circle(center, minf(size.x, size.y) * 0.5, Color(0.08, 0.05, 0.04, 0.6))
		draw_circle(center, minf(size.x, size.y) * 0.48, col.darkened(0.45))
		draw_circle(center, minf(size.x, size.y) * 0.44, col.darkened(0.15))
	var origin := center - Vector2(100, 100) * s + _offset + Vector2(0, bob * s)
	draw_set_transform(origin, _rot, Vector2(s, s * _squash))
	match character:
		"rex": _draw_rex()
		"cirilo": _draw_cirilo()
		"yanina": _draw_yanina()
	draw_set_transform(Vector2.ZERO)


func _char_color() -> Color:
	match character:
		"rex": return Color(0.85, 0.35, 0.15)
		"cirilo": return Color(0.2, 0.45, 0.75)
		"yanina": return Color(0.75, 0.2, 0.55)
	return Color.GRAY


func _mouth_open() -> float:
	if _talk > 0.0:
		return absf(sin(_t * 18.0))
	return 0.0


static func ellipse(c: Vector2, rx: float, ry: float, n: int = 28, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


# ------------------------------------------------------------------ Don Rex

func _draw_rex() -> void:
	var green := Color(0.36, 0.66, 0.3)
	var dark := Color(0.2, 0.42, 0.17)
	if expression == "angry":
		green = Color(0.62, 0.55, 0.22)
	# Poncho rojo con guardas negras
	draw_colored_polygon(PackedVector2Array([Vector2(30, 200), Vector2(170, 200), Vector2(140, 138), Vector2(62, 138)]), Color(0.72, 0.1, 0.12))
	for i in 3:
		var y := 160.0 + i * 13.0
		draw_line(Vector2(48 - i * 3, y), Vector2(152 + i * 3, y), Color(0.1, 0.05, 0.05), 3.0)
	# Cuello
	draw_colored_polygon(PackedVector2Array([Vector2(70, 145), Vector2(120, 145), Vector2(115, 105), Vector2(78, 105)]), green)
	# Bracito
	draw_line(Vector2(132, 150), Vector2(150, 140), green, 7.0)
	draw_line(Vector2(150, 140), Vector2(158, 136), Color.WHITE, 2.0)
	draw_line(Vector2(150, 140), Vector2(157, 143), Color.WHITE, 2.0)
	# Cabeza
	draw_colored_polygon(PackedVector2Array([Vector2(58, 118), Vector2(54, 82), Vector2(72, 56), Vector2(118, 50), Vector2(160, 58), Vector2(178, 76), Vector2(176, 98), Vector2(150, 108), Vector2(110, 114)]), green)
	# Mandíbula (se abre al hablar o enojarse)
	var open := _mouth_open() * 10.0
	if expression == "angry" or expression == "happy":
		open = maxf(open, 8.0)
	var jaw := PackedVector2Array([Vector2(70, 112), Vector2(168, 100 + open), Vector2(162, 120 + open), Vector2(88, 130)])
	draw_colored_polygon(PackedVector2Array([Vector2(80, 112), Vector2(166, 100), Vector2(166, 101 + open), Vector2(85, 116)]), Color(0.5, 0.08, 0.1))
	draw_colored_polygon(jaw, dark)
	# Dientes
	for i in 6:
		var x := 92.0 + i * 13.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 109 - i * 1.4), Vector2(x + 8, 108 - i * 1.4), Vector2(x + 4, 117 - i * 1.4)]), Color.WHITE)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 2, 112 + open - i * 1.6), Vector2(x + 10, 111 + open - i * 1.6), Vector2(x + 6, 104 + open - i * 1.6)]), Color(0.97, 0.95, 0.85))
	# Escamas
	for p in [Vector2(80, 70), Vector2(95, 88), Vector2(130, 62), Vector2(68, 98)]:
		draw_circle(p, 3.5, dark)
	# Ojo y ceja
	draw_circle(Vector2(108, 72), 10, Color.WHITE)
	var pupil := Vector2(111, 73)
	if expression == "sad":
		pupil = Vector2(108, 77)
	draw_circle(pupil, 4.5, Color.BLACK)
	var brow := [Vector2(94, 58), Vector2(122, 62)]
	match expression:
		"angry": brow = [Vector2(94, 55), Vector2(122, 68)]
		"sad": brow = [Vector2(94, 66), Vector2(122, 58)]
		"happy", "smug": brow = [Vector2(94, 58), Vector2(122, 56)]
	draw_line(brow[0], brow[1], Color(0.1, 0.15, 0.05), 5.0)
	draw_circle(Vector2(168, 70), 2.5, dark)
	# Sombrero negro
	draw_colored_polygon(ellipse(Vector2(100, 52), 50, 8, 24, -0.08), Color(0.1, 0.08, 0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(76, 50), Vector2(80, 24), Vector2(122, 22), Vector2(124, 46)]), Color(0.12, 0.1, 0.1))
	draw_line(Vector2(79, 42), Vector2(124, 40), Color(0.75, 0.12, 0.12), 4.0)
	if expression == "angry":
		# Vapor de bronca
		for i in 3:
			var y := 30.0 - fmod(_t * 30.0 + i * 12.0, 30.0)
			draw_circle(Vector2(150 + i * 10, y + 10), 5.0 + i, Color(1, 1, 1, 0.6))
		draw_colored_polygon(ellipse(Vector2(140, 90), 9, 5), Color(0.9, 0.2, 0.1, 0.6))


# ------------------------------------------------------------------ Cirilo

func _draw_cirilo() -> void:
	var skin := Color(0.82, 0.6, 0.42)
	var skin_d := Color(0.68, 0.45, 0.3)
	# Camisa, chaleco y pañuelo
	draw_colored_polygon(PackedVector2Array([Vector2(28, 200), Vector2(172, 200), Vector2(158, 148), Vector2(42, 148)]), Color(0.93, 0.92, 0.88))
	draw_colored_polygon(PackedVector2Array([Vector2(28, 200), Vector2(78, 200), Vector2(88, 150), Vector2(42, 148)]), Color(0.32, 0.2, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(122, 200), Vector2(172, 200), Vector2(158, 148), Vector2(112, 150)]), Color(0.32, 0.2, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(74, 140), Vector2(126, 140), Vector2(100, 178)]), Color(0.8, 0.1, 0.12))
	# Cara
	draw_colored_polygon(ellipse(Vector2(60, 98), 8, 12), skin_d)
	draw_colored_polygon(ellipse(Vector2(140, 98), 8, 12), skin_d)
	draw_colored_polygon(ellipse(Vector2(100, 98), 40, 46), skin)
	# Patillas
	draw_colored_polygon(PackedVector2Array([Vector2(60, 80), Vector2(68, 80), Vector2(70, 112), Vector2(62, 108)]), Color(0.55, 0.55, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(132, 80), Vector2(140, 80), Vector2(138, 108), Vector2(130, 112)]), Color(0.55, 0.55, 0.55))
	# Ojos
	match expression:
		"happy", "smug":
			draw_arc(Vector2(84, 90), 6, PI, TAU, 8, Color.BLACK, 3.0)
			draw_arc(Vector2(116, 90), 6, PI, TAU, 8, Color.BLACK, 3.0)
		_:
			draw_circle(Vector2(84, 90), 4, Color.BLACK)
			draw_circle(Vector2(116, 90), 4, Color.BLACK)
	var brow_l := [Vector2(74, 78), Vector2(94, 80)]
	var brow_r := [Vector2(106, 80), Vector2(126, 78)]
	if expression == "angry":
		brow_l = [Vector2(74, 74), Vector2(94, 82)]
		brow_r = [Vector2(106, 82), Vector2(126, 74)]
	elif expression == "sad":
		brow_l = [Vector2(74, 82), Vector2(94, 76)]
		brow_r = [Vector2(106, 76), Vector2(126, 82)]
	draw_line(brow_l[0], brow_l[1], Color(0.6, 0.6, 0.6), 6.0)
	draw_line(brow_r[0], brow_r[1], Color(0.6, 0.6, 0.6), 6.0)
	# Nariz
	draw_colored_polygon(ellipse(Vector2(100, 104), 9, 11), skin_d)
	# Boca y bigotazo
	var mo := _mouth_open() * 6.0
	if expression == "happy":
		draw_colored_polygon(ellipse(Vector2(100, 126 + mo * 0.5), 12, 5 + mo), Color(0.4, 0.08, 0.08))
	elif expression == "sad":
		draw_arc(Vector2(100, 134), 9, PI * 1.15, PI * 1.85, 8, Color(0.3, 0.1, 0.1), 3.0)
	else:
		draw_colored_polygon(ellipse(Vector2(100, 126 + mo * 0.5), 9, 2 + mo), Color(0.4, 0.08, 0.08))
	var wig := sin(_t * 3.0) * 1.5
	draw_colored_polygon(PackedVector2Array([Vector2(100, 112), Vector2(124, 112), Vector2(142, 118 + wig), Vector2(146, 108 + wig), Vector2(150, 122 + wig), Vector2(128, 124), Vector2(100, 120), Vector2(72, 124), Vector2(50, 122 - wig), Vector2(54, 108 - wig), Vector2(58, 118 - wig), Vector2(76, 112)]), Color(0.75, 0.75, 0.73))
	# Sombrero de ala ancha
	draw_colored_polygon(ellipse(Vector2(100, 58), 66, 11), Color(0.28, 0.18, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(66, 58), Vector2(72, 24), Vector2(128, 24), Vector2(134, 58)]), Color(0.33, 0.22, 0.12))
	draw_line(Vector2(68, 50), Vector2(132, 50), Color(0.1, 0.07, 0.05), 5.0)


# ------------------------------------------------------------------ Yanina

func _draw_yanina() -> void:
	var skin := Color(0.85, 0.62, 0.45)
	var hair := Color(0.12, 0.07, 0.06)
	var sway := sin(_t * 1.7) * 3.0
	# Pelo largo atrás
	draw_colored_polygon(PackedVector2Array([Vector2(58, 70), Vector2(142, 70), Vector2(152 + sway, 150), Vector2(146 + sway, 196), Vector2(128, 168), Vector2(72, 168), Vector2(54 - sway, 196), Vector2(48 - sway, 150)]), hair)
	# Hombros y cuello
	draw_colored_polygon(PackedVector2Array([Vector2(26, 200), Vector2(174, 200), Vector2(166, 168), Vector2(126, 152), Vector2(74, 152), Vector2(34, 168)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(86, 120), Vector2(114, 120), Vector2(118, 156), Vector2(82, 156)]), skin)
	# Top tipo bandeau con estampado de escamas de dino
	draw_colored_polygon(PackedVector2Array([Vector2(46, 200), Vector2(154, 200), Vector2(150, 182), Vector2(124, 176), Vector2(100, 184), Vector2(76, 176), Vector2(50, 182)]), Color(0.3, 0.6, 0.35))
	for p in [Vector2(64, 190), Vector2(90, 194), Vector2(112, 190), Vector2(136, 193)]:
		draw_colored_polygon(ellipse(p, 5, 3), Color(0.95, 0.75, 0.2))
	# Collar con diente de dinosaurio
	draw_arc(Vector2(100, 150), 22, 0.3, PI - 0.3, 16, Color(0.95, 0.8, 0.3), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(95, 170), Vector2(105, 170), Vector2(100, 184)]), Color(0.98, 0.95, 0.85))
	# Cara
	draw_colored_polygon(ellipse(Vector2(100, 96), 31, 38), skin)
	# Flequillo
	draw_colored_polygon(PackedVector2Array([Vector2(68, 92), Vector2(70, 66), Vector2(100, 58), Vector2(132, 66), Vector2(132, 82), Vector2(110, 72), Vector2(84, 76)]), hair)
	# Ojos con delineado
	var wink := expression == "smug"
	for side in [-1, 1]:
		var e := Vector2(100 + side * 13, 94)
		if wink and side == 1:
			draw_arc(e, 6, 0.2, PI - 0.2, 8, Color.BLACK, 2.5)
			continue
		if expression == "happy":
			draw_arc(e + Vector2(0, 3), 6, PI + 0.2, TAU - 0.2, 8, Color.BLACK, 2.5)
			continue
		draw_colored_polygon(ellipse(e + Vector2(0, -3), 8, 4), Color(0.55, 0.25, 0.6, 0.6))
		draw_colored_polygon(ellipse(e, 6.5, 4.0), Color.WHITE)
		draw_circle(e, 3.2, Color(0.3, 0.18, 0.08))
		draw_line(e + Vector2(-7, -2), e + Vector2(7 * side * 0 + 8, -4), Color.BLACK, 2.0)
		draw_line(e + Vector2(side * 7, -2), e + Vector2(side * 10, -6), Color.BLACK, 1.5)
	var by := 82.0
	if expression == "angry":
		draw_line(Vector2(80, by - 2), Vector2(94, by + 3), hair, 2.5)
		draw_line(Vector2(106, by + 3), Vector2(120, by - 2), hair, 2.5)
	else:
		draw_arc(Vector2(87, by + 4), 8, PI * 1.15, PI * 1.85, 8, hair, 2.5)
		draw_arc(Vector2(113, by + 4), 8, PI * 1.15, PI * 1.85, 8, hair, 2.5)
	# Lunar y nariz
	draw_circle(Vector2(122, 112), 1.6, Color(0.25, 0.12, 0.08))
	draw_line(Vector2(100, 100), Vector2(97, 110), Color(0.7, 0.45, 0.32), 2.0)
	# Labios
	var mo := _mouth_open() * 5.0
	var red := Color(0.8, 0.08, 0.2)
	match expression:
		"sad", "angry":
			draw_colored_polygon(ellipse(Vector2(100, 122 + mo * 0.3), 8, 3 + mo * 0.5), red)
		"happy":
			draw_colored_polygon(PackedVector2Array([Vector2(88, 118), Vector2(112, 118), Vector2(106, 127 + mo), Vector2(94, 127 + mo)]), red)
			draw_line(Vector2(91, 119), Vector2(109, 119), Color.WHITE, 2.0)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(89, 120), Vector2(100, 117), Vector2(111, 119), Vector2(104, 125 + mo), Vector2(95, 125 + mo)]), red)
	# Aros dorados
	draw_arc(Vector2(70, 110), 7, 0, TAU, 16, Color(0.95, 0.78, 0.2), 2.0)
	draw_arc(Vector2(130, 110), 7, 0, TAU, 16, Color(0.95, 0.78, 0.2), 2.0)
	# Sombrero con pluma, inclinado
	var hat := Color(0.82, 0.62, 0.38)
	draw_colored_polygon(ellipse(Vector2(102, 62), 56, 9, 24, -0.15), hat)
	draw_colored_polygon(PackedVector2Array([Vector2(76, 62), Vector2(80, 34), Vector2(118, 28), Vector2(126, 56)]), hat.darkened(0.1))
	draw_line(Vector2(78, 54), Vector2(125, 48), Color(0.75, 0.15, 0.4), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(122, 50), Vector2(150, 18 + sway), Vector2(156, 22 + sway), Vector2(128, 52)]), Color(0.9, 0.3, 0.55))
