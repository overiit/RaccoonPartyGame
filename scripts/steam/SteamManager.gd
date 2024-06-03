extends Node

const STEAM_APP_ID: int = 2968740;

var IS_ONLINE: bool = false
var IS_OWNED: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = "You"
var IS_ON_STEAM_DECK: bool = false

func _ready():
	_initialize_Steam()

	# if IS_ON_STEAM_DECK:
		# full screen
		# OS.setWindowFullscreen(true)

func _initialize_Steam() -> void:
	var INIT = Steam.steamInit(true, STEAM_APP_ID)
	Steam.restartAppIfNecessary(STEAM_APP_ID);

	print("Did Steam initialize?: " + str(INIT))

	if INIT['status'] != 1:
		print("Failed to initialize Steam. " + str(INIT['verbal']) + " Shutting down...")
		get_tree().quit()
	
	IS_ONLINE = Steam.loggedOn()
	IS_OWNED = Steam.isSubscribed()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	IS_ON_STEAM_DECK = Steam.isSteamRunningOnSteamDeck()
	
	print(("ONLINE" if IS_ONLINE else "OFFLINE") + ", " + str(STEAM_ID) + ", " + STEAM_USERNAME)
	
	if IS_OWNED == false:
		print("User does not own this game")
		get_tree().quit()
