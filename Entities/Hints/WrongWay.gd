extends Node2D


func _process(delta):
	$WrongWay.visible = not GlobalSceneManager.tutorial_completed
	$RightWay.visible = GlobalSceneManager.tutorial_completed
	$WrongWayHint.visible = GlobalSceneManager.tutorial_completed
