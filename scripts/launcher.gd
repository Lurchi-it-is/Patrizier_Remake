extends Node

const MAIN_GAME_SCENE := "res://scenes/main_game.tscn"
const MAP_EDITOR_SCENE := "res://scenes/map_editor.tscn"

func _ready() -> void:
	_load_startup_scene.call_deferred()

func _load_startup_scene() -> void:
	var scene_path := MAIN_GAME_SCENE
	if OS.has_feature("map_editor"):
		scene_path = MAP_EDITOR_SCENE

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not load startup scene: %s" % scene_path)
