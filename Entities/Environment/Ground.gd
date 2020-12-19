tool
extends StaticBody2D
class_name Ground


#exports
export var size = Vector2(64,64) setget _set_size
export(Color) var color = Color(1,1,1,1) setget _set_color

#variables
var init_size = size


func _ready():
	_set_size(size)
	_set_color(color)


func _set_size(new_val):
	size = new_val
	$CollisionShape2D.shape.extents = size / Vector2(2,2)
	$Sprite.scale = size / init_size


func _set_color(new_val):
	color = new_val
	$Sprite.modulate = color
