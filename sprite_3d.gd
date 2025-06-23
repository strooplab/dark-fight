extends Sprite3D

signal no_hp_left
@export var max_hp : int = 100
@onready var timer = $SubViewport/Barra_DF01/Timer
@onready var health_bar = $SubViewport/Barra_DF01
@onready var damage_bar = $SubViewport/Barra_DF01/DamageBar
# Called when the node enters the scene tree for the first time.
var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(health_bar.max_value, new_health)
	health_bar.value = health
	
	if health <= 0:
		health_bar.queue_free()
	
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

func init_health(_health):
	health = _health
	health_bar.max_value = health
	health_bar.value = health
	damage_bar.max_value = health
	damage_bar.value = health	


func _on_timer_timeout() -> void:
	damage_bar.value = health
	
func take_damage(damage: float):
	health_bar.value -= damage
	if health_bar.value <= 0.1:
		no_hp_left.emit()
