extends MeshInstance3D

@export var health_bar_e: MeshInstance3D
@export var max_health_e := 100.0
@export var current_health_e := 100.0
var displayed_health_e := 10.0

var health_material: ShaderMaterial

func _ready():
	health_material = health_bar_e.get_active_material(0) as ShaderMaterial
	update_health_bar()

func update_health_bar():
	var porcentaje := displayed_health_e / max_health_e
	health_material.set_shader_parameter("porcentaje", porcentaje)

func take_damage(amount: float):
	current_health_e = max(current_health_e - amount, 0.0)
	animate_health_bar()

func animate_health_bar():
	if is_processing():
		return
	set_process(true)

func _process(delta):
	var speed = 9
	displayed_health_e = lerp(displayed_health_e, current_health_e, delta * speed)
	update_health_bar()

	if abs(displayed_health_e - current_health_e) < 0.01:
		displayed_health_e = current_health_e
		update_health_bar()
		set_process(false)
