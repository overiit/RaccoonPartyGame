class_name VehicleSpawner
extends Node3D

@export var entitySpawner: EntitySpawner
@export_enum("any_vehicle", "jeep", "sportscar") var entity_to_spawn: String

func _ready():
	if SteamLobbyManager.isHost():
		entitySpawner.spawnEntity(str(get_instance_id()), entity_to_spawn, self.position, self.rotation)
	pass
