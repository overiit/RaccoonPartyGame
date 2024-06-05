extends Node

var interactables = []

func _ready():
	pass

func add_interactable(interactable):
	interactables.append(interactable)

func remove_interactable(interactable):
	interactables.erase(interactable)

func get_interactables():
	return interactables
