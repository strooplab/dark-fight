extends Node3D

@onready var hud = $TitleScreen/Gameover
@onready var temp = $Jugadores/DarkFighter/Camera3D/Timer
@onready var jugador = $Jugadores/DarkFighter
@onready var enemigo = $Jugadores/Enemy

func _ready():
	if temp:
		temp.start_countdown()

func _on_enemy_dead() -> void:
	var pantalla_fin = preload("res://GameOver.tscn").instantiate()
	pantalla_fin._set_resultado( "¡VICTORIA!")
	add_child(pantalla_fin)
	temp.timer_completed()

func _on_dark_fighter_dead() -> void:
	var pantalla_fin = preload("res://GameOver.tscn").instantiate()
	pantalla_fin._set_resultado( "¡DERROTA!")
	add_child(pantalla_fin)
	temp.timer_completed()


func _on_timer_tiempo_agotado() -> void:
	var salud_jugador = jugador.current_health
	var salud_enemigo = enemigo.current_health_e
	
	var pantalla_fin = preload("res://GameOver.tscn").instantiate()
	
	if salud_jugador > salud_enemigo:
		pantalla_fin.resultado = "¡VICTORIA!"
	elif salud_enemigo > salud_jugador:
		pantalla_fin.resultado = "¡DERROTA!"
	
	add_child(pantalla_fin)
	temp.timer_completed()
