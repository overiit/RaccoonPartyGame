extends Node

var interactables = []

func _ready():
	pass

func add_interactable(interactable: Node):
	interactables.append(interactable)
	interactable.child_exiting_tree.connect(_onExit)
	
func _onExit(interactable: Node):
	interactables.erase(interactable)

func get_interactables():
	return interactables
