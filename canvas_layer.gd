extends CanvasLayer

func _ready():
	# Hacer que el botón sea el foco inicial
	$StartButton.grab_focus()
	
	# Efecto de aparición gradual
	$Background.modulate = Color(1, 1, 1, 0)
	$StartButton.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property($Background, "modulate", Color(1, 1, 1, 1), 0)
	tween.parallel().tween_property($StartButton, "modulate", Color(1, 1, 1, 1), 1.0).set_delay(0.5)

func _on_start_button_pressed() -> void:
	# Deshabilitar botón durante la transición
	$StartButton.disabled = true
	
	# Transición de fade out
	var tween = create_tween()
	tween.tween_property($Background, "modulate:a", 0, 0.5)
	tween.parallel().tween_property($StartButton, "modulate:a", 0, 0.5)
	await tween.finished
	
	# Remover completamente el CanvasLayer antes de cambiar de escena
	queue_free()
	
	# Cambiar a la escena principal del juego
	get_tree().change_scene_to_file("res://World.tscn")
