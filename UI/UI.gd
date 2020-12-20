extends CanvasLayer

#exports
export var is_final_scene = false


func _ready():
	# connect signals
	GlobalSignalManager.connect("toggle_settings", self, "_on_toggle_settings")
	
	if is_final_scene:
		$Particles2D.emitting = true
		$Particles2D2.emitting = true


func _process(delta):
	$Back.visible = get_tree().paused
	$Settings.visible = not get_tree().paused


func _on_toggle_settings():
	$SettingsMenu.visible = not $SettingsMenu.visible
	get_tree().paused = not get_tree().paused
