# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project
Este  es un juego 2D top down de puzzles. Manejas a un monje en un dungeon donde que lleva un candelabro con una vela encendida. 
La premisa es, todo en grilla de 32x32, el jugador ocupa una celda y el candelabro otra celda extra, el candelabro siempre lo tenemos adelante (el personaje lo está tomando con las manos) al movernos lo hacemos 
alineados a la grilla, es un grid based movement.

## Gameplay
El objetivo del juego es encender los candelabros que hay por el nivel para que se abra la puerta del dungeon y poder bajar al siguiente piso. 
Los niveles pueden tener diferentes tamaños, no necesariamente siempre va a ocupar el 100% de la pantalla.
Si el candelabro que llevamos se superpone con uno de los candelabros que hay en el nivel:
- Si nuestro candelabro esta encendido y el otro apagado, se enciende el otro
- Si nuestro candelabro está apagado y el otro encendido, se enciende el nuestro
- Si ambos están apagados, no sucede nada
- Si ambos están encendidos, no sucede nada

Hay puntos en el nivel (siempre todo ocupa 1 celda) donde hay una gotera, si nuestro candelabro se posa ahi, se apaga (no hay una cuestión de timing, se apaga si o si)
El candelabro colisiona con la pared, ni nosotros ni el candelabro pueden atravesarla

### Agarrar y soltar candelabros
- Con un boton (tecla `Z`, accion `grab`) se suelta el candelabro que llevamos: queda apoyado en la celda de adelante. El monje se sigue moviendo igual, pero sin candelabro.
- Si no llevamos ninguno, el mismo boton agarra el candelabro que tenemos adelante.
- Solo se puede agarrar un candelabro por un asa (handle): tiene que haber un asa apuntando hacia el monje. No vale agarrarlo de cualquier lado.
- Los candelabros pueden tener 1, 2, 3 o 4 asas (configurable desde el editor).
- Los candelabros apoyados en el nivel son obstaculos: el monje no puede atravesarlos.
- No se puede soltar un candelabro si esta encima de otro.

## Movimiento
El moviento es siempre en grilla, como si fuera por turnos. 
Si apuntamos a una dirección no podemos cambiar a la dirección opuesta, siempre debemos hacer la rotación. Ejemplo: Si apuntamos a la derecha, para ir a la izquierda debemos primero girar arriba y luego a la izquierda (o abajo y luego a la izquierda)
Lo mismo aplica con todas las direcciones. 
Si se presiona la direccion opuesta a la que miramos, se retrocede una celda de reversa: no se gira, el candelabro sigue adelante. Ejemplo: mirando a la derecha, presionar izquierda nos mueve una celda a la izquierda sin dejar de mirar a la derecha.
Si cambiamos la direccion, cualquiera sea, primero se rota a esa dirección, luego se avanza.
La rotación no es instantanea, se reproduce una animacion (durante la cual no podemos realizar ninguna acción), la misma debe ser muy rapida, de 0.5 segundos.
Lo mismo aplica para caminar, se debe ver una animación de 0.5 segundos durantes los cuales no podemos movernos ni rotar. No es un juego de acción! Es un puzzle.

## Implementacion
- Player se debe implementar como un characterbody2d
- Pared debe ser un Staticbody 
- Los candelabros se tienen que poder superponer entre si:
  - Se pueden implementar como characterbody2d con diferentes masks para que no colisionen entre si
  - Se les puede sumar un area2D interno para detectar la superposicion
- La puerta puede ser un area2D y tiene 2 estados (abierta y cerrada) inicia siempre cerrada y solo se abre si todos los candelabros están encendidos (incluido el nuestro)


## Elementos

- Player (nuestro monje que se mueve de a 1 celda)
- Candelabro (que lleva nuestro jugador)
- Candelabros del nivel
- Gotera (que nos apaga el candelabro)
- Pared (bloques que no se pueden atravezar por el personaje)
- Puerta (la que si nos posicionamos sobre ella, nos traslada al siguiente nivel)


## Running / editing

- Open the project in the Godot editor: `godot -e --path .` (or just open `project.godot` with the Godot 4.7 editor).
- Run the game headless from the CLI: `godot --path .`
- The main scene is set via `run/main_scene` in `project.godot` (currently `scenes/Main.tscn`, que carga el nivel actual de `Global.levels`).
- Controles: flechas o WASD para moverse/rotar, `Z` para agarrar/soltar el candelabro, `R` para reiniciar el nivel (acciones `move_*`, `grab` y `restart` en el Input Map).
- There is no automated test suite, linter, or CI config in this repo — verify changes by running the game in the editor. Para chequear errores de parseo sin abrir el editor: `godot --headless --path . --import`.
- `.godot/` is the editor's generated cache (gitignored) — never hand-edit files there.

## Architecture

### Global autoload (`global_scripts/Global.gd`)
Existen scripts globales en la carpeta global_scripts que son Global y Music. Music tiene todo lo relativo a reproducir musica en el juego, Global tiene el metodo para reproducir SFX.
Global ademas guarda todo tipo de estados y de enums del juego. Mi estilo de hacer juegos en Godot hace uso fuerte de variables globales.

Global contiene: `CELL` (32), `MOVE_TIME` / `ROTATE_TIME` (0.5s), el enum `Dir` (RIGHT, DOWN, LEFT, UP) y helpers
(`dir_vector`, `dir_angle`, `is_opposite`, `cell_to_pos`, `pos_to_cell`), las capas de fisica (`LAYER_*`), la lista
de niveles `levels` (se arma sola desde `LEVELS_DIR`) + `current_level`, y referencias a `main`, `level` y `player` (cada objeto se registra solo en su `_ready`).
`Global.next_level()` avanza al siguiente nivel (al terminar el ultimo vuelve al primero) y `Global.restart_level()` reinicia.

### Estructura de carpetas
- `scenes/` una escena por objeto: `Main`, `Player`, `Candle`, `Drip`, `Door`, `Wall`.
- `scenes/levels/` los niveles (`Level1.tscn`, ...). Se cargan solos: `Global.load_levels()` lista todos los `.tscn` de la carpeta y los ordena por nombre en orden natural (`Level2` antes que `Level10`). Para agregar un nivel solo hay que guardar la escena ahi.
- `scripts/` los scripts de cada escena, con el mismo nombre que la escena (`Player.gd`, `Candle.gd`, ...). `Level.gd` es el script comun a todos los niveles.
- `global_scripts/` autoloads (`Global`, `Music`).
- `sprites/<entidad>/` los png (ver skill art-maker). `sprites/examples` y `sprites/color-palette` son referencia de estilo.
- `tilesets/Dungeon.tres` tileset del piso (solo visual, sin colision).

### Como armar un nivel
- Root `Node2D` con `scripts/Level.gd`.
- (Opcional) un `TileMapLayer` con el tileset `Dungeon.tres` para pintar el piso (z_index -10).
- Instanciar `Wall`, `Candle` (`lit` define si arranca encendido, `handles` que asas tiene), `Drip`, `Door` y un `Player` (`facing` define hacia donde mira, `has_candle = false` lo hace arrancar sin candelabro: en el editor se oculta y en runtime se borra). `Player.gd` es `@tool` solo para eso: en el editor no corre `_ready` ni `_physics_process`.
- Todo va centrado en su celda: posicion = celda * 32 + 16. El candelabro del player queda automaticamente en la celda de adelante.
- El rectangulo del nivel se calcula con las paredes. Si entra en pantalla se centra con zoom entero (hasta x4); si no, la camara sigue al player.

### Reglas implementadas (decisiones tomadas)
- Presionar la direccion a la que se mira = avanzar. Direccion perpendicular = rotar 90 grados (sin avanzar; si se mantiene apretada, despues avanza). Direccion opuesta = retroceder de reversa (sin girar; el walk se reproduce al reves).
- Para avanzar o retroceder, tanto la celda destino del player como la de su candelabro (si lleva uno) tienen que estar libres de paredes. No hay excepciones (tampoco para la puerta).
- Al rotar, el candelabro describe un arco: la celda diagonal y la celda destino deben estar libres de paredes, si no, no se puede rotar.
- El player no puede pararse sobre un candelabro del nivel (lo bloquea). El candelabro del player si se superpone con ellos.
- Agarrar/soltar (`grab`, tecla Z), en `Player.try_drop()` / `Player.try_grab()`:
  - Soltar: el candelabro se reparenta al nivel en su celda (rotacion redondeada a 90 grados) y pasa a ser un candelabro del nivel (`Candle.set_held(false)`), que bloquea al player. No se puede soltar si esta superpuesto con otro candelabro (`Candle.is_over_candle()`). Se puede soltar sobre una gotera o la puerta.
  - Agarrar: solo si no se lleva ninguno y hay un candelabro en la celda de adelante (`Level.get_candle_at()`) con un asa que apunte al player (`Candle.has_handle_towards()`). Se reparenta al `pivot` en (32, 0) conservando su rotacion, asi el asa usada queda hacia las manos del monje. Al agarrarlo se resuelven las interacciones de esa celda.
  - Sin candelabro el player rota libremente (no hay arco que chequear), solo necesita su propia celda libre para moverse, y no hay interacciones (gotera/fuego). La puerta se puede pisar sin necesitar celda libre detras.
- Feedback visual (todo dura `Global.GRAB_TIME`, el player queda `busy` mientras tanto): al soltar, el candelabro "cae" (`Candle.play_drop()`: los sprites bajan de escala 1.3 a 1 con rebote); al agarrar, se "levanta" y brilla (`Candle.play_grab()`: escala 0.7 a 1 + destello de `modulate`); si la accion no es valida (soltar sobre otro candelabro, o agarrar uno sin asa hacia el monje) el candelabro tiembla (`Candle.shake()`). Solo se animan `sprite` y `handles`, nunca el cuerpo fisico (no escalar colisiones).
- Asas: `Candle.handles` es un `export_flags` (Right, Down, Left, Up; bit = `1 << Global.Dir`) en direcciones locales del candelabro, o sea que rotan con el. Default: solo Left (el del player la tiene hacia el monje). Cada asa es un AnimatedSprite2D en `Candle/handles/<dir>` que se muestra u oculta segun el flag; `Candle.gd` es `@tool` para verlas en el editor (por eso no usa `Global` fuera de runtime).
- Sprites del candelabro: el cuerpo (`candle_*_spr.png`) no tiene asa; el asa va aparte (`candle_handle_1_spr.png`, apuntando a la izquierda) y se rota por direccion.
- Las interacciones (gotera, pasar el fuego, puerta) se resuelven al terminar cada paso o rotacion, segun la celda donde quedo el candelabro. La gotera se evalua antes que los candelabros.
- La puerta es una trampilla en el piso: cerrada se puede pisar sin efecto. Abierta, al pisarla el monje baja al siguiente nivel. Como el candelabro tambien ocupa lugar, para pisar la puerta tiene que haber una celda libre detras de ella (en la direccion en que se llega), o llegar de reversa.
- Paredes con perspectiva 3/4 (referencia: A Link to the Past): cada pieza tiene un "techo" plano del lado de afuera y una cara de ladrillos que baja hacia el piso; las esquinas unen las caras en diagonal. Piezas en `sprites/wall/`: `north/south/west/east` (pared de ese lado de la sala), `corner_nw/ne/sw/se` (esquinas de la sala), `convex_nw/ne/sw/se` (esquinas que sobresalen hacia la sala, ej. `convex_se` = piso al sur y al este) y `fill` (solo techo).
- `Wall.gd` es `@tool`: la propiedad `look` elige la pieza. Con `auto` (default) la elige sola: el interior del nivel son las celdas sin pared a las que se llega desde Player/Candle/Drip/Door sin salir del rectangulo de las paredes. Se actualiza en el editor al mover paredes; se puede forzar una pieza a mano eligiendola en `look`.
- Todos los sprites son vista cenital (desde arriba). El candelabro tiene un asa que, en el del player, apunta hacia las manos del monje.
- Ambientacion: `CanvasModulate` oscuro en Main y un `PointLight2D` en cada candelabro que se prende/apaga con la vela.

### Capas de fisica
| Capa | Uso | Quien la detecta |
|---|---|---|
| 1 walls | `Wall` (StaticBody2D) | Player, candelabro del player |
| 2 player | `Player` (CharacterBody2D) | `Door` (Area2D) |
| 3 candles | candelabros del nivel, incluido uno soltado por el player (CharacterBody2D) | Player |
| 4 held_candle | candelabro del player | nadie (no choca con los otros candelabros) |
| 5 triggers | `Drip` y el `detector` (Area2D) de los candelabros del nivel | `detector` del candelabro del player |

Las capas se setean por codigo en el `_ready` de cada objeto (`Candle.set_held()` configura las del candelabro segun `held`, y se vuelve a llamar al agarrarlo o soltarlo).

### Nodos y escenas
El estilo general es crear una escena por objeto (Player, Enemy, Block) con un script con el mismo nombre en el root de ese nodo, por ejemplo:

 * Player.tscn
   * collider (collition shape)
   * Player.gd (script)
   * pivot (Node2D que rota al girar)
     * sprite (animatedsprite)
     * Candle (instancia de Candle.tscn con `held = true`, en (32, 0); gira junto con el pivot. Se reparenta al nivel al soltarlo y vuelve al pivot al agarrar otro)

Movimiento y rotacion se animan con Tweens (no hace falta AnimationPlayer).

Salvo las señales que se conectan desde el editor para tener eventos, no se usa otro tipo de señales prevaleciendo siempre el uso de llamar a funciones dentro de objetos, por ejemplo enemy.kill()

- Siempre que hay un sprite, usar un AnimatedSprite
- Siempre usar nombres con la primera letra en mayuscula para las escenas
- Siempre usar el mismo nombre de la escena para el script principal de la misma
