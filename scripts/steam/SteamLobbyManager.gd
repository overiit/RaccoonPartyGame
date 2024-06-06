extends Node

const PACKET_READ_LIMIT: int = 32

var LOBBY_ID: int = 0

var LOBBY_MEMBERS: Array = []

var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 16

var ConnectingScene = preload("res://scenes/ui/connecting.tscn")

# general
signal onPacket(steam_id: int, message: String, data: Dictionary)
# TODO signal onHostChanged(to_steam_id: int)

# lobby
signal onLobbyCreated(lobby_id: int)
signal onLobbyJoined(lobby_id: int)
signal onLobbyUpdated(lobby_id: int)

# player
signal onPlayerConnected(player_id: int)
signal onPlayerJoined(player_id: int)
signal onPlayerLeft(player_id: int)
signal onPlayerKicked(player_id: int, ban: bool)

# player lobby
signal onPlayerReady(steam_id: int)
signal onPlayerUnready(steam_id: int)

# generic game
signal onCountdownChange(time: float)

const COMPRESSION_GZIP = 3 # File.COMPRESSION_GZIP

func _ready():
	Steam.lobby_created.connect(_on_Lobby_Created)
	Steam.lobby_joined.connect(_on_Lobby_Joined)
	Steam.lobby_chat_update.connect(_on_Lobby_Chat_Update)
	Steam.lobby_data_update.connect(_on_Lobby_Data_Update)
	Steam.join_requested.connect(_on_Lobby_Join_Requested)
	Steam.persona_state_change.connect(_on_Persona_Change)
	Steam.p2p_session_request.connect(_on_P2P_Session_Request)
	Steam.p2p_session_connect_fail.connect(_on_P2P_Session_Connect_Fail)

	# Check for command line arguments
	_check_Command_Line()

func _process(_delta):
	Steam.run_callbacks()

	# If the player is connected, read packets
	if LOBBY_ID > 0:
		_read_P2P_Packet()

func _check_Command_Line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()

	# There are arguments to process
	if ARGUMENTS.size() > 0:

		# A Steam connection argument exists
		if ARGUMENTS[0] == "+connect_lobby":

			# Lobby invite exists so try to connect to it
			if int(ARGUMENTS[1]) > 0:
				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("CMD Line Lobby ID: " + str(ARGUMENTS[1]))
				joinLobby(int(ARGUMENTS[1]))

func createLobby() -> void:
	# Make sure a lobby is not already set
	if LOBBY_ID == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, LOBBY_MAX_MEMBERS)

func _on_Lobby_Created(_connect: int, lobby_id: int) -> void:
	if _connect == 1:
		# Set the lobby ID
		LOBBY_ID = lobby_id

		print("Created a lobby: "+str(LOBBY_ID))
		
		onLobbyCreated.emit(LOBBY_ID)
		
		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(LOBBY_ID, true)

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var RELAY: bool = Steam.allowP2PPacketRelay(false)

		print("Allowing Steam to be relay backup: "+str(RELAY))

func joinLobby(lobby_id: int) -> void:
	if LOBBY_ID > 0:
		Steam.leaveLobby(LOBBY_ID)

	print("Attempting to join lobby "+str(lobby_id)+"...")
	
	get_tree().change_scene_to_packed(ConnectingScene)
	
	# Clear any previous lobby members lists, if you were in a previous lobby
	LOBBY_MEMBERS.clear()
	
	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)

func getHost() -> int:
	if LOBBY_ID > 0:
		return Steam.getLobbyOwner(LOBBY_ID)
	return 0;

func isHost():
	return getHost() == SteamManager.STEAM_ID;


func _on_Lobby_Joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == 1:
		# Set this lobby ID as your lobby ID
		LOBBY_ID = lobby_id

		# Get the lobby members
		_get_Lobby_Members()

		# Make the initial handshake
		_make_P2P_Handshake()
		
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

func _on_Lobby_Data_Update(_idk: int, lobby_id: int, _success: bool) -> void:
	# If this is your lobby
	if lobby_id == LOBBY_ID:
		# Update the lobby members list
		_get_Lobby_Members()
		onLobbyUpdated.emit(lobby_id)

func _get_Lobby_Members() -> void:
	# Clear your previous lobby list
	LOBBY_MEMBERS.clear()

	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(LOBBY_ID)
	
	# Get the data of these players from Steam
	for MEMBER in range(0, MEMBERS):
		# Get the member's Steam ID
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(LOBBY_ID, MEMBER)

		# Get the member's Steam name
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)

		# Add them to the list
		LOBBY_MEMBERS.append({
			"steam_id":MEMBER_STEAM_ID, 
			"steam_name":MEMBER_STEAM_NAME
		})

# A user's information has changed
func _on_Persona_Change(steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	print(str(steam_id) +": " +str(_flag))
	if LOBBY_ID > 0:
		print("[STEAM] A user ("+str(steam_id)+") had information change, update the lobby list")
		
		# Update the player list
		_get_Lobby_Members()
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

func _make_P2P_Handshake() -> void:
	print("Sending P2P handshake to the lobby")

	sendPacket(0, "handshake", {})

func _on_Lobby_Join_Requested(lobby_id: int, owner_steam_id: int):
	print("A user has requested to join your lobby.")
	var owner_name: String = Steam.getFriendPersonaName(owner_steam_id)
	
	print("Joining %s's lobby..." % owner_name)
	
	joinLobby(lobby_id)

func _on_Lobby_Chat_Update(_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == 1:
		print(str(CHANGER)+" has joined the lobby.")
		onPlayerConnected.emit(change_id)

	# Else if a player has left the lobby
	elif chat_state == 2:
		print(str(CHANGER)+" has left the lobby.")
		onPlayerLeft.emit(change_id)

	# Else if a player has been kicked
	elif chat_state == 8:
		print(str(CHANGER)+" has been kicked from the lobby.")
		onPlayerLeft.emit(change_id)
		onPlayerKicked.emit(change_id, false);

	# Else if a player has been banned
	elif chat_state == 16:
		print(str(CHANGER)+" has been banned from the lobby.")
		onPlayerLeft.emit(change_id)
		onPlayerKicked.emit(change_id, true);

	# Else there was some unknown change
	else:
		print(str(CHANGER)+" did... something.")

	# Update the lobby now that a change has occurred
	_get_Lobby_Members()

func _leave_Lobby() -> void:
	# If in a lobby, leave it
	if LOBBY_ID != 0:
		# Send leave request to Steam
		Steam.leaveLobby(LOBBY_ID)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		LOBBY_ID = 0

		# Close session with all users
		for MEMBERS in LOBBY_MEMBERS:
			# Make sure this isn't your Steam ID
			if MEMBERS['steam_id'] != SteamManager.STEAM_ID:
				# Close the P2P session
				Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])

		# Clear the local lobby list
		LOBBY_MEMBERS.clear()

# p2p
func _on_P2P_Session_Request(remote_id: int) -> void:
	# Get the requester's name
	var REQUESTER: String = Steam.getFriendPersonaName(remote_id)
	
	print("Connection request: " + REQUESTER);

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	_make_P2P_Handshake()

func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)
		
		if PACKET.is_empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")
		
		# Get the remote user's ID
		var from: int = PACKET['remote_steam_id']

		# Make the packet data readable
		var PACKET_CODE: PackedByteArray = PACKET['data']
		# Decompress the array before turning it into a useable dictionary
		var PACKET_DATA: Dictionary = bytes_to_var(PACKET_CODE)

		# Print the packet to output
		var message: String = PACKET_DATA['message']

		_handlePacket(from, message, PACKET_DATA['data'])
		
		# read more packets
		_read_P2P_Packet()

func _handlePacket(steam_id: int, message: String, data: Dictionary):
	if message == "handshake":
		print("handshake from: " + str(steam_id));
		onPlayerJoined.emit(steam_id)
	elif message == "ready":
		print("Ready from: " + str(steam_id))
		onPlayerReady.emit(steam_id)
	elif message == "unready":
		print("Unready from: " + str(steam_id))
		onPlayerUnready.emit(steam_id)
	elif message == "countdown":
		onCountdownChange.emit(data['time'])
	elif message == 'pos':
		pass
	elif message == "entity_move":
		pass
	else:
		print("Packet " + message + ": "+str(data))
		
	onPacket.emit(steam_id, message, data)

func sendPacket(target: int, message: String, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0

	# Create a data array to send the data through
	var DATA: PackedByteArray = []
	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var COMPRESSED_DATA: PackedByteArray = var_to_bytes({
		"message": message,
		"data": packet_data,
	})
	DATA.append_array(COMPRESSED_DATA)
	
	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in LOBBY_MEMBERS:
				if MEMBER['steam_id'] != SteamManager.STEAM_ID:
					Steam.sendP2PPacket(MEMBER['steam_id'], DATA, SEND_TYPE, CHANNEL)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)

func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with "+str(steamID)+" [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with "+str(steamID)+" [target user not running the same game].")

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with "+str(steamID)+" [local user doesn't own app / game].")

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with "+str(steamID)+" [target user isn't connected to Steam].")

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with "+str(steamID)+" [connection timed out].")

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with "+str(steamID)+" [unused].")

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")
