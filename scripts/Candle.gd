class_name Candle
extends CharacterBody2D

## Candelabro. Se usa tanto para el que lleva el player (held = true)
## como para los candelabros del nivel (held = false).

@export var lit := true
@export var held := false

@onready var sprite: AnimatedSprite2D = $sprite
@onready var detector: Area2D = $detector
@onready var light: PointLight2D = $light


func _ready():
	add_to_group("candles")
	if held:
		# Choca solo con paredes y detecta goteras / otros candelabros
		collision_layer = Global.LAYER_HELD_CANDLE
		collision_mask = Global.LAYER_WALLS
		detector.collision_layer = 0
		detector.collision_mask = Global.LAYER_TRIGGERS
		detector.monitoring = true
	else:
		# Bloquea al player, pero no al candelabro que lleva (se superponen)
		collision_layer = Global.LAYER_CANDLES
		collision_mask = 0
		detector.collision_layer = Global.LAYER_TRIGGERS
		detector.collision_mask = 0
		detector.monitoring = false
	refresh()


func light_up():
	if lit:
		return
	lit = true
	refresh()


func put_out():
	if not lit:
		return
	lit = false
	refresh()


func refresh():
	sprite.play("lit" if lit else "off")
	light.enabled = lit


## Solo para el candelabro del player: resuelve la celda donde quedo apoyado.
func check_overlaps():
	var areas := detector.get_overlapping_areas()
	# 1) Gotera: apaga si o si
	for area in areas:
		if area is Drip:
			put_out()
	# 2) Candelabros del nivel: se pasa el fuego en cualquier sentido
	for area in areas:
		var other = area.get_parent()
		if other is Candle and other != self:
			if lit and not other.lit:
				other.light_up()
			elif not lit and other.lit:
				light_up()
