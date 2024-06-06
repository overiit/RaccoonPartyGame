extends Interactable
class_name Mountable

func _ready():
	super._ready()


func onPacket(sender: int, message: String, data: Dictionary):
	super.onPacket(sender, message, data);
	if sender == SteamLobbyManager.getHost():
		if message == "mount" && data['entity_id'] == get_entity_id():
			onMounted(data['steam_id'])
		if message == "unmount" && data['steam_id'] == get_authority():
			onUnmounted(data['steam_id'])

# when a user successfully mounted this, handle accordingly in the subclass
func onMounted(steam_id: int):
	set_mount(steam_id)

func onUnmounted(steam_id: int):
	unset_mount()

func unmount():
	if SteamLobbyManager.isHost():
		onUnmounted(SteamManager.STEAM_ID)
	else:
		SteamLobbyManager.sendPacket(SteamLobbyManager.getHost(), "unmount", {
			"steam_id": SteamManager.STEAM_ID,
			"entity_id": get_entity_id()
		})

func _handleMount(steam_id: int):
	if SteamLobbyManager.isHost():
		SteamLobbyManager.sendPacket(0, "mount", {
			"steam_id": steam_id,
			"entity_id": get_entity_id(),
		})
	onMounted(steam_id);

# when a user successfully interacted with this
func onInteract(steam_id: int):
	super.onInteract(steam_id)
	if !is_mountable():
		print("not mountable")
		# TODO Let user now and give them an alert, though it should show up anyways
		return
	_handleMount(steam_id)
########
# Util
########

func set_mount(steam_id: int):
	set_meta("steam_id", steam_id)

func unset_mount():
	remove_meta("steam_id")

func is_mountable():
	return !is_mounted()

func is_mounted():
	return get_authority() > 0

func is_authority() -> bool:
	return get_authority() == SteamManager.STEAM_ID
	
func get_authority() -> int:
	if has_meta("steam_id"):
		return get_meta("steam_id")
	return 0
