extends StaticBody2D

#enums
enum TRIGGER_TYPES {tutorial_complete, level_complete}

#exports
export(TRIGGER_TYPES) var trigger_type = TRIGGER_TYPES.tutorial_complete

#variables
var player_present = false


func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		player_present = true
		$Timer.start()

func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		player_present = false
		$Timer.stop()


func _on_Timer_timeout():
	if trigger_type == TRIGGER_TYPES.tutorial_complete:
		GlobalSignalManager.emit_signal("tutorial_completed")

