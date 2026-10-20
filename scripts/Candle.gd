@tool
class_name Candle
extends CharacterBody2D

## Candelabro. Se usa tanto para el que lleva el player (held = true)
## como para los candelabros del nivel (held = false).
## Solo se puede agarrar por un asa (handle). `handles` dice que asas tiene,
## en direcciones locales del candelabro (sin rotar: Left = asa a la izquierda).

@export var lit := true:
	set(value):
		lit = value
		if is_node_ready():
			refresh()
@export var held := false
@export_flags("Right", "Down", "Left", "Up") var handles := 4:  # Left
	set(value):
		handles = value
		if is_node_ready():
			refresh_handles()

# Indices = Global.Dir (RIGHT, DOWN, LEFT, UP). Sin usar Global porque el
# script corre en el editor (@tool) y ahi el autoload no existe.
const HANDLE_NODES := ["handles/right", "handles/down", "handles/left", "handles/up"]

@onready var sprite: AnimatedSprite2D = $sprite
@onready var detector: Area2D = $detector
@onready var light: PointLight2D = $light
@onready var handle_sprites: Node2D = $handles


func _ready():
	refresh()
	refresh_handles()
	if Engine.is_editor_hint():
		return
	add_to_group("candles")
	set_held(held)


## Configura las capas segun si lo lleva el player o esta apoyado en el nivel
func set_held(value: bool):
	held = value
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


func refresh_handles():
	for dir in HANDLE_NODES.size():
		get_node(HANDLE_NODES[dir]).visible = handles & (1 << dir) != 0


## true si tiene un asa que apunta (en coordenadas globales) hacia world_dir
func has_handle_towards(world_dir: Vector2) -> bool:
	for dir in HANDLE_NODES.size():
		if handles & (1 << dir) and Global.dir_vector(dir).rotated(global_rotation).round() == world_dir:
			return true
	return false


## Feedback al soltarlo: cae al piso desde un poco mas grande y rebota.
## Solo se animan los sprites (no el cuerpo fisico, para no escalar la colision).
func play_drop():
	await pop(Vector2(1.3, 1.3), Color(1, 1, 1))


## Feedback al agarrarlo: se "levanta" (crece con rebote) y brilla un instante.
func play_grab():
	await pop(Vector2(0.7, 0.7), Color(1.8, 1.8, 1.8))


func pop(from_scale: Vector2, from_color: Color):
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for node in [sprite, handle_sprites]:
		node.scale = from_scale
		tween.tween_property(node, "scale", Vector2.ONE, Global.GRAB_TIME)
	modulate = from_color
	tween.tween_property(self, "modulate", Color(1, 1, 1), Global.GRAB_TIME)
	await tween.finished


## Feedback de accion invalida (soltarlo sobre otro / agarrarlo sin asa): tiembla.
func shake():
	var tween := create_tween()
	tween.tween_method(set_shake, 1.0, 0.0, Global.GRAB_TIME)
	await tween.finished


func set_shake(amount: float):
	var offset := Vector2(sin(amount * TAU * 3.0) * 3.0 * amount, 0).round()
	sprite.position = offset
	handle_sprites.position = offset


## Solo para el candelabro del player: true si esta encima de otro candelabro
func is_over_candle() -> bool:
	for area in detector.get_overlapping_areas():
		var other = area.get_parent()
		if other is Candle and other != self:
			return true
	return false


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
