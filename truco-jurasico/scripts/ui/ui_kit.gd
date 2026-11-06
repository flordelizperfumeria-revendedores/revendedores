extends RefCounted
## Tema visual y helpers para construir la interfaz por código.

const CREAM := Color(1, 0.95, 0.85)
const GOLD := Color(0.95, 0.72, 0.25)
const RED := Color(0.72, 0.16, 0.12)
const BLUE := Color(0.18, 0.4, 0.72)
const GREEN := Color(0.2, 0.55, 0.25)
const GRAY := Color(0.35, 0.32, 0.3)
const DARK := Color(0.12, 0.07, 0.04)
const PURPLE := Color(0.5, 0.2, 0.55)

static var _bold: FontVariation


static func bold_font() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = bold_font()
	t.default_font_size = 20
	_button_styles(t, "Button", RED)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.4))
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 4)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.12, 0.07, 0.04, 0.92)
	panel.set_corner_radius_all(18)
	panel.border_color = GOLD
	panel.set_border_width_all(3)
	panel.set_content_margin_all(20)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_color("default_color", "RichTextLabel", CREAM)
	t.set_font("bold_font", "RichTextLabel", bold_font())
	t.set_font("normal_font", "RichTextLabel", ThemeDB.fallback_font)
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 19)
	return t


static func _box(c: Color, border: Color, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(12)
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 3)
	return s


static func _button_styles(t: Theme, type: String, c: Color) -> void:
	t.set_stylebox("normal", type, _box(c, GOLD))
	t.set_stylebox("hover", type, _box(c.lightened(0.15), Color(1, 0.9, 0.5), 3))
	t.set_stylebox("pressed", type, _box(c.darkened(0.2), GOLD))
	t.set_stylebox("disabled", type, _box(Color(0.25, 0.22, 0.2, 0.8), Color(0.4, 0.35, 0.3)))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())


static func color_button(b: Button, c: Color) -> void:
	b.add_theme_stylebox_override("normal", _box(c, GOLD))
	b.add_theme_stylebox_override("hover", _box(c.lightened(0.15), Color(1, 0.9, 0.5), 3))
	b.add_theme_stylebox_override("pressed", _box(c.darkened(0.2), GOLD))


static func button(text: String, c: Color = RED, font_size: int = 20, min_size: Vector2 = Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.custom_minimum_size = min_size
	color_button(b, c)
	b.pressed.connect(func(): Audio.play("click"))
	return b


static func label(text: String, font_size: int = 20, color: Color = CREAM, outline: int = 5) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	return l


static func title(text: String, font_size: int = 64) -> Label:
	var l := label(text, font_size, Color(1, 0.82, 0.3), 14)
	l.add_theme_color_override("font_outline_color", Color(0.35, 0.08, 0.05))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Botón de opciones excluyentes (devuelve el HBox; llama on_change(valor)).
static func toggle_group(options: Array, values: Array, current, on_change: Callable, font_size: int = 17) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var buttons: Array = []
	for i in options.size():
		var b := button(options[i], GRAY, font_size)
		buttons.append(b)
		box.add_child(b)
	var refresh := func(sel):
		for j in buttons.size():
			color_button(buttons[j], RED if values[j] == sel else GRAY)
	refresh.call(current)
	for i in options.size():
		var v = values[i]
		buttons[i].pressed.connect(func():
			refresh.call(v)
			on_change.call(v))
	return box


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
