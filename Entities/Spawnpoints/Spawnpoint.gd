extends Node2D

#exports
export(GlobalSceneManager.SPAWN_POINTS) var spawn_point = GlobalSceneManager.SPAWN_POINTS.init


func _ready():
	GlobalSignalManager.emit_signal("spawn_initialize", spawn_point, global_position)
