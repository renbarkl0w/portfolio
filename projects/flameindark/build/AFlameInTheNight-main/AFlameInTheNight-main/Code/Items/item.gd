extends RigidBody2D

class_name Item

@export var use_animation : StringName

# Called when the node enters the scene tree for the first time.
func use() -> bool:
	return false


func set_picked_up(value : bool) -> void:
	collision_layer = 0 if value else 8
	freeze = value
