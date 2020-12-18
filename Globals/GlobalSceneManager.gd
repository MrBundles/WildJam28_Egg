extends Node

#variables
var tutorial_completed = false


func _ready():
	#connect signals
	GlobalSignalManager.connect("tutorial_completed", self, "_on_tutorial_completed")


func _on_tutorial_completed():
	tutorial_completed = true
	get_tree().reload_current_scene()
