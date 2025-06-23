extends CanvasLayer
var _resultado = "¡GANASTE!"
@onready var etiqueta_resultado = $CenterContainer/VBoxContainer/Resultado
@onready var boton_reintentar = $CenterContainer/VBoxContainer/BotonReintentar
@onready var boton_menu = $CenterContainer/VBoxContainer/BotonMenu

func _ready():
	etiqueta_resultado.text = _resultado
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	boton_reintentar.grab_focus()

func _set_resultado(valor):
	_resultado = valor
	if etiqueta_resultado:
		etiqueta_resultado.text = valor

func _on_reintentar_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Menu_Principal.tscn")
	
