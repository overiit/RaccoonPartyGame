class_name VehicleMount extends Mountable

func _ready():
	super._ready()
	if not get_parent() is Vehicle:
		print("Parent is not a vehicle")
		return;
	onMounted.connect(_onMounted)
	onUnmounted.connect(_onUnmounted)

func _onMounted(steam_id: int):
	if EntityManager.players.has(steam_id):
		var player : Player = EntityManager.players[steam_id]
		var vehicle: Vehicle = get_parent();
		player.reparent(get_parent(), false)
		player.position = Vector3(0, 1.5, 0.5)
		player.rotation.y = -player.visual_char.rotation.y + 180
		player.onEntityMount(self)
		
		if steam_id == SteamAccount.STEAM_ID:
			vehicle.controller.camera.make_current()

func _onUnmounted(steam_id: int):
	print("a")
	if EntityManager.players.has(steam_id):
		var player : Player = EntityManager.players[steam_id]
		# TODO: reparent to 
		var parent = get_tree().current_scene
		print("b")
		player.reparent(parent)
		# TODO fix player position
		player.global_position = Vector3(0, 15, 0)
		player.velocity = Vector3.ZERO
		player.rotation.y = 0
		player.onEntityUnmount()
		

	# reset engine
	get_parent().set_idle()
