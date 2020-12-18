extends Node


func _ready():
	# connect signals
	GlobalSignalManager.connect("bus_mute_changed", self, "_on_bus_mute_changed")
	GlobalSignalManager.connect("bus_volume_changed", self, "_on_bus_volume_changed")
	
	$MusicASP.play()


func _on_bus_mute_changed(bus_id):
	var bus_muted = AudioServer.is_bus_mute(bus_id)
	AudioServer.set_bus_mute(bus_id, not bus_muted)


func _on_bus_volume_changed(bus_id, new_val):
	AudioServer.set_bus_volume_db(bus_id, new_val)
