extends Button

#exports
export(GlobalSceneManager.SPAWN_POINTS) var spawn_point = GlobalSceneManager.SPAWN_POINTS.init


func _process(delta):
	visible = GlobalSceneManager.tutorial_completed


func _on_SettingsButton_pressed():
	GlobalSignalManager.emit_signal("start_level", 0, spawn_point)
