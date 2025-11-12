extends Item
class_name Stick

static var burning_stick : Stick

@export var warmth_amount := 2.0
@export var durability_sprites : Array[Sprite2D]

@onready var warmth_area: Area2D = %WarmthArea
@onready var extinguish_timer : Timer = %ExtinguishTimer
@onready var fire_durability_timer : Timer = %FireDurabilityTimer
@onready var fire_particles : GPUParticles2D = %FireParticles
@onready var hit_area : Area2D = %HitArea2D
@onready var sprite_root : Node2D = %SpriteRoot
@onready var durability := durability_sprites.size() - 1:
	get: return durability
	set(value):
		if value < 0 && durability < 0:
			return
			
		durability = max(0, value)
		for s in durability_sprites:
			s.visible = false
			s.process_mode = Node.PROCESS_MODE_DISABLED
		
		durability_sprites[durability].visible = true
		durability_sprites[durability].process_mode = Node.PROCESS_MODE_INHERIT
		var target_node : Node2D = durability_sprites[durability].get_child(0)
		create_tween().tween_property(fire_particles, "position", target_node.position * durability_sprites[durability].scale, 0.2)
		
		if durability == 0:
			break_stick()




var extinguish_tween : Tween
var swinging := false

var is_on_fire := false:
	get: return is_on_fire
	set(value):
		is_on_fire = value
		fire_particles.visible = value
		if value:
			burning_stick = self
			fire_durability_timer.start()
		else:
			if burning_stick == self:
				burning_stick = null
			fire_durability_timer.stop()


func _ready() -> void:
	durability = durability


func set_picked_up(value : bool) -> void:
	collision_layer = 0 if value else 8
	freeze = value
	if !value:
		extinguish_timer.start()
		extinguish_tween = create_tween()
		extinguish_tween.tween_property(fire_particles, "modulate", Color.TRANSPARENT, extinguish_timer.wait_time)
	else:
		extinguish_timer.stop()
		if extinguish_tween:
			extinguish_tween.stop()


func use() -> bool:
	if durability <= 0:
		return false
	
	if Player.inst.interacting:
		return false
	
	sprite_root.visible = false
	Player.inst.interacting = true
	Player.inst.blocking = true
	is_on_fire = false
	Player.inst.play_animation(use_animation)
	await Player.inst.on_animaiton_event
	for rat : Node2D in hit_area.get_overlapping_bodies():
		if rat is RigidBody2D:
			rat.get_parent().take_damage()
		else:
			rat.take_damage()
		durability -= 1
		break;
	await Player.inst.anim_tree.animation_finished
	Player.inst.blocking = false
	Player.inst.interacting = false
	sprite_root.visible = true
	
	return true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_on_fire and warmth_area.overlaps_body(Player.inst):
		Player.inst.temperature += warmth_amount * delta

func break_stick() -> void:
	is_on_fire = false


func _on_extinguish_timer_timeout() -> void:
	is_on_fire = false


func _on_fire_durability_timer_timeout() -> void:
	durability -= 1
