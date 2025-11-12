extends CharacterBody2D

class_name Rat

@export var damage := 2.0
@export var hop_velocity := 300.0
@export var jump_velocity := 300.0
@export var speed := 300.0
@export var snap_radius := 30.0
@export var snap_speed := 700.0
@export var dead_rat : PackedScene

@onready var anchors : Array[Node2D] = \
	[$".", $Neck, $UpperBody/Spine, $LowerBody/Butt, $Tail/TailTip]
@onready var segments: Array[RigidBody2D] = \
	[%UpperBody, %LowerBody, %Tail]
@onready var line_sprite: Line2D = %LineSprite
@onready var little_hop_vision: RayCast2D = %LittleHopVision
@onready var jump_vision: RayCast2D = %JumpVision

var flipped := false
var intital_positions : Array[Vector2]
var direction := false

func _ready() -> void:
	intital_positions.resize(segments.size())
	for i in range(segments.size()):
		intital_positions[i] = segments[i].position
	
	for other in segments:
		add_collision_exception_with(other)
		little_hop_vision.add_exception(other)
		jump_vision.add_exception(other)
	
	direction = randf() > 0.5

func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if Stick.burning_stick:
			direction = global_position.x > Stick.burning_stick.global_position.x
		elif velocity.x == 0:
			direction = !direction
		little_hop_vision.scale.x = -1 if direction else 1
		jump_vision.scale.x = -1 if direction else 1
		velocity.x = speed if direction else -speed
		
		
	# Handle jump.
	if jump_vision.is_colliding() and is_on_floor():
		velocity.y = -jump_velocity
		velocity.x += speed if direction else -speed
	if little_hop_vision.is_colliding() and is_on_floor():
		velocity.y = -hop_velocity
	
	update_segments()
	
	move_and_slide()


func update_segments() -> void:
	if velocity.x:
		for segment in segments:
			segment.constant_force = Vector2(-sign(velocity.x) * 1000, 0)
		
		flipped = velocity.x > 0
		line_sprite.scale.y = -1 if flipped else 1
	
	for i in range(segments.size()):
		var target_pos := -intital_positions[i] if flipped else intital_positions[i]
		if segments[i].position.distance_to(target_pos) > snap_radius\
		or segments[i].linear_velocity.length() > snap_speed:
			segments[i].position = target_pos
			segments[i].linear_velocity = velocity
			segments[i].rotation = PI if flipped else 0.0
	
	for i in range(anchors.size()):
		line_sprite.set_point_position(i, line_sprite.to_local(anchors[i].global_position))


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body != Player.inst:
		return
	
	if Player.inst.blocking:
		velocity.x = -velocity.x
		velocity.y -= hop_velocity
	else:
		Player.inst.health -= damage


func take_damage():
	queue_free()
	var corpse : Node2D = dead_rat.instantiate()
	corpse.global_transform = global_transform
	get_tree().current_scene.add_child(corpse)
