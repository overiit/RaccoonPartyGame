extends Node3D
class_name Entity

@onready var entity_id: int

var entity_type: String = ""

func _ready():
	pass

func set_entity_id(id: int):
	entity_id = id
