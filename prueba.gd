extends CharacterBody3D

# Movimiento
const WALK_SPEED = 80.0
const RUN_SPEED = 130.0
const ACCELERATION = 20.0
const DECELERATION = 10.0
const JUMP_VELOCITY = 90.0
const MAX_JUMP_HEIGHT = 10.0
const MIN_GRAVITY = 200.0  # Aplicar gravedad correctamente
const COYOTE_TIME = 0.3
const JUMP_BUFFER = 0.3
const DOUBLE_JUMP_VELOCITY = 100.0
const SLOW_FALL_MULTIPLIER = 2.5
const ROTATION_SPEED = 20.0


# Variables
var gold = 0
var is_running = false
var GRAVITY = MIN_GRAVITY
var initial_jump_position = 0.0
var last_on_floor_time = 0.0
var last_jump_pressed_time = 0.0
var rotation_velocity = 0.0
var is_jumping = false
var can_double_jump = false
var is_double_jumping = false
var is_slow_falling = false


@onready var animation_player = $Pivot/darkfighter01/AnimationPlayer
@onready var mesh = $Pivot/darkfighter01
@onready var camera = $Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_player.play("Agachado")
	print(animation_player)

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_jump(delta)
	handle_rotation(delta)
	move_and_slide()
	update_animations()

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var cam_basis = camera.global_transform.basis
	var forward = -cam_basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var right = cam_basis.x
	right.y = 0
	right = right.normalized()
	
	# Calculate direction based on camera orientation
	var direction = (forward * input_dir.y + right * input_dir.x).normalized()
	
	# Control de velocidad
	is_running = Input.is_action_pressed("run")
	var target_speed = RUN_SPEED if is_running else WALK_SPEED
	
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * target_speed, (delta * ACCELERATION))
		velocity.z = lerp(velocity.z, direction.z * target_speed, (delta * ACCELERATION))
	else:
		velocity.x = lerp(velocity.x, 0.0, (delta * DECELERATION))
		velocity.z = lerp(velocity.z, 0.0, (delta * DECELERATION))
	
	# Aplicar gravedad correctamente
	if !is_on_floor():
		velocity.y -= GRAVITY * delta

func handle_jump(delta):
	# Coyote time
	if is_on_floor():
		last_on_floor_time = COYOTE_TIME
		can_double_jump = true  # Reset del doble salto al tocar el suelo
		is_slow_falling = false  # Reset de caída lenta
		is_jumping = false  # Reset del estado de salto
		is_double_jumping = false 
		rotation_velocity = 0.0 
		GRAVITY = MIN_GRAVITY
	else:
		last_on_floor_time -= delta

	# Jump buffer (almacena el tiempo en el que se presionó el botón de salto)
	if Input.is_action_just_pressed("jump"):
	
		last_jump_pressed_time = JUMP_BUFFER
	else:
		last_jump_pressed_time -= delta

	# Salto normal
	if last_jump_pressed_time > 0 and last_on_floor_time > 0:
		
		velocity.y = JUMP_VELOCITY
		initial_jump_position = global_transform.origin.y
		is_jumping = true
		last_jump_pressed_time = 0  
		
		animation_player.play("Salto")
		return 
	
	# Doble salto
	if Input.is_action_just_pressed("jump") and can_double_jump and !is_on_floor():
		
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false
		is_slow_falling = true  # Activa caída lenta después del giro
		is_double_jumping = true
		rotation_velocity = ROTATION_SPEED
		GRAVITY = MIN_GRAVITY / SLOW_FALL_MULTIPLIER  
		animation_player.play("Stand01")  # Usa una animación distinta para el doble salto
	
	if is_slow_falling:
		GRAVITY = MIN_GRAVITY / SLOW_FALL_MULTIPLIER  
	else:
		GRAVITY = MIN_GRAVITY
	# Control de salto sostenido
	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.5  

func handle_rotation(delta):
	if is_double_jumping:
		mesh.rotation.y += rotation_velocity * delta
	elif velocity.length() > 0.5:
		var look_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		if look_direction != Vector3.ZERO:
			mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-look_direction.x, -look_direction.z), 0.2)
	

func update_animations():
	if !is_on_floor():
		if is_slow_falling:
			animation_player.play("Stand02")  # Cambia la animación de caída
		elif is_jumping:
			animation_player.play("Salto")
	elif velocity.length() > 0.5:
		animation_player.play("Correr_Adelante" if is_running else "Movimiento_Adelante")
	else:
		animation_player.play("Stand00")

	
