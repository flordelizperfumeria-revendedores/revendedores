extends SceneTree
## Prueba de humo de la interfaz: navega pantallas y juega partidas completas
## tocando cartas/botones como lo haría una persona. Saca capturas.
##   xvfb-run godot --path . --rendering-driver opengl3 --script res://tests/ui_smoke.gd -- <carpeta>

const Match = preload("res://scripts/core/truco_match.gd")

var out_dir := "user://shots"
var main
var shots := 0
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	rng.seed = 5
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out_dir, shots, name])
	shots += 1


func wait(s: float) -> void:
	await create_timer(s).timeout


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await wait(1.5)
	await shot("menu")
	main.show_setup("ai")
	await wait(0.6)
	await shot("setup")
	main.show_howto()
	await wait(0.4)
	await shot("howto")
	main.show_stats()
	await wait(0.3)
	await shot("stats")
	var ok_matches := 0
	for game_i in 3:
		var cfg := {"mode": "ai", "chars": [["cirilo", "yanina", "rex"][game_i], ["rex", "cirilo", "yanina"][game_i]],
			"target": 15, "flor": game_i == 1, "difficulty": game_i, "hints": true}
		main.start_game(cfg)
		Engine.time_scale = 1.0 if game_i == 0 else 4.0
		var res: bool = await play_game(game_i, 1500.0)
		if res:
			ok_matches += 1
	# Dos jugadores: debe aparecer la pantalla de pasar el dispositivo.
	Engine.time_scale = 1.0
	main.start_game({"mode": "pvp", "chars": ["yanina", "cirilo"], "target": 15, "flor": false, "difficulty": 1, "hints": true})
	await wait(2.5)
	var g = main.current
	await shot("pvp_handoff")
	var handoff_ok: bool = g.overlay != null and not g.revealed
	print("UI_RESULT matches_completed=%d/3 pvp_handoff=%s" % [ok_matches, handoff_ok])
	quit(0 if ok_matches == 3 and handoff_ok else 1)


func play_game(idx: int, max_seconds: float) -> bool:
	var g = main.current
	var t0 := Time.get_ticks_msec()
	var took_table := false
	var took_call := false
	var took_hand := false
	var actions := 0
	while (Time.get_ticks_msec() - t0) / 1000.0 < max_seconds / Engine.time_scale + 60:
		await wait(0.15)
		if g.m.is_over() and not g.busy:
			if idx == 0:
				await wait(0.8)
				await shot("match_end")
			print("partida %d terminada: %s en %d acciones humanas" % [idx, str(g.m.scores), actions])
			return true
		if g.overlay != null and g.m.phase == Match.Phase.HAND_OVER and not g.busy:
			if idx == 0 and not took_hand:
				took_hand = true
				await shot("hand_over")
			g._close_overlay()
			g.m.next_hand()
			g._queue_events()
			continue
		if idx == 0 and not took_call and g.banner.visible:
			took_call = true
			await shot("call_banner")
		if g.human_turn and not g.busy:
			var legal: Array = g.m.legal_actions(0)
			if legal.is_empty():
				continue
			if idx == 0 and not took_table and g.m.bazas.size() == 2:
				took_table = true
				await shot("table")
			var a: Dictionary = legal[rng.randi_range(0, legal.size() - 1)]
			if a["type"] == "mazo" and rng.randf() < 0.9:
				continue
			actions += 1
			if a["type"] == "play":
				g._on_card_pressed(a["card"])
			else:
				g._on_action(a["type"])
	print("partida %d NO terminó: fase %d actor %d busy %s" % [idx, g.m.phase, g.m.actor, g.busy])
	await shot("stuck_%d" % idx)
	return false
