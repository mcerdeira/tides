@tool
class_name Wall
extends StaticBody2D

## Pared: bloquea al player y a su candelabro.
##
## `look` elige el sprite (perspectiva 3/4: techo plano + cara de ladrillos hacia el piso):
## - "auto": lo elige solo segun donde este el interior del nivel (ver interior_cells).
## - north/south/west/east: pared de ese lado de la sala (la cara mira hacia el piso).
## - corner_*: esquina de la sala (ej. corner_nw = esquina noroeste).
## - convex_*: esquina que sobresale hacia la sala (ej. convex_se = piso al sur y al este).
## - fill: solo techo, para paredes sin piso alrededor.
## En el editor se actualiza al cambiar `look` o al mover la pared.

@export_enum("auto", "fill", "north", "south", "west", "east",
		"corner_nw", "corner_ne", "corner_sw", "corner_se",
		"convex_nw", "convex_ne", "convex_sw", "convex_se") var look: String = "auto":
	set(value):
		look = value
		if is_node_ready():
			refresh()

@onready var sprite: AnimatedSprite2D = $sprite


func _ready():
	refresh()
	if Engine.is_editor_hint():
		set_notify_transform(true)
		return
	add_to_group("walls")
	collision_layer = Global.LAYER_WALLS
	collision_mask = 0


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_node_ready():
		refresh_all()


func refresh():
	sprite.play(auto_look() if look == "auto" else look)


## Refresca todas las paredes del nivel (en el editor, al mover una cambian sus vecinas)
func refresh_all():
	if owner == null:
		refresh()
		return
	for wall in owner.find_children("*", "Wall"):
		if wall.is_node_ready():
			wall.refresh()


func auto_look() -> String:
	var interior := interior_cells()
	var cell := cell_of(self)
	var n := interior.has(cell + Vector2i.UP)
	var s := interior.has(cell + Vector2i.DOWN)
	var e := interior.has(cell + Vector2i.RIGHT)
	var w := interior.has(cell + Vector2i.LEFT)
	if s and e: return "convex_se"
	if s and w: return "convex_sw"
	if n and e: return "convex_ne"
	if n and w: return "convex_nw"
	if s: return "north"
	if n: return "south"
	if e: return "west"
	if w: return "east"
	if interior.has(cell + Vector2i(1, 1)): return "corner_nw"
	if interior.has(cell + Vector2i(-1, 1)): return "corner_ne"
	if interior.has(cell + Vector2i(1, -1)): return "corner_sw"
	if interior.has(cell + Vector2i(-1, -1)): return "corner_se"
	return "fill"


func cell_of(node: Node2D) -> Vector2i:
	var pos: Vector2 = owner.to_local(node.global_position) if owner else node.position
	return Vector2i((pos / 32.0).floor())


## Celdas del interior del nivel: las celdas sin pared a las que se llega
## (en 4 direcciones) desde el Player, candelabros, goteras o puertas.
## La busqueda no sale del rectangulo que forman las paredes.
func interior_cells() -> Dictionary:
	var result := {}
	if owner == null:
		return result
	var walls := {}
	var seeds: Array[Vector2i] = []
	for node in owner.find_children("*", "Node2D"):
		if node is Wall:
			walls[cell_of(node)] = true
		elif node is Player or node is Candle or node is Drip or node is Door:
			seeds.append(cell_of(node))
	if walls.is_empty():
		return result
	var min_c: Vector2i = walls.keys()[0]
	var max_c: Vector2i = min_c
	for c in walls:
		min_c = min_c.min(c)
		max_c = max_c.max(c)
	var stack := seeds.duplicate()
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if result.has(c) or walls.has(c):
			continue
		if c.x < min_c.x or c.y < min_c.y or c.x > max_c.x or c.y > max_c.y:
			continue
		result[c] = true
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			stack.append(c + d)
	return result
