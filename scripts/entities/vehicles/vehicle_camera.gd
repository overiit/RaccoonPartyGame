@tool
class_name VehicleCamera
extends Camera3D


@onready var controller : VehicleController = get_parent();

@export var follow_distance = 5
@export var follow_height = 2
@export var speed:=20.0


func _get_configuration_warnings():
	if not get_parent() is VehicleController:
		return PackedStringArray(["This camera should be a child of a Vehicle node"])
	return []

var start_rotation : Vector3
var start_position : Vector3

func _ready():
	start_rotation = rotation
	start_position = position

func _process(_delta):
	if controller == null:
		return
	if controller.vehicle == null:
		return
		
	var delta_v: Vector3 = global_transform.origin - controller.vehicle.global_transform.origin
	delta_v.y = 0.0
	if (delta_v.length() > follow_distance):
		delta_v = delta_v.normalized() * follow_distance
		delta_v.y = follow_height
		global_position = controller.vehicle.global_transform.origin + delta_v
	
	look_at(controller.vehicle.global_transform.origin, Vector3.UP)
