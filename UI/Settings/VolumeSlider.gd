tool
extends HBoxContainer

#exports
export var label_string = "" setget _set_label_string
export var bus_id = 0


func _ready():
	_set_label_string(label_string)


func _set_label_string(new_val):
	label_string = new_val
	if has_node("Label"):
		$Label.text = label_string


func _process(delta):
	if has_node("Button"):
		if AudioServer.is_bus_mute(bus_id):
			$Button.text = "Unmute"
		else:
			$Button.text = "Mute"


func _on_HSlider_value_changed(value):
	GlobalSignalManager.emit_signal("bus_volume_changed", bus_id, value)


func _on_Button_pressed():
	GlobalSignalManager.emit_signal("bus_mute_changed", bus_id)
