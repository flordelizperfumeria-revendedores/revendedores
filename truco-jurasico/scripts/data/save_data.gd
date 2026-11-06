extends Node
## Autoload "Save": opciones y estadísticas guardadas en user://save.json
## (funciona offline en todas las plataformas).

const PATH := "user://save.json"

var settings := {
	"music": true, "sfx": true, "hints": true,
	"target": 30, "flor": false, "difficulty": 1,
	"p0": "cirilo", "p1": "rex",
}

var stats := {
	"played": 0, "won": 0, "lost": 0, "streak": 0, "best_streak": 0,
	"hands_won": 0, "hands_lost": 0, "trucos_called": 0, "envidos_won": 0,
	"flores": 0, "vs": {},
}


func _ready() -> void:
	load_data()


func load_data() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed.get("settings", {}):
			settings[k] = parsed["settings"][k]
		for k in parsed.get("stats", {}):
			stats[k] = parsed["stats"][k]
	# JSON devuelve floats: normalizar enteros.
	for k in ["target", "difficulty"]:
		settings[k] = int(settings[k])
	for k in stats:
		if stats[k] is float:
			stats[k] = int(stats[k])


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"settings": settings, "stats": stats}, "\t"))


func add(key: String, amount: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


func record_match(won: bool, opponent_id: String) -> void:
	add("played")
	if won:
		add("won")
		stats["streak"] = int(stats["streak"]) + 1
		stats["best_streak"] = maxi(int(stats["best_streak"]), int(stats["streak"]))
	else:
		add("lost")
		stats["streak"] = 0
	var vs: Dictionary = stats.get("vs", {})
	var rec: Dictionary = vs.get(opponent_id, {"won": 0, "lost": 0})
	rec["won"] = int(rec["won"]) + (1 if won else 0)
	rec["lost"] = int(rec["lost"]) + (0 if won else 1)
	vs[opponent_id] = rec
	stats["vs"] = vs
	save()
