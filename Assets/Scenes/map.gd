## The night/wave controller and the owner of everything living on the map.
##
## Responsibilities:
##  - spawn each night's waves, scaled by how many nights have passed
##  - keep the running counts of enemies and plants
##  - decide when a night has been survived or lost
##  - repaint the ground so the reclaimed/corrupted border moves
##
## It does not run the clock. DayAndNightCycle owns the timer and calls into
## changeNight() and killAllChildren() at dusk and dawn respectively.
class_name Map
extends Node2D



## Top-left cell of each ground "section", ordered from the safest (east,
## nearest the house) to the most corrupted (far west). nightSurvived and
## nightLoss index into this to move the frontier one section at a time,
## which is why nightsSurived is used directly as an index.
const tileMapSectionVectors: Array[Vector2i] = [Vector2i(-6,-23),Vector2i(-24,-23),Vector2i(-42,-23),Vector2i(-60,-23),Vector2i(-76,-23),Vector2i(-92,-23),Vector2i(-110,-23),Vector2i(-128,-23)]

## The clock. Map reads its timer and can force it to fire early.
@onready var day_and_night: DayAndNightCycle = $"../dayAndNight"

## separate nodes so each can be counted and cleared independently.
@onready var navMap: Node2D = $NavMap ## Navigation regions plants wander within (see Plant.getNewPosition).
## Ground layers. GrassTiles carries the corruption border that gets
## repainted as nights are won and lost.
@onready var grass_tiles: TileMapDual = $GrassTiles
@onready var soil_tiles: TileMapDual = $SoilTiles
@onready var grass_tileset: TileSet = grass_tiles.tile_set
@onready var hud: CanvasLayer = $"../HUD"

## Where every enemy enters the map, far to the west of the house.
@onready var enemy_spawn: Marker2D = $EnemySpawn
@onready var player: CharacterBody2D = $"../Player"

## Baseline child count of enemyStorage, captured at startup. changeNight()
## treats "numberOfEnemies back to this value" as "the field is clear".
var startingNodes: int  

## Live counts. numberOfEnemies is maintained by hand as enemies spawn and
## die; numberOfPlants is incremented by Plant._ready and recounted on death.
var numberOfEnemies: int
var numberOfPlants: int

## False for the duration of a night. Gates plant placement, shop access and
## the Moonlight Reflector's light.
var nightEnded: bool = true
## Unused.
var movingToNextNight: bool

## Unused.
var navServerMap: RID

## The plant list enemies choose targets from, and the list Coneflower heals
## from. Refreshed at the start of each night and whenever a plant dies.
var availableTargets

## Placed defence items, appended into the enemy target list separately.
var defenceObjects

## Hooks the three gameplay signals and captures the baseline counts.
func _ready() -> void:
	# NOTE: toggling `enabled` forces TileMapDual to rebuild its display
	# layers, which otherwise sometimes come up blank at runtime.
	# disable and reenable tilemaps to make sure they are visible to the player
	grass_tiles.enabled = false
	grass_tiles.enabled = true
	soil_tiles.enabled = false
	soil_tiles.enabled = true


func grassProgression(nightsSurived: int, Direction: bool) -> void:
	if Direction == true: #win
		grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 1], grass_tileset.get_pattern(4))
		grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived], grass_tileset.get_pattern(0))
	else: #loss
		grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 1], grass_tileset.get_pattern(4))
		grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 2], grass_tileset.get_pattern(1))
