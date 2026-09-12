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

## Containers. Enemies, planted plants and placed defences are kept in
## separate nodes so each can be counted and cleared independently.
@onready var enemy_storage: Node2D = $enemyStorage
@onready var plant_storage: Node2D = $plantStorage
@onready var defense_storage: Node2D = $defenseStorage
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

## Progress along the ground sections: up on a win, down on a loss. Reaching
## 7 wins the run and -1 loses it. Also used as a nav-region count for plant
## wandering, so the roaming area widens as ground is reclaimed.
var nightsSurived: int

## Unused.
var navServerMap: RID

## The plant list enemies choose targets from, and the list Coneflower heals
## from. Refreshed at the start of each night and whenever a plant dies.
var availableTargets

## Placed defence items, appended into the enemy target list separately.
var defenceObjects

## Kill quota for the current night. Counts down on each enemy death, and
## reaching zero is what ends the night early as a win.
var mobAmount: int

## Hooks the three gameplay signals and captures the baseline counts.
func _ready() -> void:
	SignalBus.connect("EnemyDeath", Callable(self, "_enemyDeath"))
	SignalBus.connect("PlantDeath", Callable(self, "_plantDeath"))
	SignalBus.connect("DecoyPlanted", Callable(self, "_updateDefence"))
	currentNight = 0
	startingNodes = enemy_storage.get_child_count()
	numberOfEnemies = enemy_storage.get_child_count()
	availableTargets = plant_storage.get_children()
	defenceObjects = defense_storage.get_children() 
	
	# NOTE: toggling `enabled` forces TileMapDual to rebuild its display
	# layers, which otherwise sometimes come up blank at runtime.
	# disable and reenable tilemaps to make sure they are visible to the player
	grass_tiles.enabled = false
	grass_tiles.enabled = true
	soil_tiles.enabled = false
	soil_tiles.enabled = true



## Called at dusk by DayAndNightCycle. Builds the night's waves, scaled by
## currentNight, and unlocks tougher enemy types as the run progresses.
##
## Only runs when the field is already clear -- a leftover enemy from the
## previous night blocks the next wave entirely.

	
## Works out how many of one enemy type to spawn this night and kicks off the
## staggered spawning.
##
## NOTE: mobAmount is ASSIGNED here, not added to. On nights that spawn more
## than one type the later calls overwrite the earlier ones, so the kill
## quota ends up matching only the last wave rather than the total spawned.

	
## Spawns `mobSpawnRounds` enemies of one type at the spawn marker, staggered
## by mobWaitTime so they trickle in rather than appearing as a block.
##
## The three branches are identical apart from which scene they instance.
## Because of the await this runs as a coroutine: changeNight() does not
## wait for it, so all of a night's waves start spawning in parallel.

	#nightEnded = true
	


## Runs on every EnemyDeath. Pays the player, decrements the counters, and
## ends the night early once the kill quota is met.
##
## Forcing the timer to fire is what advances dusk -> dawn immediately, so
## clearing a wave skips the rest of the night.


## Refreshes the defence list. Triggered by DecoyPlanted, since a decoy is
## also a valid enemy target and needs to enter the list immediately.
func _updateDefence() -> void:
	defenceObjects = defense_storage.get_children()

## Recounts plants after one dies and refreshes the target lists.
##
## NOTE: Plant.die() calls queue_free() before emitting PlantDeath, and
## queue_free is deferred, so the dying plant is still counted here. The
## count therefore reads one too high and never reaches 0, which means the
## nightLoss() check in killAllChildren() does not fire on the last plant.


func grassProression(nightsSurived: int, Direction: int) -> void:
	#win
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 1], grass_tileset.get_pattern(4))
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived], grass_tileset.get_pattern(0))
	#loss
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 1], grass_tileset.get_pattern(4))
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 2], grass_tileset.get_pattern(1))
