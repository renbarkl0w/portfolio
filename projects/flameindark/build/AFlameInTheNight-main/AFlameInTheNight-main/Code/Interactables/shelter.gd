extends Interactable



func interact() -> bool:
	Player.inst.sheltered = true
	return true
