class_name PlayerSpawner
extends Node3D

@onready var playerScene = load("res://scenes/characters/player.tscn");

func _ready():
	spawnPlayer(SteamManager.STEAM_ID)
	onJoin()
	SteamLobbyManager.onPlayerJoined.connect(spawnPlayer)
	SteamLobbyManager.onPlayerLeft.connect(removePlayer)
	

func onJoin():
	for MEMBERS in SteamLobbyManager.LOBBY_MEMBERS:
		var steam_id: int = MEMBERS['steam_id']
		if steam_id != SteamManager.STEAM_ID:
			spawnPlayer(steam_id)

var players: Dictionary = {};

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
