extends CharacterBody3D

signal dead
# Health system
@export var max_health_e := 200
var current_health_e := max_health_e
var can_take_damage := true
var damage_timeout := 1.0

# AI and Combat variables
@export var detection_range := 20.0
@export var attack_range := 6.0
@export var move_speed := 5.0
@export var run_speed := 8.0
@export var attack_damage := 25.0
@export var attack_cooldown := 2.0


# Animation parametersdddd
const MOVEMENT_BLEND_PARAM = "parameters/Movement/blend_position"
const RUNNING_BLEND_PARAM = "parameters/Running/blend_position"
const LIGHT_BLEND_PARAM = "parameters/Light_Attack/blend_position"
const HEAVY_BLEND_PARAM = "parameters/Heavy_Attack/blend_position"

# References
@onready var animation_tree = $Node3D/darkfighter02/AnimationTree
@onready var attack_hitbox = $AttackHitbox
@onready var detection_area = $DetectionArea
@onready var health_bar_e = $"../DarkFighter/Camera3D/Enemy_Healthbar"



# State management
enum EnemyState {
	IDLE,
	MOVING,
	RUNNING,
	ATTACKING,
	HIT,
	DYING,
	DEAD
}

var current_state = EnemyState.IDLE
var player_target = null
var can_attack := true  # Inicializar como true
var attack_timer := 0.0
var state_machine
var is_attacking := false
var hit_recovery_timer := 0.0
var hit_recovery_time := 1.0

func _ready():
	if animation_tree:
		animation_tree.active = true
		state_machine = animation_tree.get("parameters/playback")
	
	if attack_hitbox:
		attack_hitbox.monitoring = false

	if health_bar_e:
		health_bar_e.max_health_e = max_health_e
		health_bar_e.current_health_e = max_health_e
		health_bar_e.displayed_health_e = max_health_e
		health_bar_e.update_health_bar() # Actualizar el shader

	# Inicializar temporizador de ataque
	attack_timer = attack_cooldown
	
	transition_to_state(EnemyState.IDLE)


func _physics_process(delta):
	update_timers(delta)
	process_current_state(delta)
	move_and_slide()

func update_timers(delta):
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	if hit_recovery_timer > 0:
		hit_recovery_timer -= delta
		if hit_recovery_timer <= 0 and current_state == EnemyState.HIT:
			if player_target and is_instance_valid(player_target):
				var distance = global_position.distance_to(player_target.global_position)
				if distance <= attack_range:
					if can_attack:
						transition_to_state(EnemyState.ATTACKING)
				elif distance <= detection_range:
					transition_to_state(EnemyState.MOVING)
				else:
					transition_to_state(EnemyState.IDLE)
			else:
				transition_to_state(EnemyState.IDLE)

func process_current_state(delta):
	match current_state:
		EnemyState.IDLE:
			process_idle_state(delta)
		EnemyState.MOVING:
			process_moving_state(delta)
		EnemyState.RUNNING:
			process_running_state(delta)
		EnemyState.ATTACKING:
			process_attacking_state(delta)
		EnemyState.HIT:
			process_hit_state(delta)
		EnemyState.DYING, EnemyState.DEAD:
			pass

func process_idle_state(delta):
	if player_target and is_instance_valid(player_target):
		var distance = global_position.distance_to(player_target.global_position)
		
		if distance <= attack_range and can_attack:
			transition_to_state(EnemyState.ATTACKING)
		elif distance <= detection_range:
			if distance > attack_range * 1.5:
				transition_to_state(EnemyState.RUNNING)
			else:
				transition_to_state(EnemyState.MOVING)

func process_moving_state(delta):
	if !player_target or !is_instance_valid(player_target):
		transition_to_state(EnemyState.IDLE)
		return
	
	var distance = global_position.distance_to(player_target.global_position)
	
	# CORRECCIÓN: Permitir transición a ATTACKING aunque can_attack sea false
	if distance <= attack_range:
		if can_attack:
			transition_to_state(EnemyState.ATTACKING)
			return
		elif distance <= attack_range and !can_attack:
			# Wait for attack cooldown
			velocity = Vector3.ZERO
			return
		
		if distance > detection_range:
			player_target = null
			transition_to_state(EnemyState.IDLE)
			return
		
		move_towards_player(move_speed, delta)


func process_running_state(delta):
	if !player_target or !is_instance_valid(player_target):
		transition_to_state(EnemyState.IDLE)
		return
	
	var distance = global_position.distance_to(player_target.global_position)
	
	# CORRECCIÓN: Permitir transición a ATTACKING aunque can_attack sea false
	if distance <= attack_range and can_attack:
		transition_to_state(EnemyState.ATTACKING)
		return
	elif distance <= attack_range and !can_attack:
		# Wait for attack cooldown
		velocity = Vector3.ZERO
		return
	
	if distance <= detection_range * 0.5:
		transition_to_state(EnemyState.MOVING)
		return
	
	if distance > detection_range:
		player_target = null
		transition_to_state(EnemyState.IDLE)
		return
	
	move_towards_player(run_speed, delta)

func process_attacking_state(delta):
	# Detener movimiento durante el ataque
	velocity = Vector3.ZERO

func process_hit_state(delta):
	velocity = velocity.lerp(Vector3.ZERO, 2.0 * delta)

func move_towards_player(speed: float, delta: float):
	if !player_target:
		return
	
	var direction = (player_target.global_position - global_position).normalized()
	direction.y = 0
	
	velocity = direction * speed
	
	if direction.length() > 0.1:
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)

func transition_to_state(new_state: EnemyState):
	match current_state:
		EnemyState.ATTACKING:
			end_attack()
	
	current_state = new_state
	
	match new_state:
		EnemyState.IDLE:
			state_machine.travel("Idle")
			velocity = Vector3.ZERO
		EnemyState.MOVING:
			state_machine.travel("Movement")
		EnemyState.RUNNING:
			state_machine.travel("Running")
		EnemyState.ATTACKING:
			start_attack()
		EnemyState.HIT:
			state_machine.travel("Impact")
			hit_recovery_timer = hit_recovery_time
		EnemyState.DYING:
			state_machine.travel("Death")
			velocity = Vector3.ZERO
			set_collision_layer_value(4, false) 
			set_collision_mask_value(2, false)
		EnemyState.DEAD:
			pass

func start_attack():
	if !can_attack:
		return
		
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown  # Reiniciar temporizador
	
	if randf() > 0.7:
		#var idx = clamp(heavy_attack_combo_count, 0, 2)
		state_machine.travel("Heavy_Attack")
		animation_tree.set(HEAVY_BLEND_PARAM, 0)
	else:
		state_machine.travel("Light_Attack")
		animation_tree.set(LIGHT_BLEND_PARAM, 0)
	
	await get_tree().create_timer(0.3).timeout
	if attack_hitbox and current_state == EnemyState.ATTACKING and is_instance_valid(self):
		attack_hitbox.monitoring = true

func end_attack():
	is_attacking = false
	attack_hitbox.monitoring = false

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO):
	if !can_take_damage or current_state in [EnemyState.DYING, EnemyState.DEAD]:
		return
		
	current_health_e -= amount
	can_take_damage = false
	
	if knockback.length() > 0:
		velocity = knockback
	
	if health_bar_e:
		health_bar_e.take_damage(amount)

	if current_health_e <= 0:
		transition_to_state(EnemyState.DYING)
		await get_tree().create_timer(2.5).timeout
		emit_signal("dead")
		queue_free()
	else:
		if current_state != EnemyState.DYING:
			transition_to_state(EnemyState.HIT)
		
		await get_tree().create_timer(damage_timeout).timeout
		can_take_damage = true



# Signal handlers
func _on_detection_area_body_entered(body: CharacterBody3D):
	if body.is_in_group("player"):
		player_target = body

func _on_detection_area_body_exited(body: CharacterBody3D):
	if body == player_target:
		player_target = null
		if current_state != EnemyState.ATTACKING:
			transition_to_state(EnemyState.IDLE)

func _on_attack_hitbox_body_entered(body: CharacterBody3D):
	if body.is_in_group("player") and body.has_method("take_damage") and is_instance_valid(body):
		transition_to_state(EnemyState.ATTACKING)
		await get_tree().create_timer(damage_timeout).timeout
		var hit_direction = (body.global_position - global_position).normalized()
		hit_direction.z = 0.2
		body.take_damage(attack_damage, hit_direction * 8.0)

func _on_animation_tree_animation_finished(anim_name: StringName):
	if current_state in [EnemyState.DYING, EnemyState.DEAD]:
		return
	
	match anim_name:
		"Ataque_Normal", "Ataque_Fuerte":
			end_attack()
			if player_target and is_instance_valid(player_target) and global_position.distance_to(player_target.global_position) <= attack_range:
				# Intentar otro ataque si el jugador sigue cerca
				if can_attack:
					transition_to_state(EnemyState.ATTACKING)
				else:
					transition_to_state(EnemyState.IDLE)
			else:
				transition_to_state(EnemyState.IDLE)
		"Impacto_Medio":
			transition_to_state(EnemyState.IDLE)
		"Muerte02":
			transition_to_state(EnemyState.DEAD)
