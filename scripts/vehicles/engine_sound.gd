extends AudioStreamPlayer3D

@export var sample_rpm := 4000.0

@onready var vehicle = $".."

func _ready():
	pass

func _physics_process(delta):
	pitch_scale = vehicle.motor_rpm / sample_rpm
	volume_db = linear_to_db((vehicle.throttle_amount * 0.5) + 0.5)
