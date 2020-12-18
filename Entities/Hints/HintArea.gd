tool
extends Area2D

#variables
var trigger_once_flag = false

#exports
export var hint_id = 0
export var hide_on_trigger = false
export var one_shot_trigger = false
export var trigger_once = false
export var hint_area_size = Vector2(100,100) setget _set_hint_area_size


func _set_hint_area_size(new_value):
	hint_area_size = new_value
	if has_node("CollisionShape2D"):
		$CollisionShape2D.shape.extents = hint_area_size


func _on_HintArea_body_entered(body):
	if body.is_in_group("Player") and not (trigger_once and trigger_once_flag):
		trigger_once_flag = true
		
		if hide_on_trigger:
			GlobalSignalManager.emit_signal("hide_hint", hint_id)
		else:
			GlobalSignalManager.emit_signal("show_hint", hint_id)


func _on_HintArea_body_exited(body):
	if body.is_in_group("Player") and not one_shot_trigger:
		if hide_on_trigger:
			GlobalSignalManager.emit_signal("show_hint", hint_id)
		else:
			GlobalSignalManager.emit_signal("hide_hint", hint_id)
