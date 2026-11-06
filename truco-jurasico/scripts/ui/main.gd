extends Control
## Raíz del juego: arma el tema y cambia entre pantallas.

const UI = preload("res://scripts/ui/ui_kit.gd")
const MenuScreen = preload("res://scripts/ui/menu_screen.gd")
const SetupScreen = preload("res://scripts/ui/setup_screen.gd")
const GameScreen = preload("res://scripts/ui/game_screen.gd")
const HowToScreen = preload("res://scripts/ui/howto_screen.gd")
const StatsScreen = preload("res://scripts/ui/stats_screen.gd")

var current: Control


func _ready() -> void:
	theme = UI.build_theme()
	show_menu()


func _swap(c: Control) -> void:
	if current:
		current.queue_free()
	current = c
	add_child(c)
	UI.full_rect(c)


func show_menu() -> void:
	var s := MenuScreen.new()
	s.main = self
	_swap(s)


func show_setup(mode: String) -> void:
	var s := SetupScreen.new()
	s.main = self
	s.mode = mode
	_swap(s)


func start_game(cfg: Dictionary) -> void:
	var s := GameScreen.new()
	s.main = self
	s.cfg = cfg
	_swap(s)


func show_howto() -> void:
	var s := HowToScreen.new()
	s.main = self
	_swap(s)


func show_stats() -> void:
	var s := StatsScreen.new()
	s.main = self
	_swap(s)
