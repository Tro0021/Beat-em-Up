class_name Character
extends CharacterBody2D

const GRAVITY := 600.0

@export var max_health : int
@export var damage : int
@export var jump_intensity : float
@export var speed : float
@export var knockback_intensity : float
@export var knockdown_intensity : float
@export var duration_grounded : float

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_emitter: Area2D = $DamageEmitter
@onready var damage_receiver: DamageReceiver = $DamageReceiver

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK, HURT, FALL, GROUNDED}

var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.ATTACK: "punch",
	State.TAKEOFF: "takeoff",
	State.JUMP: "jump",
	State.LAND: "land",
	State.JUMPKICK: "jumpkick",
	State.HURT: "hurt",
	State.FALL: "fall",
	State.GROUNDED: "grounded",
}

var current_health := 0
var height := 0.0
var height_speed := 0.0
var state = State.IDLE
var time_since_grounded := Time.get_ticks_msec()

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage)
	damage_receiver.damage_received.connect(on_receive_damage)
	current_health = max_health

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_animation()
	handle_air_time(delta)
	handle_grounded()
	flip_sprites()
	character_sprite.position = Vector2.UP * height
	collision_shape_2d.disabled = state == State.GROUNDED
	move_and_slide()

func handle_input() -> void:
	pass

func handle_grounded() -> void:
	if state == State.GROUNDED and (Time.get_ticks_msec() - time_since_grounded > duration_grounded):
		state = State.LAND

func handle_movement():
	if not can_move():
		return
	if velocity.length() == 0:
		state = State.IDLE
	else:
		state = State.WALK

func handle_animation() -> void:
	var anim = anim_map.get(state)
	if anim and animation_player.current_animation != anim:
		animation_player.play(anim)

func handle_air_time(delta : float) -> void:
	if [State.JUMP, State.JUMPKICK, State.FALL].has(state):
		height += height_speed * delta
		if height < 0:
			height = 0
			if state == State.FALL:
				state = State.GROUNDED
				time_since_grounded = Time.get_ticks_msec()
			else:
				state = State.LAND
			velocity = Vector2.ZERO
		else:
			height_speed -= GRAVITY * delta

func flip_sprites() -> void:
	if velocity.x != 0:
		character_sprite.flip_h = velocity.x < 0
		damage_emitter.scale.x = -1 if velocity.x < 0 else 1

func can_move() -> bool:
	return state == State.IDLE or state == State.WALK

func can_attack() -> bool:
	return state == State.IDLE or state == State.WALK

func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK

func can_jumpkick() -> bool:
	return state == State.JUMP

func on_action_complete() -> void:
	state = State.IDLE

func on_takeoff_complete() -> void:
	state = State.JUMP
	height_speed = jump_intensity

func on_land_complete() -> void:
	state = State.IDLE

func on_receive_damage(amount: int, direction: Vector2, hit_type: DamageReceiver.HITtype) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	if current_health == 0 or hit_type == DamageReceiver.HITtype.KNOCKBACK:
		state = State.FALL
		height_speed = knockdown_intensity
	else:
		state = State.HURT
	if current_health <= 0:
		queue_free()
	velocity = direction * knockback_intensity

func on_emit_damage(receiver : DamageReceiver) -> void:
	var hit_type := DamageReceiver.HITtype.NORMAL
	var direction := Vector2.LEFT if receiver.global_position.x < global_position.x else Vector2.RIGHT
	if state == State.JUMPKICK:
		hit_type = DamageReceiver.HITtype.KNOCKBACK
	receiver.damage_received.emit(damage, direction, hit_type)
