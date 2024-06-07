#extends Area3D
class_name Interactable
extends Entity

# Custom Interact Threshold
@export var interact_message = "Interact"

func _ready():
	super._ready()
	InteractionManager.add_interactable(self)
	SteamNetwork.onPacket.connect(onPacket)

func _exit_tree():	
	InteractionManager.interactables.erase(self)

func onPacket(steam_id: int, message: String, data: Dictionary):
	if SteamLobby.is_host():
		if message == "interact":
			if data['entity_id'] == entity_id:
				_onInteract(steam_id)

func onInteract(steam_id: int):
	print(str(steam_id) + " interacted with " + str(entity_id))
	pass

func _onInteract(steam_id: int):
	if !SteamLobby.is_host():
		return
	onInteract(steam_id)

func interact():
	if !SteamLobby.is_host():
		SteamNetwork.sendPacket(SteamLobby.host_id, "interact", {
			"entity_id": entity_id,
		})
		return
	else:
		onInteract(SteamAccount.STEAM_ID)
	pass
