@tool
class_name WheelSet
extends Node3D

@export var front_left_wheel : Wheel
@export var front_right_wheel : Wheel
@export var rear_left_wheel : Wheel
@export var rear_right_wheel : Wheel

func _get_configuration_warnings():
    var warnings = []
    if not front_left_wheel:
        warnings.append("Front left wheel not set.")
    if not front_right_wheel:
        warnings.append("Front right wheel not set.")
    if not rear_left_wheel:
        warnings.append("Rear left wheel not set.")
    if not rear_right_wheel:
        warnings.append("Rear right wheel not set.")
    return warnings