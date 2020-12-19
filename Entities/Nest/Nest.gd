extends StaticBody2D

#enums
enum TRIGGER_TYPES {tutorial_complete, level_complete, start_level}

#exports
export(TRIGGER_TYPES) var trigger_type = TRIGGER_TYPES.tutorial_complete
export var level_id = 0    #only used for starting a level
export(GlobalSceneManager.SPAWN_POINTS) var spawn_point = GlobalSceneManager.SPAWN_POINTS.init

#variables
var player_present = false


func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		player_present = true
		$Timer.start()
		$Particles2D.emitting = true

func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		player_present = false
		$Timer.stop()
		$Particles2D.emitting = false


func _on_Timer_timeout():
	if trigger_type == TRIGGER_TYPES.tutorial_complete:
		GlobalSignalManager.emit_signal("tutorial_completed", spawn_point)
	elif trigger_type == TRIGGER_TYPES.level_complete:
		GlobalSignalManager.emit_signal("level_completed", spawn_point)
	elif trigger_type == TRIGGER_TYPES.start_level:
		GlobalSignalManager.emit_signal("start_level", level_id, spawn_point)
