class_name VehicleMount extends Mountable

func _ready():
	super._ready()
	if not get_parent() is Vehicle:
		print("Parent is not a vehicle")
		return;

func onMounted(steam_id: int):
	super.onMounted(steam_id)
	if EntityManager.players.has(steam_id):
		var player : Player = EntityManager.players[steam_id]
		var vehicle: Vehicle = get_parent();
		player.reparent(get_parent(), false)
		player.position = Vector3(0, 1.5, 0.5)
		player.rotation.y = -player.visual_char.rotation.y + 180
		player.onEntityMount(self)
		
		if steam_id == SteamManager.STEAM_ID:
			vehicle.controller.camera.make_current()

func onUnmounted(steam_id: int):
	super.onUnmounted(steam_id) 
	print("a")
	if EntityManager.players.has(steam_id):
		var player : Player = EntityManager.players[steam_id]
		# TODO: reparent to 
		var parent = Utils.findNodeOfType(get_tree().current_scene, EntitySpawner)
		if parent == null:
			# fallback to scene lol
			parent = get_tree().current_scene
		print("b")
		player.reparent(parent)
		# TODO fix player position
		player.global_position = parent.global_position
		player.velocity = Vector3.ZERO
		player.rotation.y = 0
		player.onEntityUnmount()
		

	# reset engine
	get_parent().set_idle()
