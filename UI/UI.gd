extends CanvasLayer


func _ready():
	# connect signals
	GlobalSignalManager.connect("toggle_settings", self, "_on_toggle_settings")


func _on_toggle_settings():
	$SettingsMenu.visible = not $SettingsMenu.visible
	get_tree().paused = not get_tree().paused
