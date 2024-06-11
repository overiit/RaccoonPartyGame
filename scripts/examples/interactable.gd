#extends Area3D
class_name Interactable
extends Entity

# @export var interaction_distance = 1.0
@export var is_interactable = true
@export var interact_message = "Interact"

signal onInteract(steam_id: int)

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
				onInteract.emit(steam_id)

func interact():
	print("Interacted with ", entity_id)
	if !SteamLobby.is_host():
		SteamNetwork.sendPacket(SteamLobby.host_id, "interact", {
			"entity_id": entity_id,
		})
		return
	else:
		onInteract.emit(SteamAccount.STEAM_ID)
	pass
