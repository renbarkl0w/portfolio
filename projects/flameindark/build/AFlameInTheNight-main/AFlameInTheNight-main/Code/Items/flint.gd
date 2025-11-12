extends Item

func use() -> bool:
	if Player.inst.interacting:
		return false
	
	if not Player.inst.has_item("Stick"):
		return false
	
	Player.inst.interacting = true
	Player.inst.play_animation(use_animation)
	await Player.inst.on_animaiton_event
	
	visible = false
	while not Player.inst.get_held_item().name.begins_with("Stick"):
		Player.inst.cycle_backpack_item()
	(Player.inst.get_held_item() as Stick).is_on_fire = true
	
	await Player.inst.anim_tree.animation_finished
	Player.inst.interacting = false
	queue_free()
	
	return true
