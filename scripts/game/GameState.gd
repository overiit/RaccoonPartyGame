extends Node

const LOBBY_TIME = 10.0;
const WARMUP_TIME = 10.0;

enum LobbyState {
	NONE = 0, # no lobby
	WAITING_FOR_PLAYERS = 1,
	INGAME = 2,
	END = 3,
}

# Global Game State
var STATE: LobbyState = LobbyState.NONE
var MODE = null
var countdown: float = 0

# Lobby
var READY_PLAYERS: Array = [];

func _ready():
	SteamLobbyManager.onLobbyCreated.connect(_onLobbyCreated)
	SteamLobbyManager.onLobbyJoined.connect(_onLobbyJoined)
	SteamLobbyManager.onLobbyUpdated.connect(_onLobbyUpdated)
	SteamLobbyManager.onCountdownChange.connect(_onCountdownChange)
	SteamLobbyManager.onPlayerReady.connect(_onPlayerReady)
	SteamLobbyManager.onPlayerUnready.connect(_onPlayerUnready)
	SteamLobbyManager.onPlayerLeft.connect(_onPlayerLeft)
	pass

func _process(delta):
	if SteamLobbyManager.LOBBY_ID > 0:
		if SteamLobbyManager.isHost():
			hostGameLoop(delta)

############
# Functions
############

func _handleStateChange():
	if STATE == LobbyState.WAITING_FOR_PLAYERS:
		print("Switching to lobby...")
		get_tree().change_scene_to_file("res://scenes/gamelobby.tscn")
	elif STATE == LobbyState.INGAME:
		if MODE == "test":
			print("Switching to test mode")
			get_tree().change_scene_to_file("res://scenes/testgamemode.tscn")
		else:
			print("gamemode unkown: " + str(MODE))
	else:
		print("state unknown: " + str(STATE))


func startRound():
	MODE = "test"
	STATE = LobbyState.INGAME
	READY_PLAYERS.clear()
	countdown = WARMUP_TIME
	pushGameState()
	_handleStateChange()
	pass

func sendCountdown():
	SteamLobbyManager.send_P2P_Packet(0, "countdown", {
		"time": countdown
	})

func hostGameLoop(delta):
	var lobby_size = SteamLobbyManager.LOBBY_MEMBERS.size()
	var ready_size = READY_PLAYERS.size()
	sendCountdown();
	
	if STATE == LobbyState.WAITING_FOR_PLAYERS:
		if lobby_size <= 1:
			pass
		if lobby_size == ready_size:
			# count down as all are ready
			countdown -= delta
		else:
			# reset to max timer
			countdown = LOBBY_TIME
		if countdown <= 0:
			startRound()
	elif STATE == LobbyState.INGAME:
		pass
	pass

	
###########
# UTILS
###########

func toggleReady():
	var isReady = READY_PLAYERS.has(SteamManager.STEAM_ID)
	if SteamLobbyManager.isHost():
		if !isReady:
			_onPlayerReady(SteamManager.STEAM_ID)
		else:
			_onPlayerUnready(SteamManager.STEAM_ID)
	else:
		if !isReady:
			SteamLobbyManager.send_P2P_Packet(0, "ready", {})
		else:
			SteamLobbyManager.send_P2P_Packet(0, "unready", {})

func backToLobby():
	STATE = LobbyState.WAITING_FOR_PLAYERS
	MODE = null
	READY_PLAYERS.clear()
	countdown = WARMUP_TIME
	pushGameState()

func pushGameState():
	setState("mode", MODE)
	setState("state", STATE)
	setState("ready", READY_PLAYERS)
	sendCountdown()

func isReady() -> bool:
	return READY_PLAYERS.has(SteamManager.STEAM_ID)

###########
# Events
###########

func _onCountdownChange(_countdown):
	countdown = _countdown

func _onLobbyJoined(lobby_id: int):
	# on join trigger fetching the state
	_onLobbyUpdated(lobby_id)

func _onPlayerReady(steam_id: int):
	if SteamLobbyManager.isHost():
		if not GameState.READY_PLAYERS.has(steam_id):
			GameState.READY_PLAYERS.append(steam_id)
			setState("ready", READY_PLAYERS)

func _onPlayerUnready(steam_id: int):
	if SteamLobbyManager.isHost():
		if GameState.READY_PLAYERS.has(steam_id):
			GameState.READY_PLAYERS.erase(steam_id)
			setState("ready", READY_PLAYERS)

func _onPlayerLeft(steam_id: int):
	if SteamLobbyManager.isHost():
		if GameState.READY_PLAYERS.has(steam_id):
			GameState.READY_PLAYERS.erase(steam_id)
			setState("ready", READY_PLAYERS)

func _onLobbyUpdated(_lobby_id: int):
	var _state = getData("state") as LobbyState
	var _mode = getData("mode")
	READY_PLAYERS.clear()
	READY_PLAYERS.assign(getData("ready"))
	var changed = STATE != _state
	STATE = _state
	MODE = _mode
	
	if changed:
		print("Lobby Updated: " + str(_state) + ", " + str(_mode))
		_handleStateChange()
	
func _onLobbyCreated(_lobby_id: int):
	STATE = LobbyState.WAITING_FOR_PLAYERS
	countdown = LOBBY_TIME
	READY_PLAYERS.clear()
	pushGameState()
	_handleStateChange()

###########
# CORE UTILS
###########
func setState(key: String, data: Variant):
	Steam.setLobbyData(SteamLobbyManager.LOBBY_ID, key, var_to_str(data))

func getData(key: String):
	return str_to_var(Steam.getLobbyData(SteamLobbyManager.LOBBY_ID, key));
