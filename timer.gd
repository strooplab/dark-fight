extends MeshInstance3D
signal tiempo_agotado
@export var initial_time: int = 99  # Tiempo inicial configurable desde el editor
var tiempo_activo = false
var current_time: int

@onready var countdown_timer: Timer = $Timer

func _ready():
	current_time = initial_time
	update_display()
	countdown_timer.timeout.connect(_on_timer_timeout)

func start_countdown():
	tiempo_activo = true
	#countdown_timer.timeout.connect(_on_timer_timeout)
	countdown_timer.start()

func _on_timer_timeout():
	if tiempo_activo and initial_time > 0:	
		current_time -= 1
	update_display()
	
	if current_time <= 0:
		emit_signal("tiempo_agotado")
		timer_completed()

func update_display():
	if mesh is TextMesh:
		mesh.text = str(current_time)
		if current_time <= 10:
			mesh.material_override.albedo_color = Color.RED
	else:
		push_error("El Mesh asignado no es un TextMesh")

func timer_completed():
	tiempo_activo = false
	countdown_timer.stop()
