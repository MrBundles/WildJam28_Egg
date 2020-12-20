extends Node

#enums
enum SPAWN_POINTS {init, tutorial, level_select}

#variables
var tutorial_completed = false
var jump_slo_mo = .7
var current_level_id = 0
var highest_completed_level_id = 0
var spawn_pos_array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

#exports
export(Array, String) var scene_path_array = []
export(SPAWN_POINTS) var current_spawn_point = SPAWN_POINTS.init


func _ready():
	#connect signals
	GlobalSignalManager.connect("tutorial_completed", self, "_on_tutorial_completed")
	GlobalSignalManager.connect("level_completed", self, "_on_level_completed")
	GlobalSignalManager.connect("start_level", self, "_on_start_level")
	GlobalSignalManager.connect("slo_mo_changed", self, "_on_slo_mo_changed")
	GlobalSignalManager.connect("spawn_initialize", self, "_on_spawn_initialize")


func _on_tutorial_completed(spawn_point):
	current_spawn_point = spawn_point
	tutorial_completed = true
	get_tree().reload_current_scene()


func _on_level_completed(level_id):
	if level_id >  highest_completed_level_id:
		highest_completed_level_id = level_id
	


func _on_start_level(level_id, spawn_point):
	if level_id <= scene_path_array.size() - 1:
		current_spawn_point = spawn_point
		get_tree().change_scene(scene_path_array[level_id])
		current_level_id = level_id
		get_tree().paused = false


func _on_slo_mo_changed(new_val):
	jump_slo_mo = new_val


func _on_spawn_initialize(spawn_point, spawn_position):
	spawn_pos_array[spawn_point] = spawn_position
	print("spawn point added")
	if not Vector2.ZERO in spawn_pos_array:
		GlobalSignalManager.emit_signal("spawn_player", spawn_pos_array[current_spawn_point])
		print("emitting signal")
