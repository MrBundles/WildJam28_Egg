extends Button

#exports
export(GlobalSceneManager.SPAWN_POINTS) var spawn_point = GlobalSceneManager.SPAWN_POINTS.init
export var restart_button = false


func _process(delta):
	visible = GlobalSceneManager.tutorial_completed


func _on_SettingsButton_pressed():
	if restart_button:
		GlobalSignalManager.emit_signal("start_level", GlobalSceneManager.current_level_id, spawn_point)
	else:
		GlobalSignalManager.emit_signal("start_level", 0, spawn_point)
	$SettingsButtonClickASP.play()


func _on_SettingsButton_mouse_entered():
	$SettingsButtonHoverASP.play()
