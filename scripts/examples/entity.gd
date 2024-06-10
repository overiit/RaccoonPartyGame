extends Node3D
class_name Entity

@export var auto_spawn: bool = false
@export_enum(
	"jeep", "sportscar"
) var entity_type: String

@onready var entity_id: int


func _init():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready():
	if auto_spawn:
		set_entity(Utils.genEntityId(), entity_type)
	if SteamLobby.is_host():
		sendSpawnPacket()
	pass

func set_entity(id: int, type: String):
	entity_id = id
	entity_type = type
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	EntityManager.entities[id] = self

func sendSpawnPacket(to: int = 0):
	SteamNetwork.sendPacket(to, "spawn_entity", {
		"id": entity_id,
		"type": entity_type,
		"position": position,
		"rotation": rotation
	})