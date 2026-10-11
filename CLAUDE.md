# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project
"Tides" es un juego 2D top down de puzzles, basado en "runs" donde el jugador va ganando mas conocimiento sobre las reglas del mundo, ademas de resolver los puzzles en si.
El estilo es pixel art con un poco de aberraccion cromatica dada por un shader que se puede encontrar en todas las escenas.

## Running / editing

- Open the project in the Godot editor: `godot -e --path .` (or just open `project.godot` with the Godot 4.7 editor).
- Run the game headless from the CLI: `godot --path .`
- The main scene is set via `run/main_scene` in `project.godot` (currently `scenes/main.tscn`, which loads `main_game.tscn`).
- There is no automated test suite, linter, or CI config in this repo — verify changes by running the game in the editor.
- `.godot/` is the editor's generated cache (gitignored) — never hand-edit files there.

## Architecture

### Global autoload (`scripts/Global.gd`)
Existen scripts globales en la carpeta global_scripts que son Global y Music. Music tiene todo lo relativo a reproducir musica en el juego, Global tiene el metodo para reproducir SFX.
Global ademas guarda todo tipo de estados y de enums del juego. Mi estilo de hacer juegos en Godot hace uso fuerte de variables globales.

### Nodos y escenas
El estilo general es crear una escena por objeto (Player, Enemy, Block) con un script con el mismo nombre en el root de ese nodo, por ejemplo:

 * Player.tscn
   * collider (collition shape)
   * Player.gd (script)
   * sprite (animatedsprite)
   * animation (animationplayer)

Salvo las señales que se conectan desde el editor para tener eventos, no se usa otro tipo de señales prevaleciendo siempre el uso de llamar a funciones dentro de objetos, por ejemplo enemy.kill()

- Siempre que hay un sprite, usar un AnimatedSprite
- Siempre usar nombres con la primera letra en mayuscula para las escenas
- Siempre usar el mismo nombre de la escena para el script principal de la misma