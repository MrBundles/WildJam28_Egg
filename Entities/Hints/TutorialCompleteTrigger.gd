extends Area2D


func _on_TutorialCompleteTrigger_body_entered(body):
	if body.is_in_group("Player"):
		GlobalSceneManager.tutorial_completed = true
