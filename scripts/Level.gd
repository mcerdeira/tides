class_name Level
extends Node2D

## Raiz de cada nivel. Los objetos (Wall, Candle, Drip, Door, Player) se
## instancian como hijos alineados a la grilla (centro de celda = n*32 + 16).


func _ready():
	Global.level = self
	update_door.call_deferred()
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("SKIP_LEVEL"):
		Global.next_level()

## Abre las puertas si todos los candelabros estan encendidos (incluido el nuestro)
func update_door():
	var all_lit := true
	for candle in get_tree().get_nodes_in_group("candles"):
		if not candle.lit:
			all_lit = false
	for door in get_tree().get_nodes_in_group("doors"):
		door.set_open(all_lit)


## Devuelve el candelabro apoyado en el nivel (no el del player) en esa celda
func get_candle_at(cell: Vector2i) -> Candle:
	for candle in get_tree().get_nodes_in_group("candles"):
		if not candle.held and Global.pos_to_cell(candle.global_position) == cell:
			return candle
	return null


## Devuelve la puerta ABIERTA donde esta parado el player (las cerradas no cuentan)
func get_open_door_under_player() -> Door:
	for door in get_tree().get_nodes_in_group("doors"):
		if door.is_open and door.is_player_on():
			return door
	return null


## Rectangulo (en pixeles) que ocupa el nivel, calculado a partir de las paredes
func get_bounds() -> Rect2:
	var rect := Rect2()
	var first := true
	for wall in get_tree().get_nodes_in_group("walls"):
		var cell_rect := Rect2(wall.global_position - Vector2(Global.CELL, Global.CELL) / 2.0, Vector2(Global.CELL, Global.CELL))
		if first:
			rect = cell_rect
			first = false
		else:
			rect = rect.merge(cell_rect)
	return rect
