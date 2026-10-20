extends Node2D

## Escena principal: carga el nivel actual (Global.levels[Global.current_level])
## y acomoda la camara. Si el nivel entra en pantalla se centra y se hace zoom
## entero (pixel perfect); si no entra, la camara sigue al player.

const MAX_ZOOM := 4

var level: Node2D = null

@onready var camera: Camera2D = $Camera2D


func _ready():
	Global.main = self
	load_level()


func load_level():
	if level:
		remove_child(level)
		level.queue_free()
	Global.player = null
	Global.level = null
	level = load(Global.levels[Global.current_level]).instantiate()
	add_child(level)
	setup_camera()


func setup_camera():
	var bounds: Rect2 = level.get_bounds()
	var view := get_viewport_rect().size
	var zoom := floorf(minf(view.x / bounds.size.x, view.y / bounds.size.y))
	zoom = clampf(zoom, 1.0, MAX_ZOOM)
	camera.zoom = Vector2(zoom, zoom)
	camera.position = bounds.get_center()


func _process(_delta):
	if Input.is_action_just_pressed("restart"):
		Global.restart_level()
		return
	if level == null or Global.player == null:
		return
	var bounds: Rect2 = level.get_bounds()
	var visible_size := get_viewport_rect().size / camera.zoom
	if bounds.size.x > visible_size.x or bounds.size.y > visible_size.y:
		var target: Vector2 = Global.player.global_position
		var half := visible_size / 2.0
		if bounds.size.x > visible_size.x:
			camera.position.x = clampf(target.x, bounds.position.x + half.x, bounds.end.x - half.x)
		if bounds.size.y > visible_size.y:
			camera.position.y = clampf(target.y, bounds.position.y + half.y, bounds.end.y - half.y)
