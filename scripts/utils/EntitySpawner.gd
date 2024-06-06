class_name EntitySpawner
extends Node3D

@onready var playerScene = preload("res://scenes/characters/player.tscn");

@onready var GLOBAL_ENTITIES = {
	"jeep": preload("res://scenes/entities/vehicles/jeep_babycar.tscn"),
	"sportscar": preload("res://scenes/entities/vehicles/sportscar_babycar.tscn")
}

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
	
func _exit_tree():
	EntityManager.players.clear()
	EntityManager.entities.clear()

######
# Players
######

func onJoin():
	for MEMBERS in SteamLobbyManager.LOBBY_MEMBERS:
		var steam_id: int = MEMBERS['steam_id']
		if steam_id != SteamManager.STEAM_ID:
			spawnPlayer(steam_id)

func spawnPlayer(id: int):
	if EntityManager.players.has(id):
		print("Warning: Failed spawning "  + str(id) + " as they already exist")
		return
	var player = playerScene.instantiate()
	player.set_meta("steam_id", id)
	EntityManager.players[id] = player
	add_child(player)
	return player
	
func removePlayer(id: int):
	if not EntityManager.players.has(id):
		print('Player not in list')
		return
	remove_child(EntityManager.players[id])
	EntityManager.players[id].queue_free()
	EntityManager.players.erase(id);


######
# Entities
######

func _onPacket(sender: int, message: String, data: Dictionary):
	# If I am the host, handle the message
	if SteamLobbyManager.isHost():
		if message == "request_entities":
			notifyEntities(sender)
		return
	else:
		# if sender is not the host, ignore the message
		if sender != SteamLobbyManager.getHost():
			return 
		
		if message == "entities":
			receivedEntities(data)

func notifyEntities(steam_id: int):
	var data = {
		"entities": EntityManager.entities
	}
	SteamLobbyManager.sendPacket(steam_id, "entities", data)
	pass

func receivedEntities(_data: Dictionary):
	var data = _data["entities"]
	
	for key in data.keys():
		var entity = data[key]
		spawnEntity(entity["id"], entity["type"], entity["position"], entity["rotation"])
	pass

func spawnEntity(id: int, type: String, _position: Vector3, _rotation: Vector3):
	if not GLOBAL_ENTITIES.has(type):
		print("Warning: Entity type " + type + " does not exist")
		return

	# add if doesnt exist
	#if EntityManager.entityNodes.has(id):
		#EntityManager.entityNodes.erase(id)
	
	EntityManager.entities[id] = {
		"id": id,
		"type": type,
		"position": _position,
		"rotation": _rotation,
		"meta": {},
	}
	
	var scene = GLOBAL_ENTITIES[type]
	var entity = scene.instantiate()
	var ent = Utils.findNodeOfType(entity, Entity)
	ent.set_entity_id(id)
	entity.position = _position
	entity.rotation = _rotation
	EntityManager.entityNodes[id] = entity
	add_child(entity)
	

	if SteamLobbyManager.isHost():
		notifyEntities(0)
		print(EntityManager.entities)

	return
