extends RigidBody2D

#variables
var fade_flag = false

#exports
export var polygon_points : PoolVector2Array = PoolVector2Array() setget _set_polygon_points
export var texture_polygon_texture : Texture = Texture.new() setget _set_texture_polygon_texture


func _process(delta):
	if not $Timer.is_stopped() and fade_flag:
		$TexturePolygon2D.color.a = $Timer.time_left / $Timer.wait_time


func _set_polygon_points(new_val):
	polygon_points = new_val
	$CollisionPolygon2D.polygon = polygon_points
	$TexturePolygon2D.polygon = polygon_points


func _set_texture_polygon_texture(new_val):
	texture_polygon_texture = new_val
	$TexturePolygon2D.texture = texture_polygon_texture
	
	# set offset offset to center on shard
	var texture_polygon_image = texture_polygon_texture.get_data()
	var texture_polygon_texture_offset = Vector2(texture_polygon_image.get_width() / 2, texture_polygon_image.get_height() / 2)
	$TexturePolygon2D.texture_offset = texture_polygon_texture_offset


func _on_Timer_timeout():
	if fade_flag:
		queue_free()
	else:
		fade_flag = true
		$Timer.start()
