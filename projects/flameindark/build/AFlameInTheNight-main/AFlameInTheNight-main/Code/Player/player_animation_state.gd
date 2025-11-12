extends AnimationTree

class_name PlayerAnimationState

var facing_left : bool
@onready var sprite: Sprite2D = $"../../Sprite"

func _ready() -> void:
	%AnimationPlayer.active = true

func _process(_delta: float) -> void:
	if Player.inst.velocity.x != 0:
		facing_left = Player.inst.velocity.x < 0
		Player.inst.sprite.scale.x = -1 if facing_left else 1


func is_moving() -> bool:
	return Player.inst.velocity == Vector2.ZERO


func is_on_floor() -> bool:
	return Player.inst.is_on_floor()
