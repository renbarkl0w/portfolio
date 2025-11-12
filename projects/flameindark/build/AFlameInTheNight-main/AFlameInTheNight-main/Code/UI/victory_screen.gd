extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


func _on_victory_area_body_entered(body: Node2D) -> void:
	visible = true
