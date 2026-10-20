extends Node
var FULLSCREEN = false
var GAMEOVER = false

# ---------------- Grilla y tiempos ----------------
const CELL := 32
const MOVE_TIME := 0.2   # duracion de un paso (segundos)
const ROTATE_TIME := 0.2   # duracion de una rotacion (segundos)
const GRAB_TIME := 0.2   # duracion del feedback al agarrar / soltar el candelabro (segundos)

# ---------------- Direcciones ----------------
enum Dir { RIGHT, DOWN, LEFT, UP }

const DIR_VECTORS := {
	Dir.RIGHT: Vector2i(1, 0),
	Dir.DOWN: Vector2i(0, 1),
	Dir.LEFT: Vector2i(-1, 0),
	Dir.UP: Vector2i(0, -1),
}

# ---------------- Capas de fisica (bits) ----------------
# 1: paredes | 2: player | 3: candelabros del nivel | 4: candelabro del player | 5: triggers (goteras, detectores)
const LAYER_WALLS := 1
const LAYER_PLAYER := 2
const LAYER_CANDLES := 4
const LAYER_HELD_CANDLE := 8
const LAYER_TRIGGERS := 16

# ---------------- Niveles ----------------
# Se cargan solos todos los .tscn de LEVELS_DIR, ordenados por nombre
# (orden natural: Level2 va antes que Level10). No hace falta tocar codigo.
const LEVELS_DIR := "res://scenes/levels"
var levels: Array[String] = []
var current_level := 0

# Referencias a los objetos activos (las setean ellos mismos en _ready)
var main = null
var level = null
var player = null


func init_vars():
	levels = load_levels()
	current_level = 0
	GAMEOVER = false


func _ready():
	#Load music and SFX
	#Initialize variables
	init_vars()


func dir_vector(dir: Dir) -> Vector2:
	return Vector2(DIR_VECTORS[dir])


func dir_angle(dir: Dir) -> float:
	return dir_vector(dir).angle()


func is_opposite(a: Dir, b: Dir) -> bool:
	return DIR_VECTORS[a] == -DIR_VECTORS[b]


## Centro (en pixeles) de una celda de la grilla
func cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL) + Vector2(CELL, CELL) / 2.0


## Celda de la grilla que contiene una posicion en pixeles
func pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / CELL).floor())


## Lista los niveles de LEVELS_DIR. En un juego exportado las escenas aparecen
## como ".tscn.remap", por eso se limpia esa extension.
func load_levels() -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(LEVELS_DIR):
		file = file.trim_suffix(".remap")
		if file.ends_with(".tscn") and not found.has(file):
			found.append(file)
	found.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	var paths: Array[String] = []
	for file in found:
		paths.append(LEVELS_DIR + "/" + file)
	return paths


func next_level():
	current_level = (current_level + 1) % levels.size()
	if main:
		main.load_level()


func restart_level():
	if main:
		main.load_level()


func play_sound(stream: AudioStream, options:= {}, _global_position = null, delay = 0.0) -> AudioStreamPlayer:
	var audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(audio_stream_player)
	audio_stream_player.stream = stream
	audio_stream_player.bus = "SFX"

	for prop in options.keys():
		audio_stream_player.set(prop, options[prop])

	if delay > 0.0:
		var timer = Timer.new()
		timer.wait_time = delay
		timer.one_shot = true
		timer.connect("timeout", audio_stream_player.play)
		add_child(timer)
		timer.start()
	else:
		audio_stream_player.play()

	audio_stream_player.finished.connect(kill.bind(audio_stream_player))

	return audio_stream_player

func kill(_audio_stream_player):
	if _audio_stream_player and is_instance_valid(_audio_stream_player):
		_audio_stream_player.queue_free()
