extends AudioStreamPlayer3D

@export var sample_rpm := 4000.0

@onready var vehicle = $".."
@onready var controller = $"../.."

func _physics_process(delta):
	if !controller.is_mounted():
		stream_paused = true
		return;
	stream_paused = false
	pitch_scale = vehicle.motor_rpm / sample_rpm
	volume_db = linear_to_db((vehicle.throttle_amount * 0.5) + 0.5)
