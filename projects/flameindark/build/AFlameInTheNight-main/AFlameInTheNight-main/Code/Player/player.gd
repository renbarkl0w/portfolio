extends CharacterBody2D

class_name Player

@export_group("Movement")
@export var acceleration := 100.0
@export var decceleration := 300.0
@export var max_speed := 200.0
@export var jump_velocity := 200.0
@export_range(0,1) var air_control := 0.1

@export_group("Inventory")
@export var hand : Node2D
@export var backpack : Array[Node2D]

@export_group("Needs")
@export var max_hunger := 100.0
@export var max_temperature := 20.0
@export var max_health := 50.0

var hunger := 100.0:
	get: return hunger
	set(value): hunger = min(value, max_hunger)
var temperature := 20.0:
	get: return temperature
	set(value): temperature = min(value, max_temperature)
var health := 50.0:
	get: return health
	set(value):
		if value < health && health > 0:
			if blocking:
				return
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(sprite, "self_modulate", Color.INDIAN_RED, 0.08)
			tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.15)
		
		if health > 0 and value <= 0:
			health = min(value, max_health)
			play_animation("death")
			drop()
			drop_item(get_backpack_item(0))
			drop_item(get_backpack_item(1))
			await anim_tree.animation_finished
			on_death.emit()
		else:
			health = value


@onready var sprite: Sprite2D = $Sprite
@onready var pickup_area : Area2D = %PickupArea
@onready var interaction_area : Area2D = %InteractionArea
@onready var anim_tree : AnimationTree = %AnimationTree
@onready var interaction_popup: Panel = %InteractionPopup

var tween : Tween
var sheltered := false
var interacting := false
var blocking := false

signal on_animaiton_event
signal on_death

static var inst : Player


func _enter_tree() -> void:
	inst = self;

#region Input


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if global_position.y > 145.0:
		health = 0
	
	if health <= 0:
		return
	
	if sheltered or interacting:
		velocity.x = 0
		move_and_slide()
		return
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity += Vector2.UP * jump_velocity
		play_animation("jump")
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	var control_fraction := 1.0 if is_on_floor() else air_control
	if direction:
		var accel = acceleration if sign(direction) == sign(velocity.x) else decceleration
		velocity.x = move_toward(velocity.x, direction * max_speed, control_fraction * accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, control_fraction * decceleration * delta)
	
	move_and_slide()


func _input(event: InputEvent) -> void:
	if health <= 0 or interacting or not is_on_floor():
		return
	
	if sheltered:
		if event.is_action_pressed("interact"):
			sheltered = false
		return
	
	if event.is_action_pressed("cycle_item"):
		cycle_backpack_item(true)
	
	if event.is_action_pressed("pick_up"):
		if await pickup_item():
			return
	
	if event.is_action_pressed("interact"):
		if interact():
			return
	
	if event.is_action_pressed("use"):
		if await use_item():
			return
	
	if event.is_action_pressed("drop"):
		if drop():
			return
#endregion



func _process(delta: float) -> void:
	interaction_popup.visible = pickup_area.has_overlapping_bodies() or interaction_area.has_overlapping_bodies()
	
	hunger -= delta
	temperature += delta if Enviroment.inst.is_daytime else -delta
	if hunger <= 0:
		health -= delta
	if temperature <= 0:
		health -= delta
	if Enviroment.inst.is_raining and not sheltered:
		health -= delta



func interact() -> bool:
	if interaction_area.get_overlapping_bodies().size() == 0:
		return false
	
	var interactable : Interactable = interaction_area.get_overlapping_bodies().front()
	if not interactable:
		return false
	
	interactable.interact();
	return true


#region Animation
func animation_event():
	on_animaiton_event.emit()


func play_animation(anim_name : String):
	anim_tree.set("parameters/conditions/" + anim_name, true)
	anim_tree.set("parameters/States/conditions/" + anim_name, true)
	await get_tree().process_frame
	await get_tree().process_frame
	anim_tree.set( "parameters/conditions/" + anim_name, false)
	anim_tree.set("parameters/States/conditions/" + anim_name, false)

#endregion



#region Inventory

func drop() -> bool:
	if not is_hand_full():
		return false
	return drop_item(get_held_item())

func drop_item(item: Item) -> bool:
	if item == null:
		return false
	
	item.scale = sprite.scale
	item.reparent(get_tree().current_scene)
	item.set_picked_up(false)
	return true

func use_item() -> bool:
	if is_hand_full():
		if await get_held_item().use():
			return true
	return false


func pickup_item() -> bool:
	if pickup_area.get_overlapping_bodies().size() == 0:
		return false
	
	var item = pickup_area.get_overlapping_bodies().front()
	
	if not store_in_backpack(get_held_item()):
		return false
	
	interacting = true
	play_animation("pick_up")
	await on_animaiton_event
	item.reparent(hand, false)
	item.transform = Transform2D.IDENTITY 
	item.set_picked_up(true)
	await anim_tree.animation_finished
	interacting = false
	return true


func has_item(item_name: String) -> bool:
	if get_held_item().name.begins_with(item_name):
		return true
	
	for i in range(0, backpack.size()):
		if backpack[i].get_child_count() > 0:
			if backpack[i].get_child(0).name.begins_with(item_name):
				return true
	
	return false


func get_held_item() -> Item:
	if hand.get_child_count() == 0:
		return null
	return hand.get_child(0)


func is_hand_full() -> bool:
	return hand.get_child_count() > 0


func get_backpack_item(index : int) -> Item:
	if backpack[index].get_child_count() == 0:
		return null
	return backpack[index].get_child(0)


func is_backpack_full() -> bool:
	for i in range(backpack.size()):
		if backpack[i].get_child_count() > 0:
			return false
	return true


func store_in_backpack(item : Item) -> bool:
	if item == null:
		return true
	
	for i in range(backpack.size()):
		if backpack[i].get_child_count() == 0:
			item.reparent(backpack[i], false)
			item.transform = Transform2D.IDENTITY
			return true
	return false


func cycle_backpack_item(play_anim := false) -> void:
	var backpack_item := get_backpack_item(0)
	var hand_item := get_held_item()
	
	interacting = true
	if play_anim:
		play_animation("backpack")
		await on_animaiton_event
	
	if backpack_item:
		backpack_item.reparent(hand)
		backpack_item.transform = Transform2D.IDENTITY
		for i in range(1, backpack.size()):
			if backpack[i].get_child_count() > 0:
				var item := get_backpack_item(i)
				item.reparent(backpack[i-1], false)
				item.transform = Transform2D.IDENTITY
	
	store_in_backpack(hand_item)
	if play_anim:
		await anim_tree.animation_finished
	interacting = false

#endregion
