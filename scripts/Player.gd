@tool
class_name Player
extends CharacterBody2D

## Monje. Se mueve de a una celda, por "turnos":
## - Si se presiona la direccion a la que mira: avanza una celda (0.5s).
## - Si se presiona una direccion perpendicular: rota 90 grados (0.5s), sin avanzar.
## - Si se presiona la direccion opuesta: retrocede una celda de reversa (0.5s),
##   sin girar, con el candelabro siempre adelante.
## - Con "grab" (Z) suelta el candelabro en la celda de adelante, o agarra el
##   candelabro que tiene adelante si le apunta un asa.
## Mientras dura una animacion no se acepta ninguna otra accion.

@export var facing: Global.Dir = Global.Dir.RIGHT
## false = arranca sin candelabro (en el editor se oculta el que trae la escena)
@export var has_candle := true:
	set(value):
		has_candle = value
		if is_node_ready() and candle:
			candle.visible = has_candle

var busy := false
var leaving := false  # true mientras baja por la puerta

const ACTIONS := {
	"move_right": Global.Dir.RIGHT,
	"move_down": Global.Dir.DOWN,
	"move_left": Global.Dir.LEFT,
	"move_up": Global.Dir.UP,
}

@onready var pivot: Node2D = $pivot
@onready var sprite: AnimatedSprite2D = $pivot/sprite
@onready var candle: Candle = $pivot/Candle  # null si no lleva ninguno


func _ready():
	if Engine.is_editor_hint():
		candle.visible = has_candle
		return
	Global.player = self
	collision_layer = Global.LAYER_PLAYER
	collision_mask = Global.LAYER_WALLS | Global.LAYER_CANDLES
	pivot.rotation = Global.dir_angle(facing)
	sprite.play("idle")
	if not has_candle:
		candle.queue_free()
		candle = null
	# Resolver la celda inicial del candelabro (por si arranca sobre algo)
	resolve.call_deferred()


func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	if busy or leaving:
		return
	if Input.is_action_just_pressed("grab"):
		if candle:
			try_drop()
		else:
			try_grab()
		return
	for action in ACTIONS:
		if Input.is_action_pressed(action):
			var dir: Global.Dir = ACTIONS[action]
			if dir == facing:
				try_move(dir)
				return
			elif Global.is_opposite(dir, facing):
				try_move(dir)  # reversa
				return
			else:
				try_rotate(dir)
				return


## Avanza (dir == facing) o retrocede de reversa (dir opuesta) una celda.
## El player y su candelabro deben tener la celda destino libre.
func try_move(dir: Global.Dir):
	var motion := Global.dir_vector(dir) * Global.CELL
	if test_move(global_transform, motion):
		return
	if candle and candle.test_move(candle.global_transform, motion):
		return

	busy = true
	if dir == facing:
		sprite.play("walk")
	else:
		sprite.play_backwards("walk")
	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + motion, Global.MOVE_TIME)
	await tween.finished
	sprite.play("idle")
	await resolve()
	busy = false


func try_rotate(dir: Global.Dir):
	# El candelabro describe un arco: pasa por la celda diagonal y termina en
	# la celda de la nueva direccion. Ambas deben estar libres de paredes.
	if candle:
		var start := candle.global_position
		var diagonal := global_position + (Global.dir_vector(facing) + Global.dir_vector(dir)) * Global.CELL
		var target := global_position + Global.dir_vector(dir) * Global.CELL
		if candle.test_move(Transform2D(0.0, start), diagonal - start):
			return
		if candle.test_move(Transform2D(0.0, diagonal), target - diagonal):
			return

	busy = true
	var from_angle := pivot.rotation
	var delta := wrapf(Global.dir_angle(dir) - from_angle, -PI, PI)
	var tween := create_tween()
	tween.tween_property(pivot, "rotation", from_angle + delta, Global.ROTATE_TIME)
	await tween.finished
	facing = dir
	pivot.rotation = Global.dir_angle(dir)
	await resolve()
	busy = false


## Se llama cada vez que termina un movimiento o rotacion.
func resolve():
	# Esperar a que las areas actualicen las superposiciones
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree() or Global.level == null:
		return
	if candle:
		candle.check_overlaps()
	Global.level.update_door()
	var door = Global.level.get_open_door_under_player()
	if door:
		leaving = true
		door.enter()


## Deja el candelabro en la celda de adelante (no se puede sobre otro candelabro).
## Queda en el nivel como un candelabro mas: bloquea al player.
func try_drop():
	busy = true
	if candle.is_over_candle():
		await candle.shake()
		busy = false
		return
	var dropped := candle
	candle = null
	dropped.reparent(Global.level)
	dropped.global_position = Global.cell_to_pos(Global.pos_to_cell(dropped.global_position))
	dropped.global_rotation = snappedf(dropped.global_rotation, PI / 2.0)
	dropped.set_held(false)
	await dropped.play_drop()
	busy = false


## Agarra el candelabro de la celda de adelante, solo si tiene un asa que
## apunta hacia el player.
func try_grab():
	var front := global_position + Global.dir_vector(facing) * Global.CELL
	var target: Candle = Global.level.get_candle_at(Global.pos_to_cell(front))
	if target == null:
		return
	busy = true
	# Sin asa de este lado: el candelabro tiembla y no se agarra
	if not target.has_handle_towards(-Global.dir_vector(facing)):
		await target.shake()
		busy = false
		return
	target.reparent(pivot)
	target.position = Vector2(Global.CELL, 0)
	target.rotation = snappedf(target.rotation, PI / 2.0)
	target.set_held(true)
	candle = target
	await candle.play_grab()
	await resolve()
	busy = false


## Animacion de bajar por la trampilla
func descend():
	leaving = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
