extends Control
## Estadísticas del jugador (partidas contra la máquina).

const UI = preload("res://scripts/ui/ui_kit.gd")
const Scenery = preload("res://scripts/ui/scenery.gd")
const Chars = preload("res://scripts/data/characters.gd")

var main


func _ready() -> void:
	var sc := Scenery.new()
	sc.show_table = false
	add_child(sc)
	UI.full_rect(sc)
	var center := CenterContainer.new()
	add_child(center)
	UI.full_rect(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(UI.title("ESTADÍSTICAS", 42))
	var s: Dictionary = Save.stats
	var played := int(s["played"])
	var pct := (100.0 * int(s["won"]) / played) if played > 0 else 0.0
	var rows := [
		["Partidas jugadas", str(played)],
		["Ganadas / perdidas", "%d / %d  (%.0f%%)" % [int(s["won"]), int(s["lost"]), pct]],
		["Racha actual / mejor racha", "%d / %d" % [int(s["streak"]), int(s["best_streak"])]],
		["Manos ganadas / perdidas", "%d / %d" % [int(s["hands_won"]), int(s["hands_lost"])]],
		["Trucos cantados", str(int(s["trucos_called"]))],
		["Envidos ganados", str(int(s["envidos_won"]))],
		["Flores cantadas", str(int(s["flores"]))],
	]
	var vs: Dictionary = s.get("vs", {})
	for id in Chars.LIST:
		var rec: Dictionary = vs.get(id, {"won": 0, "lost": 0})
		rows.append(["Contra " + Chars.get_data(id)["name"], "%d G · %d P" % [int(rec["won"]), int(rec["lost"])]])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for r in rows:
		grid.add_child(UI.label(r[0], 19, UI.GOLD))
		grid.add_child(UI.label(r[1], 19))
	var back := UI.button("Volver al menú", UI.GRAY, 20)
	back.pressed.connect(func(): main.show_menu())
	v.add_child(back)
