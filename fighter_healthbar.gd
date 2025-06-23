extends MeshInstance3D

@export var health_bar: MeshInstance3D
@export var max_health := 100.0
@export var current_health := 100.0
var displayed_health := 10.0

var health_material: ShaderMaterial

func _ready():
	health_material = health_bar.get_active_material(0) as ShaderMaterial
	update_health_bar()

func update_health_bar():
	var porcentaje := displayed_health / max_health
	health_material.set_shader_parameter("porcentaje", porcentaje)

func take_damage(amount: float):
	current_health = max(current_health - amount, 0.0)
	animate_health_bar()

func animate_health_bar():
	if is_processing():
		return
	set_process(true)

func _process(delta):
	var speed = 9
	displayed_health = lerp(displayed_health, current_health, delta * speed)
	update_health_bar()

	if abs(displayed_health - current_health) < 0.01:
		displayed_health = current_health
		update_health_bar()
		set_process(false)
