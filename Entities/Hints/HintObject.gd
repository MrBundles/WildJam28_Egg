extends Node2D

#exports
export var hint_id = 0
export var on_transition_duration = 1.0
export var off_transition_duration = 1.0
export var start_hidden = true


func _ready():
	#connect signals
	GlobalSignalManager.connect("show_hint", self, "_on_show_hint")
	GlobalSignalManager.connect("hide_hint", self, "_on_hide_hint")
	
	if start_hidden:
		get_parent().modulate = Color(1,1,1,0)
	else:
		get_parent().modulate = Color(1,1,1,1)


func _on_show_hint(show_hint_id):
	get_parent().show()
	if show_hint_id == hint_id:
		$Tween.interpolate_property(get_parent(), "modulate", get_parent().modulate, Color(1,1,1,1),
		on_transition_duration,Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		$Tween.start()


func _on_hide_hint(hide_hint_id):
	if hide_hint_id == hint_id:
		$Tween.interpolate_property(get_parent(), "modulate", get_parent().modulate, Color(1,1,1,0),
		off_transition_duration,Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		$Tween.start()
		yield($Tween, "tween_all_completed")
		get_parent().hide()
