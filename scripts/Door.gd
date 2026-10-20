class_name Door
extends Area2D

## Puerta (trampilla en el piso). Empieza cerrada y se abre cuando todos los
## candelabros del nivel (incluido el del player) estan encendidos.
## Si el player se para sobre ella estando abierta, baja al siguiente nivel.

var is_open := false
var used := false

@onready var sprite: AnimatedSprite2D = $sprite


func _ready():
	add_to_group("doors")
	collision_layer = 0
	collision_mask = Global.LAYER_PLAYER
	close()


func open():
	is_open = true
	sprite.play("open")


func close():
	is_open = false
	sprite.play("closed")


func set_open(value: bool):
	if value and not is_open:
		open()
	elif not value and is_open:
		close()


func is_player_on() -> bool:
	return Global.player != null and Global.player in get_overlapping_bodies()


func enter():
	if used or not is_open:
		return
	used = true
	await Global.player.descend()
	Global.next_level()
