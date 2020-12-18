extends Sprite

#variables
var life_time = 1
var max_alpha = .1


func _ready():
	$LifeTimer.wait_time = life_time


func _process(delta):
	modulate = Color(1,1,1,clamp($LifeTimer.time_left / $LifeTimer.wait_time * max_alpha, 0, max_alpha))


func _on_LifeTimer_timeout():
	queue_free()
