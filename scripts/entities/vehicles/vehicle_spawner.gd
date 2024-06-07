class_name VehicleSpawner
extends Node3D

@export var entitySpawner: EntitySpawner
@export_enum("any_vehicle", "jeep", "sportscar") var entity_to_spawn: String


func _ready():
	if SteamLobby.is_host():
		Utils.lastVehileId += 1
		entitySpawner.spawnEntity(Utils.lastVehileId, entity_to_spawn, self.position, self.rotation)
	pass
