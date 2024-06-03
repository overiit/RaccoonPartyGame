extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var readyPlayers = "";
	for member in SteamLobbyManager.LOBBY_MEMBERS:
		var isready = GameState.READY_PLAYERS.has(member['steam_id'])
		readyPlayers += "- " + str(member['steam_name']) + ": " + str(isready) + "\n"

	text = (
		"Debug: \n" +
		"State: " + str(GameState.sessionState) + "\n" +
		"Mode: " + str(GameState.mode) + "\n" +
		"timer: " + str(GameState.countdown) + "\n" +
		"Players\n" + readyPlayers
	)
	pass
