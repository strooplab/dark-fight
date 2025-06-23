extends CanvasLayer

@onready var boton_comenzar = $CenterContainer/VBoxContainer/StartButton

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	boton_comenzar.grab_focus()
	$Background.modulate = Color(1, 1, 1, 0)
	boton_comenzar.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property($Background, "modulate", Color(1, 1, 1, 1), 0)
	tween.parallel().tween_property(boton_comenzar, "modulate", Color(1, 1, 1, 1), 1.0).set_delay(0.5)
	boton_comenzar.connect("pressed", _on_comenzar_pressed)

func _on_comenzar_pressed():
	boton_comenzar.disabled = true
	var tween = create_tween()
	tween.tween_property($Background, "modulate:a", 0, 0.5)
	tween.parallel().tween_property(boton_comenzar, "modulate:a", 0, 0.5)
	await tween.finished

	get_tree().change_scene_to_file("res://Main.tscn")
