extends Interactable

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var fallen_over := false
var broken := false

func interact() -> bool:
	if fallen_over or Player.inst.interacting:
		return false
	
	fallen_over = true
	Player.inst.interacting = true
	collision_layer -= 16
	animation_player.play("fall_over")
	Player.inst.play_animation("push")
	await Player.inst.anim_tree.animation_finished
	Player.inst.interacting = false
	return true




func _on_cruble_area_2d_body_entered(body: Node2D) -> void:
	if not fallen_over:
		return
	if broken:
		return
	
	broken = true
	animation_player.play("break")
