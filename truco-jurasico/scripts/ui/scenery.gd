extends Control
## Escenario: "Pulpería Prehistórica de Tafí del Valle".
## Cerros del Aconquija, dique La Angostura, menhires, un braquiosaurio
## paseando, pterodáctilos y la mesa de la pulpería. Todo procedural.

var show_table := true
var _t := 0.0
var _stars: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 40:
		_stars.append(Vector2(rng.randf(), rng.randf() * 0.35))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Cielo de atardecer (degradé)
	var sky := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.62), Vector2(0, h * 0.62)])
	var top := Color(0.22, 0.12, 0.35)
	var bot := Color(0.98, 0.55, 0.3)
	draw_polygon(sky, PackedColorArray([top, top, bot, bot]))
	for s in _stars:
		var a := 0.4 + 0.4 * sin(_t * 2.0 + s.x * 30.0)
		draw_circle(Vector2(s.x * w, s.y * h), 1.2, Color(1, 1, 0.9, a))
	# Sol poniente
	draw_circle(Vector2(w * 0.72, h * 0.45), h * 0.09, Color(1, 0.85, 0.45, 0.9))
	draw_circle(Vector2(w * 0.72, h * 0.45), h * 0.12, Color(1, 0.8, 0.4, 0.25))
	# Cordón del Aconquija (lejos, con nieve)
	var far := PackedVector2Array([Vector2(0, h * 0.5)])
	var peaks := [0.0, 0.36, 0.08, 0.3, 0.17, 0.42, 0.27, 0.33, 0.4, 0.26, 0.52, 0.38, 0.63, 0.31, 0.75, 0.4, 0.86, 0.29, 1.0, 0.37]
	for i in range(0, peaks.size(), 2):
		far.append(Vector2(peaks[i] * w, peaks[i + 1] * h))
	far.append(Vector2(w, h * 0.5))
	draw_colored_polygon(far, Color(0.42, 0.33, 0.55))
	for i in range(2, peaks.size() - 2, 2):
		if peaks[i + 1] < 0.32:
			var p := Vector2(peaks[i] * w, peaks[i + 1] * h)
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(w * 0.025, h * 0.035), p + Vector2(-w * 0.025, h * 0.035)]), Color(0.95, 0.93, 1.0, 0.85))
	# Braquiosaurio paseando a lo lejos
	var bx := fmod(_t * 12.0, w + 400.0) - 200.0
	_draw_brachio(Vector2(bx, h * 0.5), h * 0.0016)
	# Cerros verdes del valle
	var mid := PackedVector2Array([Vector2(0, h * 0.62)])
	for i in 13:
		var x := i / 12.0
		mid.append(Vector2(x * w, h * (0.47 + 0.05 * sin(x * 9.0) + 0.03 * sin(x * 23.0))))
	mid.append(Vector2(w, h * 0.62))
	draw_colored_polygon(mid, Color(0.3, 0.42, 0.25))
	# Dique La Angostura
	draw_colored_polygon(_ellipse(Vector2(w * 0.3, h * 0.585), w * 0.2, h * 0.03), Color(0.45, 0.55, 0.75))
	draw_line(Vector2(w * 0.2, h * 0.58), Vector2(w * 0.32, h * 0.58), Color(1, 0.8, 0.6, 0.5), 2.0)
	# Suelo de la pulpería
	draw_rect(Rect2(0, h * 0.6, w, h * 0.4), Color(0.45, 0.3, 0.18))
	draw_polygon(PackedVector2Array([Vector2(0, h * 0.6), Vector2(w, h * 0.6), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color(0.5, 0.36, 0.22), Color(0.5, 0.36, 0.22), Color(0.3, 0.19, 0.1), Color(0.3, 0.19, 0.1)]))
	# Menhires de Tafí
	_draw_menhir(Vector2(w * 0.06, h * 0.62), h * 0.24)
	_draw_menhir(Vector2(w * 0.95, h * 0.64), h * 0.2)
	_draw_menhir(Vector2(w * 0.86, h * 0.6), h * 0.13)
	# Pterodáctilos
	for i in 2:
		var px := fmod(_t * (60.0 + i * 25.0) + i * 500.0, w + 200.0) - 100.0
		var py := h * (0.12 + i * 0.1) + sin(_t * 1.5 + i) * 10.0
		_draw_ptero(Vector2(px, py), 1.0 - i * 0.3)
	# Faroles
	for x in [0.2, 0.8]:
		var flick := 0.8 + 0.2 * sin(_t * 9.0 + x * 10.0)
		var lp := Vector2(w * x, h * 0.1)
		draw_line(Vector2(lp.x, 0), lp + Vector2(0, -12), Color(0.15, 0.1, 0.08), 2.0)
		draw_circle(lp, 34, Color(1, 0.75, 0.3, 0.1 * flick))
		draw_rect(Rect2(lp + Vector2(-9, -12), Vector2(18, 24)), Color(0.2, 0.12, 0.08))
		draw_rect(Rect2(lp + Vector2(-6, -9), Vector2(12, 18)), Color(1, 0.8, 0.4, flick))
	if show_table:
		_draw_table(w, h)


func _draw_table(w: float, h: float) -> void:
	# Mesa de algarrobo con un poncho tejido encima.
	var c := Vector2(w * 0.5, h * 0.53)
	var rx := minf(w * 0.33, h * 0.62)
	var ry := h * 0.37
	draw_colored_polygon(_ellipse(c + Vector2(0, 14), rx, ry), Color(0, 0, 0, 0.35))
	draw_colored_polygon(_ellipse(c, rx, ry), Color(0.42, 0.24, 0.12))
	draw_colored_polygon(_ellipse(c, rx * 0.95, ry * 0.93), Color(0.55, 0.32, 0.16))
	# Paño / poncho
	draw_colored_polygon(_ellipse(c, rx * 0.8, ry * 0.76), Color(0.13, 0.33, 0.25))
	var ring := _ellipse(c, rx * 0.74, ry * 0.7, 64)
	ring.append(ring[0])
	draw_polyline(ring, Color(0.85, 0.65, 0.2, 0.7), 3.0)
	# guarda
	for i in 24:
		var a := TAU * i / 24.0
		var p := c + Vector2(cos(a) * rx * 0.77, sin(a) * ry * 0.73)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(6, 0), p + Vector2(0, 6), p + Vector2(-6, 0)]), Color(0.75, 0.15, 0.15, 0.8))


func _draw_menhir(base: Vector2, height: float) -> void:
	var wd := height * 0.28
	var pts := PackedVector2Array([base + Vector2(-wd * 0.5, 0), base + Vector2(-wd * 0.42, -height * 0.85), base + Vector2(0, -height), base + Vector2(wd * 0.45, -height * 0.8), base + Vector2(wd * 0.5, 0)])
	draw_colored_polygon(pts, Color(0.55, 0.52, 0.5))
	draw_colored_polygon(PackedVector2Array([base + Vector2(0, 0), base + Vector2(0, -height), base + Vector2(wd * 0.45, -height * 0.8), base + Vector2(wd * 0.5, 0)]), Color(0.45, 0.42, 0.4))
	# Rostro tallado
	var f := base + Vector2(0, -height * 0.6)
	draw_arc(f, wd * 0.22, 0, TAU, 16, Color(0.3, 0.28, 0.27), 2.0)
	draw_circle(f + Vector2(-wd * 0.08, -wd * 0.04), 2.0, Color(0.3, 0.28, 0.27))
	draw_circle(f + Vector2(wd * 0.08, -wd * 0.04), 2.0, Color(0.3, 0.28, 0.27))


func _draw_brachio(p: Vector2, k: float) -> void:
	var col := Color(0.32, 0.26, 0.42)
	var step := sin(_t * 3.0) * 6.0
	draw_colored_polygon(_ellipse(p, 70 * k, 28 * k), col)
	var neck := PackedVector2Array([p + Vector2(40, -10) * k, p + Vector2(80, -110) * k, p + Vector2(100, -115) * k, p + Vector2(60, -5) * k])
	draw_colored_polygon(neck, col)
	draw_colored_polygon(_ellipse(p + Vector2(100, -116) * k, 16 * k, 9 * k), col)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-60, -5) * k, p + Vector2(-140, 10) * k, p + Vector2(-60, 12) * k]), col)
	for lx in [-40.0, -20.0, 25.0, 45.0]:
		var off := step if int(lx) % 2 == 0 else -step
		draw_line(p + Vector2(lx, 15) * k, p + Vector2(lx + off, 55) * k, col, 11 * k)


func _draw_ptero(p: Vector2, k: float) -> void:
	var flap := sin(_t * 6.0) * 14.0 * k
	var col := Color(0.25, 0.15, 0.25)
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(-34, -flap) * k, p + Vector2(-10, 4) * k]), col)
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(34, -flap) * k, p + Vector2(10, 4) * k]), col)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -2) * k, p + Vector2(14, -6) * k, p + Vector2(4, 4) * k]), col)


func _ellipse(c: Vector2, rx: float, ry: float, n: int = 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
