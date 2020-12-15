extends RigidBody2D

#rng
var rng = RandomNumberGenerator.new()

#exports
export var torque_force = 50
export var shard_randomize_factor = .1 #should be between 0 and .33
export var shard_length = 16
export var alpha_threshhold = .5

func _ready():
	rng.randomize()
	
	$CollisionPolygon2D.polygon = find_sprite_outline($Sprite.texture, shard_length)
	$ChickPolygon2D.polygon = $CollisionPolygon2D.polygon
	generate_shell($CollisionPolygon2D.polygon)
	

func _process(delta):
	#update labels
	$VelocityLabel.text = "Velocity: " + str(linear_velocity)


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
		var shard_texture = $Sprite.texture
		var shard_image = shard_texture.get_data()
		var shard_texture_offset = Vector2(shard_image.get_width() / 2, shard_image.get_height() / 2)
		shard.texture = shard_texture
		shard.texture_offset = shard_texture_offset
		
		$ShellPolygons.add_child(shard)


func _integrate_forces(state):
	if Input.is_action_pressed("ui_left"):
		apply_torque_impulse(-torque_force)
	if Input.is_action_pressed("ui_right"):
		apply_torque_impulse(torque_force)
	
	if Input.is_action_just_pressed("ui_select") and state.get_contact_count() > 0:
		#mode = MODE_KINEMATIC
		_break_shell(to_local(state.get_contact_collider_position(0)), 500)
		#mode = MODE_RIGID
	
	if state.get_contact_count() > 0:
		$ContactLabel.text = "Contact: " + str(state.get_contact_collider_position(0))
		$ContactSprite.global_position = state.get_contact_collider_position(0)
	

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
		print(polygons.size())
		polygons_to_remove.append(polygons[0])
		damage -= _get_polygon_area(polygons[0])
		polygons.remove(0)
	
	if polygons_to_remove.size() > 0:
		#create new rigidbody2d based on polygons in array for removal, as well as a collision and 2D polygon
		var shard_body = RigidBody2D.new()
		var shard_collision_polygon = CollisionPolygon2D.new()
		var shard_polygon = Polygon2D.new()
		
		#set polygon points to combined polygon outline
		shard_collision_polygon.polygon = _get_combined_polygon_outline(polygons_to_remove.duplicate())
		shard_polygon.polygon = shard_collision_polygon.polygon
		
		#update polygon2D's texture
		var shard_polygon_texture = $Sprite.texture
		var shard_polygon_image = shard_polygon_texture.get_data()
		var shard_polygon_texture_offset = Vector2(shard_polygon_image.get_width() / 2, shard_polygon_image.get_height() / 2)
		shard_polygon.texture = shard_polygon_texture
		shard_polygon.texture_offset = shard_polygon_texture_offset
		
		#cut shard shape out off egg collision shape
		#$CollisionPolygon2D.polygon = _get_clipped_polygon_outline($CollisionPolygon2D.duplicate(), shard_polygon.duplicate())
		
		#set shards collision layer to avoid colliding with egg
		shard_body.collision_layer = 0b0
		shard_body.collision_mask = 0b1
		
		#add egg shard as a child of the scene
		shard_body.add_child(shard_collision_polygon)
		shard_body.add_child(shard_polygon)
		#shard_body.global_position = global_position
		add_child(shard_body)
		
		
		#clear polygons to remove array
		for polygon in polygons_to_remove:
			polygon.queue_free()


func _get_clipped_polygon_outline(polygonA, polygonB) -> PoolVector2Array:
	var transA = Transform2D(0.0, polygonA.global_position)
	var transB = Transform2D(0.0, polygonB.global_position)
	polygonB.polygon = Geometry.offset_polygon_2d(polygonB.polygon, 0.2)[0]
	polygonA.polygon = transA.xform_inv(Geometry.clip_polygons_2d(transA.xform(polygonA.polygon), transB.xform(polygonB.polygon))[0])
	return polygonA.polygon


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


func _get_polygon_area(polygon : Polygon2D) -> float:
	var point_A = polygon.polygon[0]
	var point_B = polygon.polygon[1]
	var point_C = polygon.polygon[2]
	var area = abs((point_A.x * (point_B.y - point_C.y) + point_B.x * (point_C.y - point_A.y) + point_C.x * (point_A.y - point_B.y)) / 2)
	return area
