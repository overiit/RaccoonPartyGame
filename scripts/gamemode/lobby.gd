extends Node3D

@export var spawnPoint: Node3D

func _ready():
	SteamLobby.onPlayerConnected.connect(_onPlayerConnected)
	EntityManager.spawnPlayer(SteamAccount.STEAM_ID, spawnPoint.global_position)

func _process(_delta):
	if Input.is_action_just_pressed("ready_up"):
		GameState.toggleReady()
	if Input.is_action_just_pressed("ui_cancel"):
		SteamLobby.leave()

func _onPlayerConnected(id: int):
	EntityManager.spawnPlayer(id, spawnPoint.global_position)
