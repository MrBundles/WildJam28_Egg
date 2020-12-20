extends Node2D

#exports
export var rotation_speed = 1
export var rotation_dir = 1      # 1 or -1
export(Texture) var pause_texture = Texture.new()
export(Texture) var unpause_texture = Texture.new()

#variables
var mouse_present = false


func _process(delta):	
	if mouse_present:
		rotation_degrees += rotation_speed * delta * rotation_dir
	if get_tree().paused:
		$SettingsButton.texture_normal = pause_texture
	else:
		$SettingsButton.texture_normal = unpause_texture


func _on_SettingsButton_mouse_entered():
	mouse_present = true
	GlobalSignalManager.emit_signal("show_hint", -1)
	$SettingsButtonHoverASP.play()


func _on_SettingsButton_mouse_exited():
	mouse_present = false
	GlobalSignalManager.emit_signal("hide_hint", -1)


func _on_SettingsButton_pressed():
	GlobalSignalManager.emit_signal("toggle_settings")
	$SettingsButtonClickASP.play()
