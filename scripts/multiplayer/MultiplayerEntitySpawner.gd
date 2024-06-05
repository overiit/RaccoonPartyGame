class_name EntitySpawner
extends Node3D

func _ready():
    SteamLobbyManager.onPacket.connect(_onPacket)
    pass

func _onPacket(steam_id: int, message: String, data: Dictionary):
    print("Packet received")
    pass
