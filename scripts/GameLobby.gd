extends Node3D


func _process(delta):
	if Input.is_action_just_pressed("ready_up"):
		GameState.toggleReady()
