extends Control
## Carta española dibujada por código (escala a cualquier tamaño, sin texturas).

const Cards = preload("res://scripts/core/cards.gd")

signal pressed(card: int)

var card := -1
var face_up := true
var selectable := false:
	set(v):
		selectable = v
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if v else Control.CURSOR_ARROW
		queue_redraw()
var show_hint := false
var glow := false:
	set(v):
		glow = v
		queue_redraw()
var dimmed := false:
	set(v):
		dimmed = v
		queue_redraw()
var lift := 0.0:
	set(v):
		lift = v
		queue_redraw()
var _hover := false

const SUIT_COLORS := [Color(0.16, 0.4, 0.75), Color(0.2, 0.5, 0.18), Color(0.85, 0.62, 0.08), Color(0.78, 0.15, 0.17)]
const PIPS := {
	1: [Vector2(0, 0)],
	2: [Vector2(0, -0.27), Vector2(0, 0.27)],
	3: [Vector2(0, -0.3), Vector2(0, 0), Vector2(0, 0.3)],
	4: [Vector2(-0.22, -0.24), Vector2(0.22, -0.24), Vector2(-0.22, 0.24), Vector2(0.22, 0.24)],
	5: [Vector2(-0.22, -0.28), Vector2(0.22, -0.28), Vector2(0, 0), Vector2(-0.22, 0.28), Vector2(0.22, 0.28)],
	6: [Vector2(-0.22, -0.3), Vector2(0.22, -0.3), Vector2(-0.22, 0), Vector2(0.22, 0), Vector2(-0.22, 0.3), Vector2(0.22, 0.3)],
	7: [Vector2(-0.22, -0.32), Vector2(0.22, -0.32), Vector2(0, -0.16), Vector2(-0.22, 0), Vector2(0.22, 0), Vector2(-0.22, 0.32), Vector2(0.22, 0.32)],
}


func setup(p_card: int, p_face_up: bool = true) -> void:
	card = p_card
	face_up = p_face_up
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): _hover = true; _update_lift())
	mouse_exited.connect(func(): _hover = false; _update_lift())


func _update_lift() -> void:
	var t := create_tween()
	t.tween_property(self, "lift", size.y * 0.1 if (_hover and selectable) else 0.0, 0.1)


func _gui_input(event: InputEvent) -> void:
	if not selectable:
		return
	var tapped := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		tapped = true
	if tapped:
		accept_event()
		pressed.emit(card)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_set_transform(Vector2(0, -lift))
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(w * 0.08)
	# Sombra
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0, 0, 0, 0.35)
	sh.set_corner_radius_all(radius)
	draw_style_box(sh, Rect2(Vector2(w * 0.03, h * 0.03 + lift * 0.5), size))
	if glow:
		var g := StyleBoxFlat.new()
		g.bg_color = Color(1, 0.85, 0.2, 0.0)
		g.set_corner_radius_all(radius + 4)
		g.border_color = Color(1, 0.85, 0.25)
		g.set_border_width_all(int(maxf(3.0, w * 0.04)))
		draw_style_box(g, r.grow(w * 0.05))
	if face_up and card >= 0:
		_draw_face(w, h, radius)
	else:
		_draw_back(w, h, radius)
	if selectable and _hover:
		var hl := StyleBoxFlat.new()
		hl.bg_color = Color(1, 1, 1, 0.0)
		hl.set_corner_radius_all(radius)
		hl.border_color = Color(1, 0.9, 0.4)
		hl.set_border_width_all(3)
		draw_style_box(hl, r)
	if dimmed:
		var dm := StyleBoxFlat.new()
		dm.bg_color = Color(0, 0, 0, 0.35)
		dm.set_corner_radius_all(radius)
		draw_style_box(dm, r)


func _draw_face(w: float, h: float, radius: int) -> void:
	var n := Cards.number(card)
	var s := Cards.suit(card)
	var col: Color = SUIT_COLORS[s]
	var face := StyleBoxFlat.new()
	face.bg_color = Color(0.99, 0.96, 0.88)
	face.set_corner_radius_all(radius)
	face.border_color = col
	face.set_border_width_all(int(maxf(2.0, w * 0.035)))
	draw_style_box(face, Rect2(Vector2.ZERO, size))
	# Marco interior cortado (como el naipe español: cortes indican el palo)
	var inner := Rect2(w * 0.1, h * 0.07, w * 0.8, h * 0.86)
	draw_rect(inner, Color(col, 0.35), false, maxf(1.0, w * 0.012))
	var font := ThemeDB.fallback_font
	var fs := int(w * 0.26)
	draw_string(font, Vector2(w * 0.06, h * 0.05 + fs * 0.85), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_string(font, Vector2(w * 0.94 - fs * (0.6 if n < 10 else 1.15), h * 0.97), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	var center := Vector2(w * 0.5, h * 0.52)
	if n <= 7:
		var big := n == 1
		var pr := w * (0.3 if big else 0.13)
		for p in PIPS[n]:
			draw_suit(self, s, center + Vector2(p.x * w, p.y * h), pr)
	else:
		_draw_figure(n, s, center, w, h, col)
	if show_hint:
		_draw_hint(w, h)


func _draw_figure(n: int, s: int, c: Vector2, w: float, h: float, col: Color) -> void:
	var fw := w * 0.56
	var fh := h * 0.52
	var rect := Rect2(c - Vector2(fw, fh) * 0.5, Vector2(fw, fh))
	draw_rect(rect, Color(col, 0.15))
	draw_rect(rect, col, false, maxf(1.0, w * 0.015))
	# Figura simple: cabeza, cuerpo y atributo
	var head := c + Vector2(0, -fh * 0.22)
	var skin := Color(0.95, 0.78, 0.6)
	var robe: Color = col.darkened(0.1)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-fw * 0.32, fh * 0.62), head + Vector2(fw * 0.32, fh * 0.62), head + Vector2(fw * 0.16, fh * 0.1), head + Vector2(-fw * 0.16, fh * 0.1)]), robe)
	draw_circle(head, fw * 0.14, skin)
	match n:
		12: # Rey: corona
			var cr := head + Vector2(0, -fw * 0.14)
			draw_colored_polygon(PackedVector2Array([cr + Vector2(-fw * 0.14, 0), cr + Vector2(-fw * 0.14, -fw * 0.12), cr + Vector2(-fw * 0.07, -fw * 0.05), cr + Vector2(0, -fw * 0.14), cr + Vector2(fw * 0.07, -fw * 0.05), cr + Vector2(fw * 0.14, -fw * 0.12), cr + Vector2(fw * 0.14, 0)]), Color(0.95, 0.75, 0.1))
		11: # Caballo: sombrero de gaucho
			var hat := head + Vector2(0, -fw * 0.12)
			draw_rect(Rect2(hat + Vector2(-fw * 0.22, -fw * 0.02), Vector2(fw * 0.44, fw * 0.05)), Color(0.15, 0.1, 0.08))
			draw_rect(Rect2(hat + Vector2(-fw * 0.1, -fw * 0.12), Vector2(fw * 0.2, fw * 0.11)), Color(0.15, 0.1, 0.08))
		10: # Sota: boina
			draw_circle(head + Vector2(0, -fw * 0.1), fw * 0.12, Color(0.2, 0.2, 0.4))
	draw_suit(self, s, c + Vector2(fw * 0.27, fh * 0.28), w * 0.1)
	var font := ThemeDB.fallback_font
	var label := Cards.figure_name(n)
	var fs := int(w * 0.1)
	draw_string(font, Vector2(rect.position.x, rect.end.y + fs * 1.05), label, HORIZONTAL_ALIGNMENT_CENTER, fw, fs, col.darkened(0.2))


func _draw_hint(w: float, h: float) -> void:
	# Barra de fuerza (1..14) y apodo de las cartas bravas.
	var rk := Cards.rank(card)
	var bar := Rect2(w * 0.14, h * 0.885, w * 0.72, h * 0.035)
	draw_rect(bar, Color(0, 0, 0, 0.15))
	var hue := lerpf(0.0, 0.33, rk / 14.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * rk / 14.0, bar.size.y)), Color.from_hsv(hue, 0.8, 0.85))
	var nick := Cards.nickname(card)
	if nick != "":
		var font := ThemeDB.fallback_font
		var fs := int(w * 0.085)
		var y := h * 0.865
		draw_rect(Rect2(w * 0.1, y - fs, w * 0.8, fs * 1.25), Color(0.1, 0.05, 0.02, 0.8))
		draw_string(font, Vector2(w * 0.1, y), nick.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, w * 0.8, fs, Color(1, 0.85, 0.3))


func _draw_back(w: float, h: float, radius: int) -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.55, 0.12, 0.1)
	back.set_corner_radius_all(radius)
	back.border_color = Color(0.98, 0.9, 0.75)
	back.set_border_width_all(int(maxf(2.0, w * 0.05)))
	draw_style_box(back, Rect2(Vector2.ZERO, size))
	# Guarda de rombos tipo aguayo
	var step := w * 0.16
	var y := h * 0.12
	var cols := [Color(0.95, 0.75, 0.15), Color(0.15, 0.55, 0.45), Color(0.95, 0.9, 0.8)]
	var row := 0
	while y < h * 0.9:
		var x := w * 0.14 + (step * 0.5 if row % 2 else 0.0)
		while x < w * 0.88:
			var c: Color = cols[(row + int(x / step)) % 3]
			var d := step * 0.32
			draw_colored_polygon(PackedVector2Array([Vector2(x, y - d), Vector2(x + d, y), Vector2(x, y + d), Vector2(x - d, y)]), Color(c, 0.85))
			x += step
		y += step * 0.75
		row += 1
	# Huella de dinosaurio en el centro
	var c := Vector2(w * 0.5, h * 0.5)
	draw_circle(c, w * 0.2, Color(0.98, 0.9, 0.75))
	var foot := Color(0.55, 0.12, 0.1)
	draw_circle(c + Vector2(0, w * 0.05), w * 0.07, foot)
	for a in [-0.6, 0.0, 0.6]:
		var dir := Vector2(sin(a), -cos(a))
		draw_line(c + Vector2(0, w * 0.03), c + dir * w * 0.14, foot, w * 0.045)


## Dibuja el símbolo de un palo centrado en c con "radio" r.
static func draw_suit(ci: CanvasItem, s: int, c: Vector2, r: float) -> void:
	match s:
		Cards.ORO:
			ci.draw_circle(c, r * 0.8, Color(0.75, 0.5, 0.05))
			ci.draw_circle(c, r * 0.68, Color(0.98, 0.78, 0.15))
			ci.draw_arc(c, r * 0.45, 0, TAU, 24, Color(0.75, 0.5, 0.05), maxf(1.0, r * 0.08))
			ci.draw_circle(c, r * 0.22, Color(0.85, 0.3, 0.1))
		Cards.COPA:
			var red := Color(0.78, 0.15, 0.17)
			var gold := Color(0.95, 0.72, 0.15)
			var bowl := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				bowl.append(c + Vector2(cos(a) * r * 0.62, -r * 0.55 + sin(a) * r * 0.7))
			ci.draw_colored_polygon(bowl, red)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.64, -r * 0.64), Vector2(r * 1.28, r * 0.16)), gold)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.09, r * 0.12), Vector2(r * 0.18, r * 0.42)), gold)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.4, r * 0.75), c + Vector2(r * 0.4, r * 0.75), c + Vector2(r * 0.15, r * 0.5), c + Vector2(-r * 0.15, r * 0.5)]), red)
		Cards.ESPADA:
			var blade := Color(0.16, 0.4, 0.75)
			var gold2 := Color(0.95, 0.72, 0.15)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.14, -r * 0.75), c + Vector2(r * 0.12, r * 0.4), c + Vector2(-r * 0.12, r * 0.4), c + Vector2(-r * 0.14, -r * 0.75)]), blade)
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.35), Color(0.75, 0.85, 1.0), maxf(1.0, r * 0.05))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, r * 0.38), Vector2(r * 0.9, r * 0.13)), gold2)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.08, r * 0.5), Vector2(r * 0.16, r * 0.32)), Color(0.45, 0.25, 0.1))
			ci.draw_circle(c + Vector2(0, r * 0.88), r * 0.12, gold2)
		Cards.BASTO:
			var wood := Color(0.42, 0.6, 0.2)
			var dark := Color(0.25, 0.38, 0.1)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.32, -r * 0.85), c + Vector2(r * 0.32, -r * 0.92), c + Vector2(r * 0.2, r * 0.9), c + Vector2(-r * 0.14, r * 0.9)]), wood)
			ci.draw_circle(c + Vector2(0, -r * 0.88), r * 0.33, wood)
			for k in [Vector2(-0.12, -0.45), Vector2(0.14, -0.05), Vector2(-0.06, 0.4)]:
				ci.draw_circle(c + k * r * 1.0, r * 0.1, dark)
			ci.draw_line(c + Vector2(r * 0.25, -r * 0.3), c + Vector2(r * 0.45, -r * 0.42), dark, maxf(1.0, r * 0.08))
