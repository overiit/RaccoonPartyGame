class_name EntitySpawner
extends Node3D

@onready var playerScene = preload("res://scenes/characters/player.tscn");

var GLOBAL_ENTITIES = {
	"jeep": preload("res://scenes/entities/vehicles/jeep_babycar.tscn"),
	"sportscar": preload("res://scenes/entities/vehicles/sportscar_babycar.tscn")
}

var players: Dictionary = {};

var entities = []

func _ready():
	spawnPlayer(SteamManager.STEAM_ID)
	onJoin()
	SteamLobbyManager.onPlayerJoined.connect(spawnPlayer)
	SteamLobbyManager.onPlayerLeft.connect(removePlayer)

	SteamLobbyManager.onPacket.connect(_onPacket)
	if SteamLobbyManager.isHost():
		return
	else:
		SteamLobbyManager.sendPacket(SteamLobbyManager.getHost(), "request_entities", {})
	pass

######
# Players
######

func onJoin():
	for MEMBERS in SteamLobbyManager.LOBBY_MEMBERS:
		var steam_id: int = MEMBERS['steam_id']
		if steam_id != SteamManager.STEAM_ID:
			spawnPlayer(steam_id)

func spawnPlayer(id: int):
	if players.has(id):
		print("Warning: Failed spawning "  + str(id) + " as they already exist")
		return
	var player = playerScene.instantiate()
	player.set_meta("steam_id", id)
	players[id] = player
	add_child(player)
	return player
	
func removePlayer(id: int):
	if not players.has(id):
		print('Player not in list')
		return
	remove_child(players[id])
	players[id].queue_free()
	players.erase(id);


######
# Entities
######

func _onPacket(steam_id: int, message: String, data: Dictionary):
	# If I am the host, handle the message
	if SteamLobbyManager.isHost():
		if message == "request_entities":
			notifyEntities(steam_id)
		return
	else:
		# if sender is not the host, ignore the message
		if steam_id != SteamLobbyManager.getHost():
			return 
		
		if message == "notify_entities":
			receivedEntities(data)

func notifyEntities(steam_id: int):
	var data = {
		"entities": entities
	}
	SteamLobbyManager.sendPacket(steam_id, "notify_entities", data)
	pass

func receivedEntities(_data: Dictionary):
	var data = _data["entities"]
	for entity in data:
		spawnEntity(entity["id"], entity["type"], entity["position"], entity["rotation"])
	pass

func spawnEntity(id: String, type: String, _position: Vector3, _rotation: Vector3):
	if not GLOBAL_ENTITIES.has(type):
		print("Warning: Entity type " + type + " does not exist")
		return
	var scene = GLOBAL_ENTITIES[type]
	scene.set_meta("entity_id", id)
	var entity = scene.instance()
	entity.position = _position
	entity.rotation = _rotation

	# TODO: set rotation

	# check if entity already exists
	for e in entities:
		if e["id"] == id:
			return 

	entities.append({
		"id": id,
		"type": type,
		"position": position,
		"rotation": rotation
	})

	add_child(entity)

	if SteamLobbyManager.isHost():
		notifyEntities(0)

	return
