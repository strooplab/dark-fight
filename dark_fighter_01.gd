extends CharacterBody3D

signal dead
# Constants
const GRAVITY = -70.0
const MAX_SPEED = 20.0
const RUN_SPEED = 110.0
const JUMP_SPEED = 30.0
const ACCELERATION = 4.0
const DECELERATION = 80.0
const AIR_CONTROL = 1
const SHIELD_DEFENSE_MULTIPLIER = 0.3
const CROUCH_SPEED_MULTIPLIER = 0.5
const JUMP_BUFFER_TIME = 0.2
var attack_z_impulse_target : float = 0.0
var attack_z_impulse_current : float = 0.0
const IMPULSE_SMOOTHNESS : float = 0.1
const MAX_ATTACK_IMPULSE = 1.0

# Animation parameters
const MOVEMENT_BLEND_PARAM = "parameters/Movement/blend_position"
const RUNNING_BLEND_PARAM = "parameters/Running/blend_position"
const LIGHT_BLEND_PARAM = "parameters/Light_Attack/blend_position"
const HEAVY_BLEND_PARAM = "parameters/Heavy_Attack/blend_position"

# Onready variables for components
@onready var animation_tree = $Pivot/darkfighter01/AnimationTree
@onready var attack_hitbox = $AttackHitbox
@onready var camera = $Camera3D
@onready var health_bar = $Camera3D/Fighter_Healthbar

# State machine references
var state_machine
var state_machine_idle
var state_machine_crouch
var state_machine_shield_crouch
var state_machine_shield
var is_attacking = false
var damage_timeout := 1.0
var can_take_damage = true

@export var max_health := 200
var current_health := max_health

# Character state
enum PlayerState {
	IDLE,
	MOVING,
	RUNNING,
	JUMPING,
	CROUCHING,
	SHIELDING,
	SHIELD_CROUCHING,
	LIGHT_ATTACKING,
	HEAVY_ATTACKING,
	COMBO_ATTACKING,
	HIT,
	DEATH
}

var current_state = PlayerState.IDLE

# Animation states
var idle_animations = ["Stand01", "Stand02", "Stand03"]
var current_idle_animation = 0
var idle_animation_timer = 0.0
var idle_animation_change_time = 6.2 

# Attack system
var light_attack_combo_count = 0
var heavy_attack_combo_count = 0
var attack_combo_timer = 0.0
var attack_combo_window = 1.68 # Time window to continue a combo
var can_attack = true
var attack_cooldown = 0.0

# Movement and input variables
var jump_buffer_timer = 0.0
var coyote_time_timer = 0.0
var buffered_attack = ""
var coyote_time = 0.15  # Time window after leaving edge where you can still jump
var melee_damage = 30.0

# Signals
signal hit_opponent(damage, knockback)
signal player_hit(damage)

func _ready():
	add_to_group("player")
	# Initialize animation tree
	animation_tree.active = true
	state_machine = animation_tree.get("parameters/playback")
	state_machine_idle = animation_tree.get("parameters/Idle/playback")
	state_machine_shield = animation_tree.get("parameters/Shield/playback")
	state_machine_shield_crouch = animation_tree.get("parameters/Shield_Crouch/playback")
	state_machine_crouch = animation_tree.get("parameters/Crouch/playback")

	
	# Setup attack hitbox
	attack_hitbox.monitoring = false
	#attack_hitbox.connect(
		#"body_entered",
		#Callable(self, "_on_attack_hitbox_body_entered")
	#)

	
	# Set default animation
	transition_to_state(PlayerState.IDLE)
	
#func melee():
	#if Input.is_action_just_pressed("attack_light") or Input.is_action_just_pressed("attack_strong"):
		#print(attack_hitbox.monitoring)
		#if Input.is_action_just_pressed("attack_strong"):
			#melee_damage = 50.0
		#if attack_hitbox.monitoring:
			#for body in attack_hitbox.get_overlapping_bodies():
				#if body.is_in_group("enemy"):
					#if body.has_method("take_damage"):
						#body.take_damage(melee_damage)
	#await get_tree().create_timer(attack_cooldown).timeout
	health_bar.max_health = max_health
	health_bar.current_health = current_health
	health_bar.update_health_bar()
		
func _physics_process(delta):
	#melee()
	# Process timers
	process_timers(delta)
	
	# Procesar el impulso del ataque
	process_attack_impulse(delta)
	
	# Handle state-specific processing
	match current_state:
		PlayerState.IDLE:
			process_idle_state(delta)
		PlayerState.MOVING, PlayerState.RUNNING:
			process_movement_state(delta)
		PlayerState.JUMPING:
			process_jumping_state(delta)
		PlayerState.CROUCHING:
			process_crouching_state(delta)
		PlayerState.SHIELDING:
			process_shielding_state(delta)
		PlayerState.SHIELD_CROUCHING:
			process_shield_crouching_state(delta)
		PlayerState.LIGHT_ATTACKING, PlayerState.HEAVY_ATTACKING:
			process_attacking_state(delta)
		PlayerState.HIT:
			process_hit_state(delta)
		PlayerState.DEATH:
			process_death_state(delta)
	
	# Apply gravity (in all states except where explicitly handled)
	if not is_on_floor() and current_state != PlayerState.DEATH:
		velocity.y += GRAVITY * delta
	
	# Process input if in a state that allows it
	if can_process_input():
		process_input(delta)
	
	# Actually move the character
	#var has_collision = move_and_slide()
	#if can_take_damage and has_collision:
		#for i in range(get_slide_collision_count()):
			#if get_slide_collision(i).get_collider() is RigidBody3D:
				#$HealthBar.take_damage(50.0)
				#can_take_damage = false
				#await get_tree().create_timer(damage_timeout).timeout
				#can_take_damage = true
				#move_and_slide()
				#break
	move_and_slide()

func process_attack_impulse(delta):
	# Suavizar el impulso actual hacia el objetivo
	#pass
	if is_attacking:
		attack_z_impulse_current = lerp(attack_z_impulse_current, attack_z_impulse_target, IMPULSE_SMOOTHNESS * delta/2)
		# Aplicar el impulso al movimiento
		velocity.z -= attack_z_impulse_current
	else:
		# Reducir gradualmente el impulso cuando no está atacando
		attack_z_impulse_current = lerp(attack_z_impulse_current, 0.0, IMPULSE_SMOOTHNESS * delta)
		velocity.z -= attack_z_impulse_current
		
	# Si el impulso es muy pequeño, reiniciarlo
	if abs(attack_z_impulse_current) < 0.1 and abs(attack_z_impulse_target) < 0.1:
		attack_z_impulse_current = 0.0
		attack_z_impulse_target = 0.0

func process_timers(delta):
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	else:
		can_attack = true
		
	# Update jump buffer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Update coyote time
	if coyote_time_timer > 0:
		coyote_time_timer -= delta
	
	# Update combo timer
	if attack_combo_timer > 0:
		attack_combo_timer -= delta
		if attack_combo_timer <= 0:
			# Reset combo if timer expires
			light_attack_combo_count = 0
			heavy_attack_combo_count = 0
			buffered_attack = ""

# State processing functions
func process_idle_state(delta):
	# Handle idle animation cycling
	idle_animation_timer += delta
	if idle_animation_timer >= idle_animation_change_time:
		idle_animation_timer = 0.0
		current_idle_animation = (current_idle_animation + 1) % idle_animations.size()
		state_machine.travel("Idle")
		state_machine_idle.travel(idle_animations[current_idle_animation])
	
	# Apply deceleration
	if abs(velocity.z) > 0.1:
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
	else:
		velocity.z = 0
	
	# Check if we should transition to movement state
	var input_axis = Input.get_axis("move_right", "move_left")
	if abs(input_axis) > 0.1:
		if Input.is_action_pressed("run"):
			transition_to_state(PlayerState.RUNNING)
		else:
			transition_to_state(PlayerState.MOVING)

func process_movement_state(delta):
	var input_axis = Input.get_axis("move_right", "move_left")
	var target_speed = MAX_SPEED
	
	# Apply run multiplier if running
	if current_state == PlayerState.RUNNING:
		target_speed = RUN_SPEED
		animation_tree.set(RUNNING_BLEND_PARAM, input_axis)
	else:
		animation_tree.set(MOVEMENT_BLEND_PARAM, input_axis)
	
	# Apply acceleration
	if abs(input_axis) > 0.1:
		velocity.z = move_toward(velocity.z, input_axis * target_speed, ACCELERATION * delta)
	else:
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
	
	# Check if we should transition back to idle
	if abs(velocity.z) < 0.1 and abs(input_axis) < 0.1:
		transition_to_state(PlayerState.IDLE)
	
	# Check if run state should change
	if current_state == PlayerState.MOVING and Input.is_action_pressed("run"):
		transition_to_state(PlayerState.RUNNING)
	elif current_state == PlayerState.RUNNING and not Input.is_action_pressed("run"):
		transition_to_state(PlayerState.MOVING)

func process_jumping_state(delta):
	# Apply air control (limited horizontal movement during jump)
	var input_axis = Input.get_axis("move_right", "move_left")
	if abs(input_axis) > 0.1:
		velocity.z = move_toward(velocity.z, input_axis * MAX_SPEED, ACCELERATION * AIR_CONTROL * delta)
	
	# Check if landed
	if is_on_floor() and velocity.y <= 0:
		if abs(velocity.z) > 0.1:
			if Input.is_action_pressed("run"):
				transition_to_state(PlayerState.RUNNING)
			else:
				transition_to_state(PlayerState.MOVING)
		else:
			transition_to_state(PlayerState.IDLE)

func process_crouching_state(delta):
	# Apply deceleration to stop movement
	velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

func process_shielding_state(delta):
	# Apply deceleration to stop movement
	velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

func process_shield_crouching_state(delta):
	# Apply deceleration to stop movement
	velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

func process_attacking_state(delta):
	# Ahora permitimos el movimiento durante ataques (por el impulso)
	pass

func process_hit_state(delta):
	# Possibly apply knockback or other hit effects
	pass

func process_death_state(delta):
	# Death behavior - no movement, maybe fade out or other effects
	pass
	#velocity = Vector3.ZERO

# Input processing
func can_process_input():
	# States where we shouldn't process input
	return not (current_state == PlayerState.DEATH or 
				   current_state == PlayerState.HIT or
				   current_state == PlayerState.LIGHT_ATTACKING or 
				   current_state == PlayerState.HEAVY_ATTACKING)

func process_input(delta):
	# Jump input
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_time_timer > 0:
			perform_jump()
		else:
			# Buffer the jump for a short time
			jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Shield input
	if Input.is_action_just_pressed("shield"):
		if current_state == PlayerState.CROUCHING:
			transition_to_state(PlayerState.SHIELD_CROUCHING)
		elif can_shield():
			transition_to_state(PlayerState.SHIELDING)
	elif Input.is_action_just_released("shield"):
		if current_state == PlayerState.SHIELDING:
			transition_to_state(PlayerState.IDLE)
		elif current_state == PlayerState.SHIELD_CROUCHING:
			transition_to_state(PlayerState.CROUCHING)
	
	# Crouch input
	if Input.is_action_just_pressed("crouch"):
		if current_state == PlayerState.SHIELDING:
			transition_to_state(PlayerState.SHIELD_CROUCHING)
		elif can_crouch():
			transition_to_state(PlayerState.CROUCHING)
	elif Input.is_action_just_released("crouch"):
		if current_state == PlayerState.CROUCHING:
			transition_to_state(PlayerState.IDLE)
		elif current_state == PlayerState.SHIELD_CROUCHING:
			transition_to_state(PlayerState.SHIELDING)
	
	# Attack inputs
	if can_attack and attack_cooldown <= 0:
		if Input.is_action_just_pressed("attack_light"):
			if current_state == PlayerState.LIGHT_ATTACKING:
				buffered_attack = "attack_light"
			elif can_attack and attack_cooldown <= 0:
				perform_light_attack()
			melee_damage = 30.0
		elif Input.is_action_just_pressed("attack_strong"):
			if current_state == PlayerState.HEAVY_ATTACKING:
				buffered_attack = "attack_strong"
			elif can_attack and attack_cooldown <= 0:
				perform_heavy_attack()
			melee_damage = 50.0
# State transition and action functions
func transition_to_state(new_state):
	# Exit current state
	match current_state:
		PlayerState.IDLE:
			idle_animation_timer = 0
		PlayerState.JUMPING:
			pass
		PlayerState.CROUCHING:
			state_machine.travel("End_Crouch")
		PlayerState.SHIELDING:
			state_machine.travel("Quit_Shield")
		PlayerState.SHIELD_CROUCHING:
			pass
		PlayerState.LIGHT_ATTACKING, PlayerState.HEAVY_ATTACKING:
			if new_state != PlayerState.LIGHT_ATTACKING and new_state != PlayerState.HEAVY_ATTACKING:
				end_attack()
	
	# Set new state
	current_state = new_state
	
	# Enter new state
	match new_state:
		PlayerState.IDLE:
			state_machine.travel("Idle")
			state_machine_idle.travel(idle_animations[current_idle_animation])
		PlayerState.MOVING:
			state_machine.travel("Movement")
		PlayerState.RUNNING:
			state_machine.travel("Running")
		PlayerState.JUMPING:
			state_machine.travel("Jump")
		PlayerState.CROUCHING:
			state_machine.travel("Start_Crouch")
			# After animation completes:
			state_machine.travel("Crouch")
			state_machine_crouch.travel("Agachado")
		PlayerState.SHIELDING:
			state_machine.travel("Shield")
			state_machine_shield.travel("Hold_Shield")
		PlayerState.SHIELD_CROUCHING:
			state_machine.travel("Shield_Crouch")
			state_machine_shield_crouch.travel("Agachado_Escudo")
		PlayerState.LIGHT_ATTACKING:
			state_machine.travel("Light_Attack")
			perform_light_attack_animation()
		PlayerState.HEAVY_ATTACKING: 
			state_machine.travel("Heavy_Attack")
			perform_heavy_attack_animation()
		PlayerState.HIT:
			state_machine.travel("Impact")
		PlayerState.DEATH:
			state_machine.travel("Death")
			set_collision_layer_value(2, false) 
			set_collision_mask_value(4, false)

func perform_jump():
	velocity.y = JUMP_SPEED
	transition_to_state(PlayerState.JUMPING)
	jump_buffer_timer = 0
	
	# Clear any buffered jump when actually jumping
	jump_buffer_timer = 0

func can_shield():
	return current_state in [PlayerState.IDLE, PlayerState.MOVING, PlayerState.RUNNING]

func can_crouch():
	return current_state in [PlayerState.IDLE, PlayerState.MOVING, PlayerState.RUNNING]

func perform_light_attack():
	can_attack = false
	is_attacking = true
	attack_combo_timer = attack_combo_window
	transition_to_state(PlayerState.LIGHT_ATTACKING)
	if light_attack_combo_count >= 3:
		attack_cooldown = 3.0
		light_attack_combo_count = 0

	attack_cooldown = 0.9
	light_attack_combo_count += 1
	
func perform_heavy_attack():
	is_attacking = true 
	can_attack = false
	attack_combo_timer = attack_combo_window
	transition_to_state(PlayerState.HEAVY_ATTACKING)
	if heavy_attack_combo_count >= 3:
		attack_cooldown = 6.0
		heavy_attack_combo_count = 0
	attack_cooldown = 1.5
	heavy_attack_combo_count += 1

func perform_light_attack_animation():
	var idx = clamp(light_attack_combo_count, 0, 2)
	animation_tree.set(LIGHT_BLEND_PARAM, idx)
	activate_hitbox()
	var base_impulse = 0.8
	attack_z_impulse_target = base_impulse * (((light_attack_combo_count + 0.01) * 0.3))
	

func perform_heavy_attack_animation():
	var idx = clamp(heavy_attack_combo_count, 0, 2)
	animation_tree.set(HEAVY_BLEND_PARAM, idx)
	activate_hitbox()
	var base_impulse = 1
	attack_z_impulse_target = base_impulse * (((heavy_attack_combo_count + 0.01) * 0.5))

func activate_hitbox():
	attack_hitbox.monitoring = true

func deactivate_hitbox():
	attack_hitbox.monitoring = false

func end_attack():
	is_attacking = false
	deactivate_hitbox()
	attack_z_impulse_target = 0.0

# Signal handlers and animation callbacks
func _on_floor_exited():
	# Start coyote time when leaving the floor, except when jumping
	if current_state != PlayerState.JUMPING:
		coyote_time_timer = coyote_time

# Handle taking damage
func take_damage(amount: float, knockback_force: Vector3 = Vector3.ZERO) -> void:
	if not can_take_damage:
		return

	# Si estamos en estado de escudo, reducimos el daño
	var actual_damage := amount
	if current_state == PlayerState.SHIELDING or current_state == PlayerState.SHIELD_CROUCHING:
		state_machine.travel("Impact_Shield")
		actual_damage = amount * SHIELD_DEFENSE_MULTIPLIER
	else:
		state_machine.travel("Impact")

	# Aplicar knockback si existe
	if knockback_force != Vector3.ZERO:
		velocity += knockback_force / 2

	# Reducir vida
	current_health -= actual_damage
	can_take_damage = false
	
	# Actualizar la barra de vida
	health_bar.current_health = current_health
	health_bar.take_damage(actual_damage)  # Esto activará la animación de la barra

	# Emitir señal para la UI u otros listeners
	emit_signal("player_hit", actual_damage)

	if current_health <= 0:
		transition_to_state(PlayerState.DEATH)
		await get_tree().create_timer(3.5).timeout
		emit_signal("dead")
	else:
		await get_tree().create_timer(damage_timeout).timeout
		can_take_damage = true

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Golpe_Rapido", "Patada_Ligera", "Golpe_Fuerte_Reves":
			end_attack()
			transition_to_state(PlayerState.IDLE)
			if buffered_attack == "attack_light" and light_attack_combo_count < 3:
				buffered_attack = ""
				perform_light_attack()
		"Golpe_Fuerte","Golpe_Fuerte_Reves", "Ataque_Mortal" :
			end_attack()
			transition_to_state(PlayerState.IDLE)
			if buffered_attack == "attack_strong" and heavy_attack_combo_count < 3:
				buffered_attack = ""
				perform_heavy_attack()
		"Start_Crouch":
			state_machine.travel("Crouch")
		"End_Crouch":
			state_machine.travel("Idle")
		"Impact_Shield":
			if current_state == PlayerState.LIGHT_ATTACKING or current_state == PlayerState.HEAVY_ATTACKING:
				end_attack()
			transition_to_state(PlayerState.SHIELDING)
		"Impacto_Medio":
			if current_state == PlayerState.LIGHT_ATTACKING or current_state == PlayerState.HEAVY_ATTACKING:
				end_attack()
			transition_to_state(PlayerState.IDLE)
		"Quit_Shield":
			state_machine.travel("Shield_Crouch")
			state_machine_shield_crouch.travel("Agacharse_Quitar_Escudo")
		"Muerte02":
			pass


#func _on_health_bar_no_hp_left() -> void:
	#queue_free()


func _on_attack_hitbox_body_entered(body: CharacterBody3D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage") and is_instance_valid(body):
		var knockback_direction = (body.global_position - global_position).normalized()
		knockback_direction.z = 0.2
		var enemy_ref = body
		await get_tree().create_timer(0.46).timeout
		if is_instance_valid(enemy_ref) and enemy_ref.has_method("take_damage"):
			enemy_ref.take_damage(melee_damage, knockback_direction * 2.0)
