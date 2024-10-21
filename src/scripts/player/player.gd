class_name Player
extends CharacterBody2D

@export_group("State")
enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	HURT,
	DEATH,	
}
@export var current_state = State.IDLE

#Speed
@export_group("Speed")
@export var speed : float = 300.0
@export var jump_velocity : float = -400.0

#Gravity
@export_group("Gravity")
@export var jump_gravity : float = 9.8
@export var fall_gravity : float = 19.6

@export_group("Jump Timers")
@export var jump_buffer_time : float = 0.1
@export var coyote_jump_time : float = 0.1
@onready var jump_buffer_timer : Timer = $JumpBufferTimer
@onready var coyote_jump_timer : Timer = $CoyoteJumpTimer

#Sprite
@onready var sprite : Sprite2D = $Sprite2D

#Camera
@onready var camera : Camera2D = $Camera2D

func _ready() -> void:
	jump_buffer_timer.wait_time = jump_buffer_time
	coyote_jump_timer.wait_time = coyote_jump_time
	

func set_state(state : State) -> void:
	current_state = state
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, speed)
		State.JUMP:
			velocity.y = jump_velocity
		State.HURT:
			velocity = Vector2(-velocity.x, -200)
			await get_tree().create_timer(0.2).timeout
			set_state(State.IDLE)
			return
		State.DEATH:
			get_tree().reload_current_scene()
			
func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_jump_timer.start()
		
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer.start()
		
	#Character flip direction
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		sprite.flip_h = direction < 0
		
	process_state(delta)
	move_and_slide()

func process_state(delta : float) -> void:
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.RUN:
			process_run(delta)
		State.JUMP:
			process_jump(delta)
		State.FALL:
			process_fall(delta)
			

func process_idle(delta : float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if not is_on_floor():
		set_state(State.FALL)
	
	if direction != 0:
		set_state(State.RUN)
	
	if not jump_buffer_timer.is_stopped() and not coyote_jump_timer.is_stopped():
		set_state(State.JUMP)
	
func process_run(delta : float) -> void:
	if not is_on_floor():
		velocity.y += fall_gravity
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		set_state(State.IDLE)
		return
	
	velocity.x = direction * speed
	
	if not jump_buffer_timer.is_stopped() and not coyote_jump_timer.is_stopped():
		set_state(State.JUMP)

func process_jump(delta : float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	velocity.y += jump_gravity
	
	if Input.is_action_just_released("ui_accept"):
		velocity.y /= 2
		
	if velocity.y > 0:
		set_state(State.FALL)

func process_fall(delta : float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	velocity.y += fall_gravity
	
	if is_on_floor():
		set_state(State.RUN if direction != 0 else State.IDLE)
