extends Node

const LOBBY_MAX_MEMBERS: int = 8

var lobby_id: int = 0
var host_id: int = 0
var members: Array = []
var is_ready = false

var MenuScene = preload("res://scenes/ui/menu.tscn")
var ConnectingScene = preload("res://scenes/ui/connecting.tscn")

# # general
signal onHostChanged(to_steam_id: int)

# # lobby
signal onLobbyCreated(lobby_id: int)
signal onLobbyJoined(lobby_id: int)
signal onLobbyConnected(lobby_id: int)
signal onLobbyUpdated(lobby_id: int)
signal onLobbyLeft(lobby_id: int)
signal onLobbyReady(lobby_id: int)

# player
signal onPlayerLobbyJoined(steam_id: int)
signal onPlayerConnected(steam_id: int)
signal onPlayerLobbyLeft(steam_id: int)
## run 
signal onPlayerKicked(steam_id: int, ban: bool)

# # player lobby
# signal onPlayerReady(steam_id: int)
# signal onPlayerUnready(steam_id: int)

# # generic game
# signal onCountdownChange(time: float)

func _ready():
	Steam.lobby_created.connect(_onLobbyCreated)
	Steam.lobby_joined.connect(_onLobbyJoined)
	Steam.lobby_chat_update.connect(_onLobbyChatUpdate)
	
	SteamNetwork.onP2PConnected.connect(_onP2PConnected)

	Steam.lobby_data_update.connect(_onLobbyDataUpdate)
	Steam.join_requested.connect(_onLobbyInvite)
	Steam.persona_state_change.connect(_onPersonaChange)

	# Check for command line arguments
	_check_Command_Line()

func _check_Command_Line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()

	if ARGUMENTS.size() > 0:
		if ARGUMENTS[0] == "+connect_lobby":
			if int(ARGUMENTS[1]) > 0:
				join(int(ARGUMENTS[1]))

func _process(_delta):
	if lobby_id > 0:
		# Get the host of the lobby
		# TODO: Optimize this to only run on lobby update?
		var new_host_id: int = Steam.getLobbyOwner(lobby_id)
		if new_host_id != host_id:
			host_id = new_host_id
			onHostChanged.emit(host_id)

func is_host():
	return host_id == SteamAccount.STEAM_ID;

func create() -> void:
	if lobby_id > 0:
		leave(false)
	
	print("Creating a lobby...")

	clearLobbySession()
	
	get_tree().change_scene_to_packed(ConnectingScene)

	members.clear()

	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, LOBBY_MAX_MEMBERS)

func join(_lobby_id: int) -> void:
	if lobby_id > 0:
		leave(false)

	print("Attempting to join lobby "+str(_lobby_id)+"...")
	
	get_tree().change_scene_to_packed(ConnectingScene)
	clearLobbySession()
	
	Steam.joinLobby(_lobby_id)

func leave(backToMenu: bool=true) -> void:
	if lobby_id > 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		onLobbyLeft.emit(lobby_id)
		clearLobbySession()
		if backToMenu:
			get_tree().change_scene_to_packed(MenuScene)


func clearLobbySession():
	SteamNetwork.clearP2PConnections()
	members.clear()
	lobby_id = 0
	is_ready = false

func _onLobbyCreated(_connect: int, _lobby_id: int) -> void:
	if _connect == 1:
		# Set the lobby ID
		lobby_id = _lobby_id

		print("Created a lobby: "+str(lobby_id))
		
		onLobbyCreated.emit(lobby_id)
		
		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)
		
		# Allow P2P connections to fallback to being relayed through Steam if needed
		Steam.allowP2PPacketRelay(true)
		
		is_ready = true
		onLobbyReady.emit(lobby_id)

func _onP2PConnected(steam_id: int):
	if is_ready:
		return
	print('checking p2p connected')
	
	var memberCount = SteamLobby.members.size()
	var connected = 0
	for member in members:
		if member['steam_id'] == SteamAccount.STEAM_ID:
			memberCount -= 1
		if SteamNetwork.isP2PConnected(member['steam_id']):
			connected += 1
	is_ready = connected == memberCount
	
	if is_ready:
		SteamNetwork.sendPacket(host_id, "connected")
		onLobbyReady.emit(lobby_id)


func _onLobbyJoined(_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == 1:
		# Set this lobby ID as your lobby ID
		lobby_id = _lobby_id

		# Get the lobby members
		_getLobbyMembers()

		# Make the initial handshake
		SteamNetwork.sendHandshake()
		# alert everywhere you joined a lobby
		onLobbyJoined.emit(lobby_id)
	# Else it failed for some reason
	else:
		# Get the failure reason
		var FAIL_REASON: String

		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."

		# Display the failure reason
		print("Failed to join lobby: "+str(FAIL_REASON))


func _onLobbyInvite(_lobby_id: int, _owner_steam_id: int):
	join(_lobby_id)

func _onLobbyDataUpdate(_idk: int, _lobby_id: int, _success: bool) -> void:
	if lobby_id != _lobby_id:
		return
	
	print("Lobby data updated: "+str(_success))
	_getLobbyMembers()
	onLobbyUpdated.emit(lobby_id)

func _getLobbyMembers() -> void:
	members.clear()

	var member_count: int = Steam.getNumLobbyMembers(lobby_id)
	
	for MEMBER in range(0, member_count):
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(lobby_id, MEMBER)
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		members.append({
			"steam_id": MEMBER_STEAM_ID, 
			"steam_name": MEMBER_STEAM_NAME,
			"connected": SteamLobby.host_id == MEMBER_STEAM_ID
		}) 

func hasMember(steam_id: int) -> bool:
	for member in members:
		if member['steam_id'] == steam_id:
			return true
	return false

# A user's information has changed
func _onPersonaChange(steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	#k_EPersonaChangeName	0x0001	
	#k_EPersonaChangeStatus	0x0002	
	#k_EPersonaChangeComeOnline	0x0004	
	#k_EPersonaChangeGoneOffline	0x0008	
	#k_EPersonaChangeGamePlayed	0x0010	
	#k_EPersonaChangeGameServer	0x0020	
	#k_EPersonaChangeAvatar	0x0040	
	#k_EPersonaChangeJoinedSource	0x0080	
	#k_EPersonaChangeLeftSource	0x0100	
	#k_EPersonaChangeRelationshipChanged	0x0200	
	#k_EPersonaChangeNameFirstSet	0x0400	
	#k_EPersonaChangeFacebookInfo	0x0800	
	#k_EPersonaChangeNickname	0x1000	
	#k_EPersonaChangeSteamLevel	0x2000
	if lobby_id > 0 and hasMember(steam_id):
		print("[STEAM] A user ("+str(steam_id)+") had information change, update the lobby list")
		
		# Update the player list
		_getLobbyMembers()

func _onLobbyChatUpdate(_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == 1:
		print(str(CHANGER)+" has joined the lobby.")
		onPlayerLobbyJoined.emit(change_id)

	# Else if a player has left the lobby
	elif chat_state == 2:
		_getLobbyMembers()
		print(str(CHANGER)+" has left the lobby.")
		Steam.closeP2PSessionWithUser(change_id)
		onPlayerLobbyLeft.emit(change_id)

	# Else if a player has been kicked
	elif chat_state == 8:
		print(str(CHANGER)+" has been kicked from the lobby.")
		onPlayerLobbyLeft.emit(change_id)
		onPlayerKicked.emit(change_id, false);

	# Else if a player has been banned
	elif chat_state == 16:
		print(str(CHANGER)+" has been banned from the lobby.")
		onPlayerLobbyLeft.emit(change_id)
		onPlayerKicked.emit(change_id, true);

	# Else there was some unknown change
	else:
		print(str(CHANGER)+" did... something.")

	# Update the lobby now that a change has occurred
	_getLobbyMembers()

func _leave_Lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0

		# Close session with all users
		for member in members:
			# Make sure this isn't your Steam ID
			if member['steam_id'] != SteamAccount.STEAM_ID:
				# Close the P2P member
				Steam.closeP2PSessionWithUser(member['steam_id'])

		# Clear the local lobby list
		members.clear()

	
# func _handlePacket(steam_id: int, message: String, data: Dictionary):
# 	if message == "handshake":
# 		print("handshake from: " + str(steam_id));
# 		SteamLobby.onPlayerJoined.emit(steam_id)
# 	elif message == "ready":
# 		print("Ready from: " + str(steam_id))
# 		onPlayerReady.emit(steam_id)
# 	elif message == "unready":
# 		print("Unready from: " + str(steam_id))
# 		onPlayerUnready.emit(steam_id)
# 	elif message == "countdown":
# 		onCountdownChange.emit(data['time'])
# 	elif message == 'pos':
# 		pass
# 	elif message == "entity_move":
# 		pass
# 	else:
# 		print("Packet " + message + ": "+str(data))
