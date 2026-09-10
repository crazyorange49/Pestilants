## Root of the playable scene. Holds the Map, HUD, Player and the day/night
## cycle, and owns the jump to the game-over screen.
##
## Mostly a container: the real logic lives in Map (waves and nights) and
## DayAndNightCycle (the clock). The counters below are not currently read by
## anything -- Map keeps the authoritative versions.
extends Node2D


# main nodes
## The four top-level systems. Sibling scripts reach each other through this
## root, which is why the node NAMES here are load-bearing.
@onready var map: Map = $Map
@onready var hud: HUD = $HUD
@onready var player: CharacterBody2D = $Player
@onready var dayAndNight: DayAndNightCycle = $dayAndNight


## Snapshot of the enemy count taken at startup. Map.numberOfEnemies is the
## live figure that actually drives the waves.
var currentNumberOfEnemies: int
## Declared but unused; Map owns the equivalents.
var currentNumberOfPlants: int
var currentNight: int
var nightsSurived: int
## Plants and defence items present at startup, captured once and not
## refreshed as things are placed or destroyed.
var itemsOnFeild


## Subscribes to GameOver so a win or loss can swap in the end screen, and
## takes the startup snapshots above.
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("GameOver", Callable(self, "changeScene"))
	currentNumberOfEnemies = map.enemy_storage.get_child_count()
	itemsOnFeild = map.plant_storage.get_children() + map.defense_storage.get_children()
	
	

## Starts a night directly, without waiting for the timer.
##
## NOTE: nothing calls this yet. It also splits the work that
## DayAndNightCycle._on_timer_timeout() does in one place -- startNight()
## handles the visuals and signals while the caller triggers the wave -- so
## the two paths into night are not currently equivalent.
func nextNight() -> void:
	dayAndNight.startNight()
	map.changeNight()


## Leaves the run entirely and loads the game-over screen. Wired to the
## GameOver signal, which Map emits both on a final loss and on surviving
## all 7 nights.
func changeScene():
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")
