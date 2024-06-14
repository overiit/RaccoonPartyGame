extends Node

## Maps: steam_id -> PlayerData
var players: Dictionary = {};
var entities: Dictionary = {}

@onready var PlayerScene = preload("res://scenes/characters/player.tscn");

@onready var GLOBAL_ENTITIES = {
	"jeep": preload("res://scenes/entities/vehicles/jeep_babycar.tscn"),
	"sportscar": preload("res://scenes/entities/vehicles/sportscar_babycar.tscn")
}

func _ready():
	SteamNetwork.onPacket.connect(_onPacket)

func refresh():
	if !SteamLobby.is_host():
		clear()
		SteamNetwork.sendPacket(SteamLobby.host_id, "request_entities", {})
		SteamNetwork.sendPacket(SteamLobby.host_id, "request_player", {})

func clear():
	for player in players.values():
		player.queue_free()
	players.clear()

	for entity in entities.values():
		entity.queue_free()
	entities.clear()

	if SteamLobby.is_host():
		notifyEntities(0)

func _onPacket(sender: int, message: String, data: Dictionary):
	# If I am the host, handle the message
	if SteamLobby.is_host():
		if message == "request_entities":
			notifyEntities(sender)
		elif message == "request_players":
			notifyPlayers(sender)
			pass
		return
	else:
		# if sender is not the host, ignore the message
		if sender != SteamLobby.host_id:
			return 
		
		if message == "spawn_entity":
			spawnEntity(data["id"], data["type"], data["position"], data["rotation"])
		elif message == "spawn_player":
			spawnPlayer(data["steam_id"], data["position"], data['rotY'])


######
# Players
######

func notifyPlayers(steam_id: int):
	for player in EntityManager.players.values():
		player.sendSpawnPacket(steam_id)
	pass

func spawnPlayer(id: int, position=null, rotY=null):
	if EntityManager.players.has(id):
		print("Warning: Failed spawning "  + str(id) + " as they already exist")
		return
	
	print("spawn player: " + str(id))
	var player = PlayerScene.instantiate() as Player
	player.set_authority(id)
	get_tree().root.add_child(player)
	if position != null:
		player.position = position
	
	if rotY != null:
		player.visual_char.rotation.y = rotY
		

func despawnPlayer(id: int):
	if not EntityManager.players.has(id):
		print("Warning: Failed despawning "  + str(id) + " as they do not exist")
		return
	EntityManager.players[id].queue_free()
	EntityManager.players.erase(id)


######
# Entities
######

func notifyEntities(steam_id: int):
	for entity in entities.values():
		entity.sendSpawnPacket(steam_id)

func receivedEntities(_data: Dictionary):
	var data = _data["entities"]
	
	for key in data.keys():
		var entity = data[key]
		spawnEntity(entity["id"], entity["type"], entity["position"], entity["rotation"])
	pass

func spawnEntity(id: int, type: String, _position: Vector3, _rotation: Vector3):
	if id == 0:
		if SteamLobby.is_host():
			id = Utils.genEntityId()
			print("Warning: Spawning entity with ID 0, generating new ID: " + str(id))
		else:
			print("Warning: Failed spawning "  + str(id) + " as the ID is invalid")
			return

	if not GLOBAL_ENTITIES.has(type):
		print("Warning: Entity type " + type + " does not exist")
		return

	var scene = GLOBAL_ENTITIES[type]

	# add if doesnt exist
	if entities.has(id):
		print("Warning: Failed spawning "  + str(id) + " as they already exist")
		return

	var instance = scene.instantiate()
	# entity might be a child of the instance
	var entity = Utils.findNodeOfType(instance, Entity)
	if entity == null:
		print("Warning: Failed spawning "  + str(id) + " as the entity does not exist")
		return
	entity.set_entity(id, type)
	get_tree().root.add_child(instance)
	print("spawn entity: " + str(id) + " type: " + type)
	entities[id] = entity
	instance.position = _position
	instance.rotation = _rotation
	

	if SteamLobby.is_host():
		notifyEntities(0)

	return
