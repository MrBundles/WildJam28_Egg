extends Node2D


func _ready():
	if GlobalSceneManager.tutorial_completed:
		$WrongWay.text = "Right Way"
		$WrongWayHint.show()
	else:
		$WrongWay.text = "Wrong Way"
		$WrongWayHint.hide()
