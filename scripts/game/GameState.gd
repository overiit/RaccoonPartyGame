extends Node

const LOBBY_TIME = 1.0;
const WARMUP_TIME = 10.0;

const k_session_state = "session_state";
const k_gamemode = "gamemode"
const k_ready_players = "ready_players"
const k_countdown = "countdown"

enum SessionState {
	NONE = 0, # no lobby
	WAITING_FOR_PLAYERS = 1,
	INGAME = 2,
	END = 3,
}

# Global Game State
var sessionState: SessionState = SessionState.NONE
var mode = null
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

func _process(delta):
	if SteamLobbyManager.LOBBY_ID > 0:
		if SteamLobbyManager.isHost():
			hostGameLoop(delta)

############
# Functions
############

func _handleStateChange():
	if sessionState == SessionState.WAITING_FOR_PLAYERS:
		print("Switching to lobby...")
		get_tree().change_scene_to_file("res://scenes/gamelobby.tscn")
	elif sessionState == SessionState.INGAME:
		if mode == "test":
			print("Switching to test mode")
			get_tree().change_scene_to_file("res://scenes/testgamemode.tscn")
		elif mode == "race":
			print("Switching to race mode")
			get_tree().change_scene_to_file("res://scenes/gamemode/race.tscn")
		else:
			print("gamemode unkown: " + str(mode))
	else:
		print("state unknown: " + str(sessionState))


func startRound():
	sessionState = SessionState.INGAME
	mode = "race"
	READY_PLAYERS.clear()
	countdown = WARMUP_TIME
	pushGameState()
	_handleStateChange()

func sendCountdown():
	SteamLobbyManager.send_P2P_Packet(0, k_countdown, {
		"time": countdown
	})

func hostGameLoop(delta):
	var lobby_size = SteamLobbyManager.LOBBY_MEMBERS.size()
	var ready_size = READY_PLAYERS.size()
	sendCountdown();
	
	if sessionState == SessionState.WAITING_FOR_PLAYERS:
		if lobby_size <= 0: # change this so 1 person cant play alone
			return
		if lobby_size == ready_size:
			# count down as all are ready
			countdown -= delta
		else:
			# reset to max timer
			countdown = LOBBY_TIME
		if countdown <= 0:
			startRound()
	elif sessionState == SessionState.INGAME:
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
	sessionState = SessionState.WAITING_FOR_PLAYERS
	mode = null
	READY_PLAYERS.clear()
	countdown = WARMUP_TIME
	pushGameState()

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
	if !SteamLobbyManager.isHost():
		return

	if sessionState == SessionState.WAITING_FOR_PLAYERS:
		if not GameState.READY_PLAYERS.has(steam_id):
			GameState.READY_PLAYERS.append(steam_id)
			setState(k_ready_players, READY_PLAYERS)

func _onPlayerUnready(steam_id: int):
	if SteamLobbyManager.isHost():
		if GameState.READY_PLAYERS.has(steam_id):
			GameState.READY_PLAYERS.erase(steam_id)
			setState(k_ready_players, READY_PLAYERS)

func _onPlayerLeft(steam_id: int):
	if SteamLobbyManager.isHost():
		if GameState.READY_PLAYERS.has(steam_id):
			GameState.READY_PLAYERS.erase(steam_id)
			setState(k_ready_players, READY_PLAYERS)

func _onLobbyUpdated(_lobby_id: int):
	var _sessionState = getData(k_session_state) as SessionState
	var _mode = getData(k_gamemode)
	var _readyPlayers = getData(k_ready_players);
	
	var changed = sessionState != _sessionState || mode != _mode
	
	READY_PLAYERS.clear()
	READY_PLAYERS.assign(_readyPlayers)
	
	sessionState = _sessionState
	mode = _mode
	
	if changed:
		print("Lobby Updated: " + str(_sessionState) + ", " + str(_mode))
		_handleStateChange()
	
func _onLobbyCreated(_lobby_id: int):
	sessionState = SessionState.WAITING_FOR_PLAYERS
	countdown = LOBBY_TIME
	READY_PLAYERS.clear()
	pushGameState()
	_handleStateChange()

###########
# CORE UTILS
###########

func pushGameState():
	setState(k_session_state, sessionState)
	setState(k_gamemode, mode)
	setState(k_ready_players, READY_PLAYERS)
	sendCountdown()

func setState(key: String, data: Variant):
	Steam.setLobbyData(SteamLobbyManager.LOBBY_ID, key, var_to_str(data))

func getData(key: String):
	return str_to_var(Steam.getLobbyData(SteamLobbyManager.LOBBY_ID, key));
