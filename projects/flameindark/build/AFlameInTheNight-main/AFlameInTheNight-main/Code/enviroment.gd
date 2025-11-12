extends Node
class_name Enviroment

static var inst : Enviroment

@export var day_length := 60.0
@export var night_length := 40.0
@export var min_rain_interval := 30.0
@export var max_rain_interval := 100.0
@export var min_rain_length := 10.0
@export var max_rain_length := 30.0
@export var transition_length := 3.0


@onready var day_background: Node2D = %DayBackground
@onready var night_background: Node2D = %NightBackground
@onready var rain_background: Node2D = %RainBackground
@onready var day_night_timer: Timer = $DayNightTimer
@onready var rain_timer: Timer = $RainTimer
@onready var anouncement: Label = %Anouncement
@onready var message: Label = %Message
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var is_daytime := true
var is_raining := false

func _enter_tree() -> void:
	inst = self


func  _ready() -> void:
	day_night_timer.start(day_length)
	rain_timer.start(day_length * 1.5 + night_length)


func _on_day_night_timer_timeout() -> void:
	create_tween().tween_property(night_background, "modulate", \
		Color.WHITE if is_daytime else Color.TRANSPARENT, transition_length)
	anouncement.text = ("Night" if is_daytime else "Day") + " is Comming"
	message.text = "Light a fire" if is_daytime else "The warmth returns"
	animation_player.play("anouncement")
	
	if not is_daytime:
		is_daytime = true
		await get_tree().create_timer(transition_length).timeout
	else:
		await get_tree().create_timer(transition_length).timeout
		is_daytime = false
	
	day_night_timer.start(day_length if is_daytime else night_length)


func _on_rain_timer_timeout() -> void:
	create_tween().tween_property(rain_background, "modulate", \
		Color.WHITE if is_raining else Color.TRANSPARENT, transition_length)
	
	if not is_raining:
		anouncement.text = "Rain is Comming"
		message.text = "Find shelter"
		animation_player.play("anouncement")
	
	
	await get_tree().create_timer(transition_length).timeout
	is_raining = not is_raining
	if is_raining:
		rain_timer.start(randf_range(min_rain_length, max_rain_length))
	else:
		rain_timer.start(randf_range(min_rain_interval, max_rain_interval))
