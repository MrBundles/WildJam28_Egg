extends RigidBody2D

#rng
var rng = RandomNumberGenerator.new()

#exports
export(Array, AudioStream) var chick_land_asp_array
export(Array, AudioStream) var egg_crack_asp_array
export(Array, AudioStream) var egg_tap_asp_array
export(Array, AudioStream) var jump_whoosh_asp_array
export(Array, AudioStream) var bird_tweet_asp_array

export var egg_texture : Texture = Texture.new()
export var chick_texture : Texture = Texture.new()
export var torque_force_grounded = 50
export var torque_force_ungrounded = 50
export var shard_randomize_factor = .1 #should be between 0 and .33
export var shard_length = 16
export var damage_threshhold = 500
export var tap_threshhold = 250
export var leg_max_y : float = 65
export var wing_max_rotation : float = 95
export var leg_accel : float = 7.5
export var max_jump_force : float = 2000
export var jump_force_accel : float = 8
export var jump_force_decel : float = 50
export var path_projectile_spread : float = .5
export(Curve) var path_projectile_curve
export(Curve) var camera_zoom_curve
export var camera_zoom_smoothing = .1
export var world_speed : float = 1 setget _set_world_speed

#variables
var jump_force : float = 0
var jump_force_decreasing : bool = false
var previous_velocity : float = 0
var current_collision_pos = Vector2.ZERO
var path_projectile_spread_count : float = path_projectile_spread
onready var camera_zoom_current = $Camera2D.zoom.x
var camera_zoom_target = 0


func _ready():
	#connect signals
	GlobalSignalManager.connect("spawn_player", self, "_on_spawn_player")
	print("connecting signal")
	
	rng.randomize()
	
	$CollisionPolygon2D.polygon = find_sprite_outline(egg_texture, 12)
	$ChickPolygon2D.polygon = $CollisionPolygon2D.polygon
	generate_shell($CollisionPolygon2D.polygon)


func _process(delta):
	$Legs/LegSprite2.position.y = clamp($Legs/LegSprite.position.y - 52, 0, 1000)
	
	#camera_zoom_smoothing *= delta
	var camera_zoom_current = $Camera2D.zoom.x
	var camera_zoom_target = camera_zoom_curve.interpolate(previous_velocity / damage_threshhold)
	var camera_zoom_smoothed = camera_zoom_current + clamp(camera_zoom_target - camera_zoom_current, -camera_zoom_smoothing, camera_zoom_smoothing)
	$Camera2D.zoom = Vector2(camera_zoom_smoothed, camera_zoom_smoothed)


func _physics_process(delta):
	if $ShellPolygons.get_child_count() < 1:
		if path_projectile_spread_count > path_projectile_spread:
			var path_projectile_instance = preload("res://Entities/Characters/Player/PathProjectile/PathProjectile.tscn").instance()
			path_projectile_instance.global_position = global_position
			path_projectile_instance.global_rotation = global_rotation
			path_projectile_instance.max_alpha = path_projectile_curve.interpolate(previous_velocity / damage_threshhold)
			get_tree().root.add_child(path_projectile_instance)
			path_projectile_spread_count = 0
		else:
			path_projectile_spread_count += delta


func _integrate_forces(state):
	current_collision_pos = state.get_contact_collider_position(0)
	
	if state.get_contact_count() > 0:
		$CoyoteTimer.start()
	
	if state.get_contact_count() > 0 and $TapTimer.is_stopped() and previous_velocity > tap_threshhold:
		$TapTimer.start()
		if $ShellPolygons.get_child_count() > 0:
			_on_egg_tap()
		else:
			_on_chick_land()
	
	if state.get_contact_count() > 0 and previous_velocity > damage_threshhold:
		while $ShellPolygons.get_child_count() > 0:
			_break_shell(state.get_contact_collider_position(0), 750)
			_on_egg_crack()
			yield(get_tree(),"physics_frame")
	previous_velocity = linear_velocity.length()
	
	if Input.is_action_pressed("ui_left"):
		if state.get_contact_count() > 0:
			apply_torque_impulse(-torque_force_grounded)
		else:
			apply_torque_impulse(-torque_force_ungrounded)
	if Input.is_action_pressed("ui_right"):
		if state.get_contact_count() > 0:
			apply_torque_impulse(torque_force_grounded)
		else:
			apply_torque_impulse(torque_force_ungrounded)
	if Input.is_action_pressed("ui_up") and not $CoyoteTimer.is_stopped():
		if jump_force_decreasing:
			jump_force = clamp(jump_force - jump_force_accel, 0, max_jump_force)
			if jump_force == 0:
				jump_force_decreasing = false
		else:
			jump_force = clamp(jump_force + jump_force_accel, 0, max_jump_force)
			if jump_force == max_jump_force:
				jump_force_decreasing = true
	else:
		jump_force_decreasing = false
		jump_force = clamp(jump_force - jump_force_decel, 0, max_jump_force)
	
	if Input.is_action_pressed("ui_up") and not $CoyoteTimer.is_stopped() and $ShellPolygons.get_child_count() < 1:
		Engine.time_scale = 1 - GlobalSceneManager.jump_slo_mo
	else:
		Engine.time_scale = world_speed
	
	if Input.is_action_just_released("ui_up") and not $CoyoteTimer.is_stopped() and $ShellPolygons.get_child_count() < 1:
		_on_jump_whoosh()
		$CoyoteTimer.stop()
		apply_central_impulse(Vector2(0,-jump_force).rotated(rotation))
		$Legs/LegTween.interpolate_property($Legs/LegSprite, "position:y", $Legs/LegSprite.position.y, jump_force / max_jump_force * leg_max_y, .1, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Legs/LegTween.start()
		yield($Legs/LegTween, "tween_all_completed")
		$Legs/LegTween.interpolate_property($Legs/LegSprite, "position:y", $Legs/LegSprite.position.y, 0, .5, Tween.TRANS_QUAD, Tween.EASE_OUT)
		$Legs/LegTween.start()
	
	if $ShellPolygons.get_child_count() < 1:
		$Wings/RightWing.rotation_degrees = (jump_force / max_jump_force) * -wing_max_rotation
		$Wings/LeftWing.rotation_degrees = (jump_force / max_jump_force) * wing_max_rotation
	else:
		$Wings/RightWing.rotation_degrees = 0
		$Wings/LeftWing.rotation_degrees = 0


func _on_spawn_player(spawn_pos):
	global_position = spawn_pos


func _set_world_speed(new_val):
	world_speed = new_val
	Engine.time_scale = world_speed


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
	
	#sort polygons based on score
	var polygons = $ShellPolygons.get_children().duplicate()
	polygons.sort_custom(self, "sort_polyscore")
	
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


# sorts two given polygons based on the average distance of their vertices to a given point
func sort_polyscore(poly_a, poly_b) -> bool:
	var poly_a_score = 0
	var poly_b_score = 0
	
	for i in range(3):
		poly_a_score += poly_a.polygon[i].distance_to(current_collision_pos)
		poly_b_score += poly_b.polygon[i].distance_to(current_collision_pos)
	
	return poly_a_score < poly_b_score


# takes in a list of polygons and returns the points of a single combined polygon
func _get_combined_polygon_outline(polygons) -> PoolVector2Array:
	while polygons.size() > 1:
		
		var polygon_to_add = null
		for i in range(1, polygons.size()):
			if polygon_to_add == null:
				for point_i in polygons[i].polygon:
					if polygon_to_add == null:
						for point_j in polygons[0].polygon:
							if point_i.distance_to(point_j) < 1 and polygon_to_add == null:
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


func _on_chick_land():
	$ASPs/ChickLandASP.stream = chick_land_asp_array[rng.randi_range(0,chick_land_asp_array.size()-1)]
	$ASPs/ChickLandASP.pitch_scale = 1 + rng.randf_range(-.5,.5)
	var min_land_vol = -20
	$ASPs/ChickLandASP.volume_db = clamp(min_land_vol + (previous_velocity / damage_threshhold) * -min_land_vol, min_land_vol, 0)
	if not $ASPs/ChickLandASP.playing:
		$ASPs/ChickLandASP.play()
		if previous_velocity > damage_threshhold or rng.randi_range(0,5) == 1:
			_on_tweet($ASPs/ChickLandASP.volume_db)


func _on_egg_crack():
	$ASPs/EggCrack1ASP.stream = egg_crack_asp_array[rng.randi_range(0,egg_crack_asp_array.size()-1)]
	$ASPs/EggCrack2ASP.stream = egg_crack_asp_array[rng.randi_range(0,egg_crack_asp_array.size()-1)]
	$ASPs/EggCrack3ASP.stream = egg_crack_asp_array[rng.randi_range(0,egg_crack_asp_array.size()-1)]
	$ASPs/EggCrack4ASP.stream = egg_crack_asp_array[rng.randi_range(0,egg_crack_asp_array.size()-1)]
	$ASPs/EggCrack1ASP.play()
	$ASPs/EggCrack2ASP.play()
	$ASPs/EggCrack3ASP.play()
	$ASPs/EggCrack4ASP.play()


func _on_egg_tap():
	$ASPs/EggTapASP.stream = egg_tap_asp_array[rng.randi_range(0,egg_tap_asp_array.size()-1)]
	$ASPs/EggTapASP.pitch_scale = 1 + rng.randf_range(-.5,.5)
	var min_tap_vol = -20
	$ASPs/EggTapASP.volume_db = clamp(min_tap_vol + (previous_velocity / damage_threshhold) * -min_tap_vol, min_tap_vol, 0)
	if not $ASPs/EggTapASP.playing:
		$ASPs/EggTapASP.play()


func _on_jump_whoosh():
	$ASPs/JumpWhooshASP.stream = jump_whoosh_asp_array[rng.randi_range(0,jump_whoosh_asp_array.size()-1)]
	$ASPs/JumpWhooshASP.pitch_scale = 1 + rng.randf_range(-.5,.5)
	var min_whoosh_vol = -30
	$ASPs/JumpWhooshASP.volume_db = min_whoosh_vol + (jump_force / max_jump_force) * -min_whoosh_vol
	$ASPs/JumpWhooshASP.play()


func _on_tweet(tweet_vol):
	if not $ASPs/TweetASP.playing:
		$ASPs/TweetASP.stream = bird_tweet_asp_array[rng.randi_range(0,bird_tweet_asp_array.size()-1)]
		$ASPs/TweetASP.volume_db = clamp(tweet_vol, -80, 0)
		$ASPs/TweetASP.play()


func _on_TapTimer_timeout():
	$TapTimer.stop()
