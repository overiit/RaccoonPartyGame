extends Node3D

var camera: Camera3D
var vehicle_node: Vehicle

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is Camera3D:
			camera = child
		elif child is Vehicle:
			vehicle_node = child
	
	if vehicle_node == null || camera == null:
		print("Vehicle or Camera not found")
		queue_free()
		return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.set_process(is_authority())
	#if !is_authority():
		#SteamLobbyManager.onPlayerMove.connect(_onPlayerMove)

func _physics_process(delta):
	if !is_authority():
		return

	vehicle_node.brake_input = Input.get_action_strength("down")
	vehicle_node.steering_input = Input.get_action_strength("left") - Input.get_action_strength("right")
	vehicle_node.throttle_input = pow(Input.get_action_strength("up"), 2.0)
	vehicle_node.handbrake_input = Input.get_action_strength("jump")
	#vehicle_node.clutch_input = clampf(Input.get_action_strength("Clutch") + Input.get_action_strength("Handbrake"), 0.0, 1.0)
	
	if vehicle_node.current_gear == -1:
		vehicle_node.brake_input = Input.get_action_strength("up")
		vehicle_node.throttle_input = Input.get_action_strength("down")

#func _onPlayerMove(steam_id: int, pos: Vector3, rot: Vector3, animation: String):
	#if get_authority() == steam_id:
		#position = pos
		#visual_char.rotation.y = rot.y
		#anim_player.play(animation)
		#return

func is_authority() -> bool:
	return true
	return get_authority() == SteamManager.STEAM_ID

func is_mounted():
	return get_authority() > 0

func get_authority() -> int:
	if has_meta("steam_id"):
		return get_meta("steam_id")
	return 0
