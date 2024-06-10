class_name Gamemode
extends Node

signal onGameModeReady(steam_id: int)

func _ready():
	SteamNetwork.onPacket.connect(_onPacket)
	if SteamLobby.is_host():
		onGameModeReady.emit(SteamAccount.STEAM_ID)
	else:
		SteamNetwork.sendPacket(SteamLobby.host_id, "gamemode_ready")
		onGameModeReady.emit(SteamAccount.STEAM_ID)

func _onPacket(steam_id: int, message: String, _data: Dictionary):
	if message == "gamemode_ready":
		onGameModeReady.emit(steam_id)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		SteamLobby.leave()
		return
	
	if SteamLobby.is_host():
		process_host(delta)
	else:
		process_client(delta)
	process_player(delta)

## This is the process for the host
func process_host(delta: float):
	pass

## This is the process for the client
func process_client(delta: float):
	pass

## This is the process for everyone processed after the host and client
func process_player(delta: float):
	pass
