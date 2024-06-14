class_name Mountable extends Interactable

signal onMounted(steam_id: int)
signal onUnmounted(steam_id: int)

var mounted_by: int = 0
@export var unmount_here: Node3D

func _ready():
	super._ready()
	SteamNetwork.onPacket.connect(_onPacket)
	onInteract.connect(_onInteract)
	
func _onPacket(steam_id: int, message: String, data: Dictionary):
	if steam_id == SteamLobby.host_id:
		if message == "mount":
			if data["entity_id"] == entity_id:
				mounted_by = data["steam_id"]
				onMounted.emit(data["steam_id"])
		elif message == "unmount":
			if data["entity_id"] == entity_id:
				mounted_by = 0
				onUnmounted.emit(data["steam_id"])
	if SteamLobby.is_host():
		if message == "unmount":
			if data["entity_id"] == entity_id:
				unmount(data["steam_id"])


func mount(steam_id: int):
	if SteamLobby.is_host():
		SteamNetwork.sendPacket(0, "mount", {
			"steam_id": steam_id,
			"entity_id": entity_id,
		})
		mounted_by = steam_id
		onMounted.emit(steam_id)
	
func unmount(steam_id: int):
	if mounted_by != steam_id:
		print("not mounted by this user")
		return
	if SteamLobby.is_host():
		SteamNetwork.sendPacket(0, "unmount", {
			"steam_id": steam_id,
			"entity_id": entity_id,
		})
		mounted_by = 0
		onUnmounted.emit(steam_id)

# when a user successfully interacted with this
func _onInteract(steam_id: int):
	if !is_interactable:
		print("not mountable")
		# TODO Let user now and give them an alert, though it should show up anyways
		return
	if !is_mounted():
		mount(steam_id)
	else:
		# user gets disabled from interacting while mounted
		pass


########
# Util
########

func is_mounted():
	return mounted_by > 0

func is_authority() -> bool:
	return mounted_by == SteamAccount.STEAM_ID
