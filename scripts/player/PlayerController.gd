class_name Player
extends CharacterBody3D

enum ViewMode { FIRST_PERSON, THIRD_PERSON }

@onready var camera : Camera3D = $camera_mount/Camera3D
@onready var anim_player = $raccoony/AnimationPlayer
@onready var camera_mount = $camera_mount
@onready var visual_char = $raccoony
@onready var interact_label = $Control/VBoxContainer/InteractLabel
@onready var collisionShape = $CollisionShape3D

@export
var PlayerViewMode = ViewMode.THIRD_PERSON

const interact_distance_threshold = 1.5;

const WALK_SPEED = 4.6
const SPRINT_SPEED = 8.0
var speed = WALK_SPEED
var gravity = 20

enum States {IDLE, RUN, SPRINT, JUMP, FALL, DROP_RUN_ROLL} 
var state = States.IDLE

const JUMP_VELOCITY = 10.0

@export var sens_horizontal = 0.5;
@export var sens_vertical = 0.5;

var steam_id: int = 0

var mounted_to : Mountable = null

func set_authority(_steam_id: int):
	steam_id = _steam_id
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	EntityManager.players[steam_id] = self

func _exit_tree():
	if steam_id > 0:
		EntityManager.players.erase(steam_id)

func is_authority() -> bool:
	return steam_id == SteamAccount.STEAM_ID

func _init():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _ready():
	camera.set_current(is_authority())

	if SteamLobby.is_host():
		SteamNetwork.sendPacket(0, "spawn_player", {
			"steam_id": steam_id,
			"position": position,
			"rotY": visual_char.rotation.y,
			"animation": "Idle"
		})

	SteamNetwork.onPacket.connect(_onPacket)
	SteamLobby.onPlayerLobbyLeft.connect(_onPlayerLobbyLeft)

func _onPlayerLobbyLeft(id: int):
	if not EntityManager.players.has(id):
		return
	EntityManager.players[id].queue_free()
	EntityManager.players.erase(id);

func _onPacket(_steam_id: int, message: String, data: Dictionary):
	if message == "pos" && _steam_id == steam_id:
		onPlayerMove(
			data['position'],
			data['rotY'],
			data['animation']
		)

func onEntityMount(entity: Mountable):
	velocity = Vector3.ZERO
	collisionShape.disabled = true
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	mounted_to = entity
	if is_authority():
		camera.set_current(false)
	
func onEntityUnmount():
	velocity = Vector3.ZERO
	collisionShape.disabled = false
	axis_lock_linear_x = false
	axis_lock_linear_y = false
	axis_lock_linear_z = false
	rotation = Vector3.ZERO
	mounted_to = null
	if is_authority():
		camera.set_current(true)

func onPlayerMove(pos: Vector3, rotY: float, animation: String):
	position = pos
	visual_char.rotation.y = rotY
	if animation.length() > 0:
		anim_player.play(animation)

func _unhandled_input(event):
	if mounted_to != null:
		return
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

func _process(_delta):
	if !is_authority():
		return
	# TODO limit to 60 ticks even if game is 144 ticks
	broadcastPosition();

func broadcastPosition():
	SteamNetwork.sendPacket(0, "pos", {
		"position": position,
		"rotY": visual_char.rotation.y,
		"animation": anim_player.current_animation
	})

func _physics_process(delta):
	if !is_authority():
		return
		
	update_closest_interactable();
	
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


########
# Interactions
########

var closest_interactable : Interactable = null

func update_closest_interactable():
	# no interactions while in car for now.
	if mounted_to != null:
		return
	
	
	var interactables = InteractionManager.get_interactables()
	var closest_distance = INF
	var closest = null
	var player_pos = self.global_transform.origin

	for interactable in interactables:
		if 'global_transform' in interactable:
			var object_pos = interactable.global_transform.origin
			var distance = player_pos.distance_to(object_pos)
			if distance < closest_distance:
				closest = interactable
				closest_distance = distance

	if closest_distance <= interact_distance_threshold:
		closest_interactable = closest
	else: 
		closest_interactable = null
		
	interact_label.visible = closest_interactable != null
	
	if closest_interactable != null:
		if 'interact_message' in closest_interactable and closest_interactable.interact_message != null:
			interact_label.text = closest_interactable.interact_message
	
	if Input.is_action_just_pressed("interact") and closest_interactable != null:
		if closest_interactable.has_method("interact"):
			closest_interactable.interact()
		else:
			print("Interactable has no interaction method. ")
