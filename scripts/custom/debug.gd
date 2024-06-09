extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var readyPlayers = "";
	for member in SteamLobby.members:
		var steam_id = member['steam_id']
		var isready = GameState.READY_PLAYERS.has(steam_id)
		readyPlayers += "- " + str(member['steam_name']) + " (" + str(steam_id) + "): \n"
		readyPlayers += "  " +  "Ready: " + str(isready) + "\n"
		readyPlayers += "  " +  "Connected: " + str(SteamNetwork.isP2PConnected(steam_id)) + "\n"
		
		readyPlayers += "\n"

	text = (
		"Debug: \n" +
		"State: " + str(GameState.sessionState) + "\n" +
		"Mode: " + str(GameState.mode) + "\n" +
		"timer: " + str(GameState.countdown) + "\n" +
		"Players\n" + readyPlayers
	)
