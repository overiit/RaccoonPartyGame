extends Node

const PACKET_READ_LIMIT: int = 32
const COMPRESSION_GZIP = 3 # File.COMPRESSION_GZIP
const CHANNEL: int = 0

var _p2pConnections = {}

enum HandshakeState {
	FAILED = -1,
	INITIAL = 0,
	RESPONSE = 1,
	CONFIRMED = 2,
}

signal onPacket(from_id: int, message: String, data: Dictionary)
signal onHandshake(from_id: int, state: HandshakeState)
signal onP2PConnected(steam_id: int)

func getP2PSteamIds():
	return _p2pConnections.keys()

func getP2PConnection(steam_id: int):
	if _p2pConnections.has(steam_id):
		return _p2pConnections[steam_id]
	
func isP2PConnected(steam_id: int):
	var connection = getP2PConnection(steam_id)
	if connection:
		if connection['connected']:
			if connection['handshake'] == HandshakeState.CONFIRMED:
				return true
	return false

func clearP2PConnections():
	for steam_id in _p2pConnections.keys():
		Steam.closeP2PSessionWithUser(steam_id)
	_p2pConnections.clear()
		

func _ready():
	Steam.p2p_session_request.connect(_onSessionRequest)
	Steam.p2p_session_connect_fail.connect(onSessionConnectFailure)
	SteamLobby.onPlayerLobbyLeft.connect(_onPlayerLobbyLeft)
	
func _process(_delta):
	Steam.run_callbacks()

	# If the player is in a lobby, read packets
	if SteamLobby.lobby_id > 0:
		_readP2PPackets()

func sendPacket(target: int, message: String, packet_data: Dictionary = {}, queue: bool = false, send_type: int = Steam.P2P_SEND_RELIABLE) -> void:
	var DATA: PackedByteArray = []
	
	var COMPRESSED_DATA: PackedByteArray = var_to_bytes([message, packet_data]).compress(FileAccess.COMPRESSION_GZIP)
	DATA.append_array(COMPRESSED_DATA)

	if target == 0:
		if SteamLobby.members.size() > 1:
			for member in SteamLobby.members:
				var steam_id = member['steam_id']
				if steam_id != SteamAccount.STEAM_ID:
					if isP2PConnected(steam_id) or queue:
						Steam.sendP2PPacket(steam_id, DATA, send_type, CHANNEL)
	else:
		if isP2PConnected(target) or queue:
			Steam.sendP2PPacket(target, DATA, send_type, CHANNEL)

func _readP2PPackets() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(CHANNEL)

	# There is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, CHANNEL)
		
		if PACKET.is_empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")
		
		# Get the remote user's ID
		var from: int = PACKET['remote_steam_id']

		# Make the packet data readable
		var PACKET_CODE: PackedByteArray = PACKET['data']
		
		# Decompress the array before turning it into a useable dictionary
		var PACKET_DATA: Array = bytes_to_var(PACKET_CODE.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))

		# Print the packet to output
		var message: String = PACKET_DATA[0]
		var data: Dictionary = PACKET_DATA[1]

		_onPacket(from, message, data)

		onPacket.emit(from, message, data)
		
		# read more packets
		_readP2PPackets()

func _onSessionRequest(remote_id: int) -> void:
	var steam_name = Steam.getFriendPersonaName(remote_id)
	print("Connection request: " + steam_name);
	_p2pConnections[remote_id] = {
		"steam_id": remote_id,
		"steam_name": steam_name,
		"connected": true,
		"handshake": HandshakeState.INITIAL,
	}
	
	Steam.acceptP2PSessionWithUser(remote_id)
	
	sendHandshake(remote_id, HandshakeState.INITIAL)

func sendHandshake(target_id: int = 0, state: HandshakeState = HandshakeState.INITIAL) -> void:
	sendPacket(target_id, "handshake", {
		"state": state
	}, true)

func _onPacket(steam_id: int, message: String, data: Dictionary) -> void:
	if message == "handshake":
		var state = data['state']
		onHandshake.emit(steam_id, state)
		var newHandshakeState = state
		if state == HandshakeState.FAILED:
			newHandshakeState = HandshakeState.INITIAL
		elif state == HandshakeState.INITIAL:
			newHandshakeState = HandshakeState.RESPONSE
		elif state == HandshakeState.RESPONSE:
			newHandshakeState = HandshakeState.CONFIRMED

		if _p2pConnections.has(steam_id):
			_p2pConnections[steam_id]["handshake"] = newHandshakeState
		else:
			_p2pConnections[steam_id] = {"connected": true, "handshake": newHandshakeState}
			
		if state != newHandshakeState:
			sendHandshake(steam_id, newHandshakeState)
			if newHandshakeState == HandshakeState.CONFIRMED:
				onP2PConnected.emit(steam_id)
		

func _onPlayerLobbyLeft(steam_id: int):
	_p2pConnections.erase(steam_id)
	Steam.closeP2PSessionWithUser(steam_id)
	

func onSessionConnectFailure(steamID: int, session_error: int) -> void:
	_p2pConnections[steamID] = {"connected": false, "handshake": HandshakeState.FAILED}

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
		print(Steam.getP2PSessionState(steamID))
		sendPacket(steamID, "handshake", {})

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with "+str(steamID)+" [unused].")

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")
