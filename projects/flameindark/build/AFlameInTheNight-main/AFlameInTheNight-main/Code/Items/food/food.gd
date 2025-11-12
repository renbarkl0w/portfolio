extends Item

@export var food_value := 30.0

func use() -> bool:
	if Player.inst.interacting:
		return false
	
	Player.inst.interacting = true
	Player.inst.play_animation(use_animation)
	await Player.inst.on_animaiton_event
	
	visible = false
	Player.inst.hunger += food_value
	
	await Player.inst.anim_tree.animation_finished
	Player.inst.interacting = false
	queue_free()
	
	return true
