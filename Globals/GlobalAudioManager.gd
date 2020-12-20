extends Node


func _ready():
	# connect signals
	GlobalSignalManager.connect("bus_mute_changed", self, "_on_bus_mute_changed")
	GlobalSignalManager.connect("bus_volume_changed", self, "_on_bus_volume_changed")
	GlobalSignalManager.connect("start_level", self, "_on_start_level")


func _on_bus_mute_changed(bus_id):
	var bus_muted = AudioServer.is_bus_mute(bus_id)
	AudioServer.set_bus_mute(bus_id, not bus_muted)


func _on_bus_volume_changed(bus_id, new_val):
	AudioServer.set_bus_volume_db(bus_id, new_val)


func _on_start_level(level_id, spawn_point):
	if level_id == GlobalSceneManager.scene_path_array.size() - 1:
		$MusicASP.playing = false
		if not $WinMusicASP.playing:
			$WinMusicASP.playing = true
	else:
		if not $MusicASP.playing:
			$MusicASP.playing = true
		$WinMusicASP.playing = false
