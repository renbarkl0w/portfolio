extends CanvasLayer

static var opened := false

func _enter_tree() -> void:
	if opened:
		queue_free()


func _ready() -> void:
	if not opened:
		opened = true
		get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false
