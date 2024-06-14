class_name VehicleSpawner
extends Node3D

@export_enum("jeep", "sportscar") var entity_to_spawn: String

func _ready():
	if SteamLobby.is_host():
		EntityManager.spawnEntity(0, entity_to_spawn, self.position, self.rotation)
	pass
