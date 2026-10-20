class_name Drip
extends Area2D

## Gotera: si el candelabro del player queda sobre ella, se apaga.
## La logica la resuelve Candle.check_overlaps().

@onready var sprite: AnimatedSprite2D = $sprite


func _ready():
	collision_layer = Global.LAYER_TRIGGERS
	collision_mask = 0
	sprite.play("default")
