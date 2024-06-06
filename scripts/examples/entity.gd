extends Node3D
class_name Entity

@export var entity_id: int

func get_entity_id() -> int:
	if has_meta("entity_id"):
		return get_meta("entity_id")
	return 0

func _ready():
	if entity_id > 0:
		set_meta("entity_id", entity_id)
