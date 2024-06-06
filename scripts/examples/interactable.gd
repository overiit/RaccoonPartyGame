#extends Area3D
class_name Interactable
extends Entity

# Custom Interact Threshold
@export var interact_message = "Interact"

func _ready():
	super._ready()
	InteractionManager.add_interactable(self)
	SteamLobbyManager.onPacket.connect(onPacket)

func onPacket(steam_id: int, message: String, data: Dictionary):
	if SteamLobbyManager.isHost():
		if message == "interact":
			_onInteract(steam_id)

func onInteract(steam_id: int):
	print(str(steam_id) + " interacted with " + str(get_entity_id()))
	pass

func _onInteract(steam_id: int):
	if !SteamLobbyManager.isHost():
		return
	onInteract(steam_id)

func interact():
	if !SteamLobbyManager.isHost():
		SteamLobbyManager.sendPacket(SteamLobbyManager.getHost(), "interact", {
			"entity_id": get_entity_id(),
		})
		return
	else:
		onInteract(SteamManager.STEAM_ID)
	pass
