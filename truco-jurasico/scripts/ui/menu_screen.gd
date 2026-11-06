extends Control
## Menú principal.

const UI = preload("res://scripts/ui/ui_kit.gd")
const Scenery = preload("res://scripts/ui/scenery.gd")
const Portrait = preload("res://scripts/ui/portrait.gd")
const Chars = preload("res://scripts/data/characters.gd")

var main
var _portraits: Array = []
var _bubble: Label
var _t := 0.0


func _ready() -> void:
	var sc := Scenery.new()
	sc.show_table = false
	add_child(sc)
	UI.full_rect(sc)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	UI.full_rect(shade)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	UI.full_rect(root)

	root.add_child(UI.title("TRUCO JURÁSICO", 78))
	var sub := UI.label("Valles Calchaquíes · Tucumán · Año 65.000.000 a.C. (más o menos)", 22, Color(1, 0.9, 0.7))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.custom_minimum_size.y = 190
	root.add_child(row)
	for id in Chars.LIST:
		var col := VBoxContainer.new()
		var p := Portrait.new()
		p.character = id
		p.custom_minimum_size = Vector2(160, 160)
		col.add_child(p)
		var n := UI.label(Chars.get_data(id)["name"], 18)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		row.add_child(col)
		_portraits.append(p)

	_bubble = UI.label("", 20, Color(1, 1, 0.8))
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.custom_minimum_size.y = 30
	root.add_child(_bubble)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var center := CenterContainer.new()
	center.add_child(buttons)
	root.add_child(center)
	var b1 := UI.button("JUGAR CONTRA LA MÁQUINA", UI.RED, 24, Vector2(460, 56))
	b1.pressed.connect(func(): main.show_setup("ai"))
	buttons.add_child(b1)
	var b2 := UI.button("2 JUGADORES (MISMO DISPOSITIVO)", UI.BLUE, 20, Vector2(460, 48))
	b2.pressed.connect(func(): main.show_setup("pvp"))
	buttons.add_child(b2)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var b3 := UI.button("CÓMO SE JUEGA", UI.GREEN, 18, Vector2(225, 46))
	b3.pressed.connect(func(): main.show_howto())
	hb.add_child(b3)
	var b4 := UI.button("ESTADÍSTICAS", UI.PURPLE, 18, Vector2(225, 46))
	b4.pressed.connect(func(): main.show_stats())
	hb.add_child(b4)
	buttons.add_child(hb)

	var music := UI.button("Música: " + ("Sí" if Save.settings["music"] else "No"), UI.GRAY, 16)
	music.position = Vector2(16, 16)
	music.pressed.connect(func():
		Audio.set_music_enabled(not Save.settings["music"])
		music.text = "Música: " + ("Sí" if Save.settings["music"] else "No"))
	add_child(music)
	if not OS.has_feature("web") and not OS.has_feature("ios"):
		var quit := UI.button("Salir", UI.GRAY, 16)
		quit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		quit.position = Vector2(-90, 16)
		quit.pressed.connect(func(): get_tree().quit())
		add_child(quit)
	_say()


func _process(delta: float) -> void:
	_t += delta
	if _t > 3.5:
		_t = 0.0
		_say()


func _say() -> void:
	var i := randi() % Chars.LIST.size()
	var id: String = Chars.LIST[i]
	var key: String = ["taunt", "truco", "win_hand", "envido"][randi() % 4]
	_bubble.text = "%s: “%s”" % [Chars.get_data(id)["name"], Chars.line(id, key)]
	_portraits[i].talk(1.0)
	_portraits[i].bounce()
