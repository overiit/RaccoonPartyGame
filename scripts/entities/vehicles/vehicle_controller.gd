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
		#SteamLobby.onPlayerMove.connect(_onPlayerMove)

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
	var broadcast = false
	if vehicle_mount.is_authority():
		broadcast = true
	elif vehicle_mount.get_authority() == 0 && SteamLobby.is_host():
		broadcast = true
		
	if !broadcast:
		return
	
	var datapacket = {
		"id": vehicle_mount.entity_id,
		# Broadcast everything
		"global_position": vehicle_node.global_position,
		"global_transform": vehicle_node.global_transform,
		"linear_velocity": vehicle_node.linear_velocity,
		"angular_velocity": vehicle_node.angular_velocity,

		#"speed": vehicle_node.speed,
		#"motor_rpm": vehicle_node.motor_rpm,
		#"steering_amount": vehicle_node.steering_amount,
		#"throttle_amount": vehicle_node.throttle_amount,
		#"brake_amount": vehicle_node.brake_amount,
		#"clutch_amount": vehicle_node.clutch_amount,
		#"current_gear": vehicle_node.current_gear,
		#"torque_output": vehicle_node.torque_output,
		#"clutch_torque": vehicle_node.clutch_torque,
	}

	#print(datapacket)

	SteamNetwork.sendPacket(0, "entity_move", datapacket, false, Steam.P2P_SEND_UNRELIABLE_NO_DELAY)
