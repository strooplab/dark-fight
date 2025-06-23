extends RigidBody3D

@export var max_health := 100
var current_health := max_health
var can_take_damage := true
var damage_timeout := 0.5

func take_damage(amount: float):
	if not can_take_damage:
		return

	current_health -= amount
	can_take_damage = false
	$HealthBar.take_damage(amount)
	if current_health <= 0:
		queue_free()  # Desaparece el enemigo
	else:
		await get_tree().create_timer(damage_timeout).timeout
		can_take_damage = true
