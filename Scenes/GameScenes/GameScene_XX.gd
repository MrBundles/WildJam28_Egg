extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("ui_select"):
		var transA = Transform2D(0.0, $APolygon2D.global_position)
		var transB = Transform2D(0.0, $BPolygon2D.global_position)
		$APolygon2D.polygon = transA.xform_inv(Geometry.clip_polygons_2d(transA.xform($APolygon2D.polygon), transB.xform($BPolygon2D.polygon))[0])
		$BPolygon2D.queue_free()
