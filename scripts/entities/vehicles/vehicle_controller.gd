@tool
class_name VehicleController extends Node3D

@export var camera: Camera3D
@export var vehicle: Vehicle
@export var mount: VehicleMount

func _get_configuration_warnings():
	var warnings = []
	if mount == null:
		warnings.append("VehicleMount not found")
	if vehicle == null:
		warnings.append("Vehicle not found")
	if camera == null:
		warnings.append("Camera not found")
	
	return PackedStringArray(warnings)

# Called when the node enters the scene tree for the first time.

func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED
	
	mount.onMounted.connect(_onMounted)
	mount.onUnmounted.connect(_onUnmounted)

func _onMounted(_steam_id: int):
	process_mode = Node.PROCESS_MODE_ALWAYS
	pass

func _onUnmounted(_steam_id: int):
	process_mode = Node.PROCESS_MODE_DISABLED
	pass

var exitTimer = 0.0;
const EXIT_THRESHOLD = .3
const EXIT_TIMER = 0.8;

func _process(_delta):
	if mount == null:
		return
	if !mount.is_authority():
		return
	
	var player = EntityManager.players[mount.mounted_by]

	if Input.is_action_just_pressed("interact"):
		exitTimer = _delta
	elif Input.is_action_pressed("interact") && exitTimer != 0.0:
		exitTimer += min(EXIT_TIMER, _delta)
		if player != null && exitTimer >= EXIT_THRESHOLD:
			player.label.visible = true
			player.progressbar.visible = true
			player.label.text = "Exiting..."
			player.progressbar.min_value = EXIT_THRESHOLD
			player.progressbar.max_value = EXIT_TIMER
			player.progressbar.value = exitTimer
		if exitTimer >= EXIT_TIMER && exitTimer != 0.0:
			exitTimer = 0.0
			mount.unmount(SteamAccount.STEAM_ID)
			player.label.visible = false
			player.progressbar.visible = false
	elif Input.is_action_just_released("interact"):
		if player != null:
			player.label.visible = false
			player.progressbar.visible = false
		exitTimer = 0.0
	else:
		exitTimer = 0.0
			
			
			

func _physics_process(delta):
	if mount == null || !mount.is_authority():
		return

	vehicle.brake_input = Input.get_action_strength("down")
	vehicle.steering_input = Input.get_action_strength("left") - Input.get_action_strength("right")
	vehicle.throttle_input = pow(Input.get_action_strength("up"), 2.0)
	vehicle.handbrake_input = Input.get_action_strength("jump")
	#vehicle.clutch_input = clampf(Input.get_action_strength("Clutch") + Input.get_action_strength("Handbrake"), 0.0, 1.0)
	
	if vehicle.current_gear == -1:
		vehicle.brake_input = Input.get_action_strength("up")
		vehicle.throttle_input = Input.get_action_strength("down")

func broadcast():
	var send = false
	if mount.is_authority():
		send = true
	elif mount.mounted_by == 0 && SteamLobby.is_host():
		send = true
		
	if !send:
		return
	
	var datapacket = {
		"id": mount.entity_id,
		# Broadcast everything
		"global_position": vehicle.global_position,
		"global_transform": vehicle.global_transform,
		"linear_velocity": vehicle.linear_velocity,
		"angular_velocity": vehicle.angular_velocity,

		#"speed": vehicle.speed,
		#"motor_rpm": vehicle.motor_rpm,
		#"steering_amount": vehicle.steering_amount,
		#"throttle_amount": vehicle.throttle_amount,
		#"brake_amount": vehicle.brake_amount,
		#"clutch_amount": vehicle.clutch_amount,
		#"current_gear": vehicle.current_gear,
		#"torque_output": vehicle.torque_output,
		#"clutch_torque": vehicle.clutch_torque,
	}

	#print(datapacket)

	SteamNetwork.sendPacket(0, "entity_move", datapacket, false, Steam.P2P_SEND_UNRELIABLE_NO_DELAY)
