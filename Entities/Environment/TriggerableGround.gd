tool
extends Ground

#exports
export var trigger_area_height = 64 setget _set_trigger_area_height
export var time_duration : float = 1.0 setget _set_time_duration
export var hint_id = 50
export var level_id = 0

#variables
var player_present = false


func _ready():
	$TextureProgress/Label.text = str(level_id)


func _process(delta):
	if not $Timer.is_stopped():
		$TextureProgress.value = $Timer.time_left / $Timer.wait_time * 100
	else:
		$TextureProgress.value = $TextureProgress.max_value


func _set_size(new_val):
	size = new_val
	$CollisionShape2D.shape.extents = size / Vector2(2,2)
	$Sprite.scale = size / init_size
	$Area2D.position.y = -size.y / 2 - trigger_area_height / 2
	$Area2D/CollisionShape2D.shape.extents.x = size.x / 2

func _set_trigger_area_height(new_val):
	trigger_area_height = new_val
	$Area2D/CollisionShape2D.shape.extents.y = trigger_area_height / 2
	_set_size(size)


func _set_time_duration(new_val):
	time_duration = new_val
	if has_node("Timer"):
		$Timer.wait_time = time_duration


func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		player_present = true
		GlobalSignalManager.emit_signal("hide_hint", hint_id)
		$Timer.start()


func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		player_present = false
		GlobalSignalManager.emit_signal("show_hint", hint_id)
		$Timer.stop()


func _on_Timer_timeout():
	queue_free()
