extends Node3D

@onready var connectionAction = $CanvasLayer/Control/CenterContainer/VBoxContainer/ConnectionAction
@onready var connectionStatus = $CanvasLayer/Control/CenterContainer/VBoxContainer/ConnectionStatus

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if SteamLobby.lobby_id == 0:
		connectionStatus.text = "Finding lobby..."
		return
	var members = SteamLobby.members;
	var memberCount = SteamLobby.members.size()
	var connected = 0
	for member in members:
		if member['steam_id'] == SteamAccount.STEAM_ID:
			memberCount -= 1
		if SteamNetwork.isP2PConnected(member['steam_id']):
			connected += 1
	
	if connected < memberCount:
		connectionStatus.text = "Connecting to players... (" + str(connected) + " / " + str(members.size() - 1) + ")"
		return
	connectionStatus.text = "Loading world... (0 / 1)"
	pass
