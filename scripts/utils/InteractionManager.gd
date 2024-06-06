extends Node

var interactables = []

func _ready():
	pass

func add_interactable(interactable: Node):
	interactables.append(interactable)
	
func get_interactables():
	return interactables
