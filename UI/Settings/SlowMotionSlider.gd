extends HBoxContainer


func _ready():
	$HSlider.value = GlobalSceneManager.jump_slo_mo


func _on_HSlider_value_changed(value):
	GlobalSignalManager.emit_signal("slo_mo_changed", value)
