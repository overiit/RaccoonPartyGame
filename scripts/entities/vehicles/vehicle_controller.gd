class_name VehicleController extends Node3D

var camera: Camera3D
var vehicle_node: Vehicle
var vehicle_mount: VehicleMount

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
		
	for child in vehicle_node.get_children():
		if child is VehicleMount:
			vehicle_mount = child

	#if !is_authority():
		#SteamLobbyManager.onPlayerMove.connect(_onPlayerMove)

func _physics_process(delta):
	if vehicle_mount == null || !vehicle_mount.is_authority():
		return

	vehicle_node.brake_input = Input.get_action_strength("down")
	vehicle_node.steering_input = Input.get_action_strength("left") - Input.get_action_strength("right")
	vehicle_node.throttle_input = pow(Input.get_action_strength("up"), 2.0)
	vehicle_node.handbrake_input = Input.get_action_strength("jump")
	#vehicle_node.clutch_input = clampf(Input.get_action_strength("Clutch") + Input.get_action_strength("Handbrake"), 0.0, 1.0)
	
	if vehicle_node.current_gear == -1:
		vehicle_node.brake_input = Input.get_action_strength("up")
		vehicle_node.throttle_input = Input.get_action_strength("down")

func broadcast():
	if vehicle_mount == null || !vehicle_mount.is_authority():
		return

	SteamLobbyManager.sendPacket(0, "entity_move", {
		"id": vehicle_mount.get_authority(),
	})
