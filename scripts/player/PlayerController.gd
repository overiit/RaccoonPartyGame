extends CharacterBody3D

enum ViewMode { FIRST_PERSON, THIRD_PERSON }

@onready var camera = $camera_mount/Camera3D
@onready var anim_player = $raccoony/AnimationPlayer
@onready var camera_mount = $camera_mount
@onready var visual_char = $raccoony

@export
var PlayerViewMode = ViewMode.THIRD_PERSON

const interact_distance_threshold = 1.5;

const WALK_SPEED = 4.6
const SPRINT_SPEED = 8.0
var speed = WALK_SPEED

enum States {IDLE, RUN, SPRINT, JUMP, FALL, DROP_RUN_ROLL} 
var state = States.IDLE

const JUMP_VELOCITY = 10.0

@export var sens_horizontal = 0.5;
@export var sens_vertical = 0.5;

var health = 100
var money = 0
var items = []

var gravity = 20

func is_authority() -> bool:
	return get_authority() == SteamManager.STEAM_ID
	
func get_authority() -> int:
	if has_meta("steam_id"):
		return get_meta("steam_id")
	return 0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.set_process(is_authority())
	if !is_authority():
		SteamLobbyManager.onPlayerMove.connect(_onPlayerMove)

func _onPlayerMove(steam_id: int, pos: Vector3, rot: Vector3, animation: String):
	if get_authority() == steam_id:
		position = pos
		visual_char.rotation.y = rot.y
		anim_player.play(animation)
		pass

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		repositionCamera(event.relative.x, event.relative.y);
		

func repositionCamera(relativeX, relativeY):
	var x_rot = camera_mount.rotation_degrees.x - relativeY * sens_vertical
	var y_rot = camera_mount.rotation_degrees.y - relativeX * sens_horizontal
	x_rot = clamp(x_rot, -80, 80)
	camera_mount.rotation_degrees.x = x_rot
	camera_mount.rotation_degrees.y = y_rot
	camera.global_transform.origin = camera_mount.global_transform.origin + camera_mount.global_transform.basis.z * 5
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera_mount.global_position, camera.global_position)
	var result = space_state.intersect_ray(query);

	
	if result.has("position"):
		camera.global_position = result["position"]
	
	camera.look_at(camera_mount.global_transform.origin)	

func _physics_process(delta):
	if !is_authority():
		return
		
	repositionCamera(0, 0)
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var input_vector = Vector3(input_dir.x, 0, input_dir.y)  
	var direction = (camera_mount.global_transform.basis * input_vector)

	if !is_on_floor():
		velocity.y -= gravity * delta
		state = States.FALL
	else:
		if state == States.FALL:
			state = States.IDLE
		elif Input.is_action_just_pressed("jump") && is_on_floor():
			velocity.y = JUMP_VELOCITY
			state = States.JUMP
		elif direction:
			if Input.is_action_pressed("sprint"):
				speed = SPRINT_SPEED
				state = States.SPRINT
			else:
				speed = WALK_SPEED
				state = States.RUN
		else:
			state = States.IDLE

	direction.y = 0
	direction = direction.normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_angle = atan2(direction.x, direction.z)
		visual_char.rotation.y = lerp_angle(visual_char.rotation.y, target_angle, 10 * delta)
	else:
		velocity.x = 0
		velocity.z = 0
	
	play_animation()
	move_and_slide()

func _process(delta):
	if !is_authority():
		return
	# limit to 60 ticks even if game is 144 ticks
	broadcastPosition();


func broadcastPosition(steam_id: int = 0):
	SteamLobbyManager.send_P2P_Packet(0, "pos", {
		"x": position.x,
		"y": position.y,
		"z": position.z,
		"rotY": visual_char.rotation.y,
		"animation": anim_player.current_animation,
	})
	

func play_animation():
	match state:
		States.IDLE:
			anim_player.play("Idle")
			return "Idle";
		States.RUN:
			anim_player.play("Walking")
			return "Walking"
		States.SPRINT:
			anim_player.play("Running")
			return "Running"
		States.FALL:
			anim_player.play("Falling")
			return "Falling"
		States.DROP_RUN_ROLL:
			anim_player.play("Crouch")
			return "Crouch";
