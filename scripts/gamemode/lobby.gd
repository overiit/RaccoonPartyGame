extends Gamemode

@export var spawnPoint: Node3D

func _ready():
	onGameModeReady.connect(_onGameModeReady)
	super._ready()

func _onGameModeReady(steam_id: int):
	if SteamLobby.is_host():
		EntityManager.spawnPlayer(steam_id, spawnPoint.global_position)
	EntityManager.refresh()

func process_player(_delta):
	if Input.is_action_just_pressed("ready_up"):
		GameState.toggleReady()
