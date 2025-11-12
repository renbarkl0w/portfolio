extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	await Player.inst.on_death
	visible = true
	get_tree().paused = true
	animation_player.play("open")
