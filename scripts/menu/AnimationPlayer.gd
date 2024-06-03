extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	play("Cheering")
	get_animation(current_animation).loop_mode = Animation.LOOP_LINEAR;
	pass # Replace with function body.


func _on_animation_finished(_anim_name):
	#get_animation(_anim_name).loop_mode = Animation.LOOP_LINEAR
	pass # Replace with function body.
