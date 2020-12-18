extends NinePatchRect

#exports
export var hint_id = 0
export var transition_duration = 1.0
export var start_hidden = true
export var hint_message = ""


func _ready():
	#connect signals
	GlobalSignalManager.connect("show_hint", self, "_on_show_hint")
	GlobalSignalManager.connect("hide_hint", self, "_on_hide_hint")
	
	$Label.text = hint_message
	
	if start_hidden:
		modulate = Color(1,1,1,0)
	else:
		modulate = Color(1,1,1,1)


func _on_show_hint(show_hint_id):
	if show_hint_id == hint_id:
		$Tween.interpolate_property(self, "modulate", modulate, Color(1,1,1,1),
		transition_duration,Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		$Tween.start()


func _on_hide_hint(hide_hint_id):
	if hide_hint_id == hint_id:
		$Tween.interpolate_property(self, "modulate", modulate, Color(1,1,1,0),
		transition_duration,Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		$Tween.start()
