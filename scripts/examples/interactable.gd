extends Area3D

func _ready():
	InteractionManager.add_interactable(self)
	print("ADDED")

func interact():
	get_parent().position.y += 1
	print("interact: " + get_parent().name)

func _exit_tree():
	InteractionManager.remove_interactable(self)
