extends Control
## Anotador con fósforos, como en la mesa de verdad: cuadrados de 5
## (4 lados + la diagonal). En partidas a 30 se separan "malas" y "buenas".

var names := ["Vos", "Rival"]
var scores := [0, 0]
var target := 30
var colors := [Color(0.2, 0.45, 0.75), Color(0.85, 0.35, 0.15)]


func set_scores(s: Array) -> void:
	scores = s.duplicate()
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.07, 0.04, 0.88)
	bg.set_corner_radius_all(14)
	bg.border_color = Color(0.85, 0.65, 0.3)
	bg.set_border_width_all(2)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	var col_w := w / 2.0
	for p in 2:
		var x0 := p * col_w
		var nm: String = names[p]
		if nm.length() > 11:
			nm = nm.substr(0, 10) + "."
		draw_string(font, Vector2(x0, 24), nm, HORIZONTAL_ALIGNMENT_CENTER, col_w, 15, colors[p].lightened(0.35))
		draw_string(font, Vector2(x0, 54), str(mini(scores[p], target)), HORIZONTAL_ALIGNMENT_CENTER, col_w, 28, Color(1, 0.95, 0.85))
		var box := minf(col_w * 0.42, 30.0)
		var cx := x0 + col_w * 0.5
		var y := 70.0
		var pts: int = mini(scores[p], target)
		var groups := int(ceil(target / 5.0))
		for g in groups:
			if target == 30 and g == 3:
				y += 8
			var n := clampi(pts - g * 5, 0, 5)
			_draw_group(Vector2(cx - box * 0.5, y), box, n)
			y += box + 8
	if target == 30:
		var box2 := minf(col_w * 0.42, 30.0)
		var ly := 70.0 + 3 * (box2 + 8) + 2
		draw_line(Vector2(10, ly), Vector2(w - 10, ly), Color(0.85, 0.65, 0.3, 0.6), 1.5)
		draw_string(font, Vector2(0, ly - 2), "malas", HORIZONTAL_ALIGNMENT_RIGHT, w - 6, 10, Color(1, 1, 1, 0.5))
		draw_string(font, Vector2(0, ly + 11), "buenas", HORIZONTAL_ALIGNMENT_RIGHT, w - 6, 10, Color(1, 1, 1, 0.5))
	draw_line(Vector2(col_w, 10), Vector2(col_w, h - 10), Color(0.85, 0.65, 0.3, 0.4), 1.0)


func _draw_group(o: Vector2, s: float, n: int) -> void:
	var ghost := Color(1, 1, 1, 0.08)
	var sides := [[o, o + Vector2(0, s)], [o, o + Vector2(s, 0)], [o + Vector2(s, 0), o + Vector2(s, s)], [o + Vector2(0, s), o + Vector2(s, s)], [o, o + Vector2(s, s)]]
	for i in 5:
		var a: Vector2 = sides[i][0]
		var b: Vector2 = sides[i][1]
		if i < n:
			_match(a, b)
		else:
			draw_line(a, b, ghost, 2.0)


func _match(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, Color(0.95, 0.85, 0.6), 3.5)
	draw_circle(b, 3.5, Color(0.8, 0.15, 0.1))
