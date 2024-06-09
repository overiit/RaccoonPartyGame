extends Gamemode

@export var spawnPoint: Node3D

func _ready():
	onGameModeReady.connect(_onGameModeReady)

func _onGameModeReady(steam_id: int):
	EntityManager.spawnPlayer(steam_id, spawnPoint.global_position)

func process_player(_delta):
	if Input.is_action_just_pressed("ready_up"):
		GameState.toggleReady()
