extends RigidBody2D

#rng
var rng = RandomNumberGenerator.new()

#exports
export var egg_texture : Texture = Texture.new()
export var chick_texture : Texture = Texture.new()
export var torque_force = 50
export var shard_randomize_factor = .1 #should be between 0 and .33
export var shard_length = 16
export var alpha_threshhold = .5

func _ready():	
	rng.randomize()
	
	$CollisionPolygon2D.polygon = find_sprite_outline(egg_texture, 10)
	$ChickPolygon2D.polygon = $CollisionPolygon2D.polygon
	generate_shell($CollisionPolygon2D.polygon)
	

func _integrate_forces(state):
	if state.get_contact_count() > 0:
		if Input.is_action_pressed("ui_left"):
			apply_torque_impulse(-torque_force)
		if Input.is_action_pressed("ui_right"):
			apply_torque_impulse(torque_force)
	
	if Input.is_action_just_pressed("ui_select") and state.get_contact_count() > 0:
		_break_shell(to_local(state.get_contact_collider_position(0)), 500)


# trace outline of given texture and return array of points for polygon generation
func find_sprite_outline(texture, point_resolution) -> PoolVector2Array:
	var outline_image = texture.get_data()
	var outline_image_offset = Vector2(-outline_image.get_width() / 2, -outline_image.get_height() / 2)
	outline_image.lock()
	var outline_texture = ImageTexture.new()
	
	var outline_points_right = PoolVector2Array()
	var outline_points_left = PoolVector2Array()
	
	for y in range(outline_image.get_height()):
		var pixel_detected = false
		for x in range(outline_image.get_width()):
			if y % int(point_resolution) == 0 or y < 3 or y > outline_image.get_height() - 3:
				if outline_image.get_pixel(x,y).a == 1:
					if not pixel_detected:
						outline_points_left.append(Vector2(x,y) + outline_image_offset)
						outline_image.set_pixel(x,y,Color(1,0,0,1))
						pixel_detected = true
					else:
						outline_image.set_pixel(x,y,Color(0,0,0,0))
				else:
					if pixel_detected:
						outline_points_right.append(Vector2(x,y) + outline_image_offset)
						outline_image.set_pixel(x,y,Color(1,0,0,1))
						pixel_detected = false
					else:
						outline_image.set_pixel(x,y,Color(0,0,0,0))
			else:
				outline_image.set_pixel(x,y,Color(0,0,0,0))
					
	outline_image.unlock()
	outline_texture.create_from_image(outline_image)
	$OutlineSprite.texture = outline_texture
	
	outline_points_left.invert()
	var outline_points = outline_points_right + outline_points_left
	
	return outline_points


# generate collision and texture polygons based on generated sprite outline points from above
func generate_shell(points : PoolVector2Array):
	for i in range(len(points)):
		var point_interpolate_count = int(points[i].distance_to(Vector2.ZERO) / shard_length)
		for j in range(point_interpolate_count):
			if j <= rng.randi_range(0, point_interpolate_count):
				points.append(points[i].linear_interpolate(Vector2.ZERO, 1.0/point_interpolate_count * (j+1)))
	
	#add center point to points array
	points.append(Vector2.ZERO)
	
	var delaunay_points = Geometry.triangulate_delaunay_2d(points)
	
	for i in range(len(delaunay_points) / 3):
		var shard_points = PoolVector2Array()
		for j in range(3):
			shard_points.append(points[delaunay_points[i*3 + j]])
		
		var shard = Polygon2D.new()
		shard.polygon = shard_points
		#shard.color = Color(randf(),randf(),randf(),1)
		var shard_texture = egg_texture
		var shard_image = shard_texture.get_data()
		var shard_texture_offset = Vector2(shard_image.get_width() / 2, shard_image.get_height() / 2)
		shard.texture = shard_texture
		shard.texture_offset = shard_texture_offset
		
		$ShellPolygons.add_child(shard)


# apply break to shell and remove shell fragment from player object
func _break_shell(collider_position : Vector2, damage : float):
	var polygon_scores = []
	var polygons = []
	
	#score all polygons
	for polygon in $ShellPolygons.get_children():
		var current_polygon_score = 0
		for point in polygon.polygon:
			current_polygon_score += point.distance_to(collider_position)
		
		polygon_scores.append(current_polygon_score)
		polygons.append(polygon)
	
	#sort polygon score array
	polygon_scores.sort()
	
	#sort polygons based on score
	for polygon in $ShellPolygons.get_children():
		var current_polygon_score = 0
		for point in polygon.polygon:
			current_polygon_score += point.distance_to(collider_position)
		
		polygons[polygon_scores.find(current_polygon_score)] = polygon
	
	#remove closest polygons from polygon array and add to array for removal
	var polygons_to_remove = []
	while damage > 0 and polygons.size() > 0:
		polygons_to_remove.append(polygons[0])
		damage -= _get_polygon_area(polygons[0])
		polygons.remove(0)
	
	if polygons_to_remove.size() > 0:
	
		# create a new shard instance and populate shard data
		var shard_instance = preload("res://Entities/Characters/Player/Shard/Shard.tscn").instance()
		shard_instance.polygon_points = _get_combined_polygon_outline(polygons_to_remove.duplicate())
		shard_instance.texture_polygon_texture = egg_texture
		shard_instance.global_position = global_position + shard_instance.position
		shard_instance.global_rotation = global_rotation
		get_tree().root.add_child(shard_instance)
		
		
		#clear polygons to remove array
		for polygon in polygons_to_remove:
			polygon.queue_free()


# takes in a list of polygons and returns the points of a single combined polygon
func _get_combined_polygon_outline(polygons) -> PoolVector2Array:
	while polygons.size() > 1:
		
		var polygon_to_add = null
		for i in range(1, polygons.size()):
			if polygon_to_add == null:
				for point_i in polygons[i].polygon:
					for point_j in polygons[0].polygon:
						if point_i.distance_to(point_j) < 1:
							polygon_to_add = polygons[i]
		
		if polygon_to_add != null:
			var transA = Transform2D(0.0, polygons[0].global_position)
			var transB = Transform2D(0.0, polygon_to_add.global_position)
			if Geometry.offset_polygon_2d(polygon_to_add.polygon, 0.01).size() > 0:
				polygon_to_add.polygon = Geometry.offset_polygon_2d(polygon_to_add.polygon, 0.01)[0]
			if Geometry.merge_polygons_2d(transA.xform(polygons[0].polygon), transB.xform(polygon_to_add.polygon)).size() > 0:
				polygons[0].polygon = transA.xform_inv(Geometry.merge_polygons_2d(transA.xform(polygons[0].polygon), transB.xform(polygon_to_add.polygon))[0])
			polygons.remove(1)
		else:
			break
		
	return polygons[0].polygon


# returns the area of a given triangle
func _get_polygon_area(polygon : Polygon2D) -> float:
	var point_A = polygon.polygon[0]
	var point_B = polygon.polygon[1]
	var point_C = polygon.polygon[2]
	var area = abs((point_A.x * (point_B.y - point_C.y) + point_B.x * (point_C.y - point_A.y) + point_C.x * (point_A.y - point_B.y)) / 2)
	return area
