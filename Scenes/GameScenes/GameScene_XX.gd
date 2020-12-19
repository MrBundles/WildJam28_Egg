extends Node2D

#exports
export var player_scene_path = ""


func _ready():
	GlobalSignalManager.connect("spawn_player", self, "_on_spawn_player")
	print("signal connected")


func _on_spawn_player(spawn_pos):
	print("spawning player")
	var player_instance = load(player_scene_path).instance()
	player_instance.global_position = spawn_pos
	add_child(player_instance)
