## Root of the playable scene. Holds the Map, HUD, Player and the day/night
## cycle, and owns the jump to the game-over screen.
##
## Mostly a container: the real logic lives in Map (waves and nights) and
## DayAndNightCycle (the clock). The counters below are not currently read by
## anything -- Map keeps the authoritative versions.
extends Node2D

## Emitted after a night is cleared / lost. The HUD listens to update the day
## counter, and the minimap listens to re-bake its terrain image.
signal nightWon
signal nightLost
# main nodes
## The top-level systems. Sibling scripts reach each other through this
## root, which is why the node NAMES here are load-bearing.
@onready var map = $Map
@onready var hud: HUD = $HUD
@onready var timer: Timer = $nightTimer
@onready var player: CharacterBody2D = $Player
@onready var dayAndNight: DayAndNightCycle = $dayAndNight
@onready var enemyManager: EnemyManager = $EnemyManager
 

## Snapshot of the enemy count taken at startup. Map.numberOfEnemies is the
## live figure that actually drives the waves.
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
	SignalBus.connect("EnemyDeath", Callable(self, "_enemyDeath"))
	SignalBus.connect("PlantDeath", Callable(self, "_plantDeath"))
	SignalBus.connect("PlantPlaced", Callable(self, "_plantPlaced"))
	SignalBus.connect("DecoyPlanted", Callable(self, "_updateDefence"))
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()	
	

## Starts a night directly, without waiting for the timer.
##
## NOTE: nothing calls this yet. It also splits the work that
## DayAndNightCycle._on_timer_timeout() does in one place -- startNight()
## handles the visuals and signals while the caller triggers the wave -- so
## the two paths into night are not currently equivalent.
func nextNight() -> void:
	dayAndNight.startNight()
	if enemyManager.numberOfEnemies == 0: #all enemies defeated
		currentNight += 1
		enemyManager.killAllChildren()
	else:
		enemyManager.killAllChildren()
		currentNight -= 1
	enemyManager.prepareSpawn("aphid", 2.0, 1, currentNight) # mob type, multiplier, # of spawn points, current night
	if nightsSurived >= 3:
		enemyManager.prepareSpawn("fly", 1.5, 1, currentNight) # mob type, multiplier, # of spawn points, current night
	if nightsSurived >= 5:
		enemyManager.prepareSpawn("worm", 1.0, 1, currentNight) # mob type, multiplier, # of spawn points	
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()
	print("Night: ", currentNight)


func _enemyDeath() -> void:
	enemyManager.numberOfEnemies -= 1
	var currentNumberOfEnemies: int = enemyManager.numberOfEnemies
	print("bug death")
	# Reward per kill: 5-14 seeds.
	player.renewalSeeds += randi() % 10 + 5
	if currentNumberOfEnemies == 0 and currentNumberOfPlants > 0:
		map.nightSurvived()
		timer.stop()
		timer.timeout.emit()
		timer.start()

func _plantDeath() -> void:
	currentNumberOfPlants -= 1
	print("Plant death")
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()
	if currentNumberOfPlants == 0:
		pass

func _plantPlaced() -> void:
	currentNumberOfPlants += 1
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()


## Night cleared: advance the frontier one section east, repainting the newly
## reclaimed strip as grass. Surviving with nightsSurived already at 7 wins
## the run.
func nightSurvived():
	if nightsSurived == 7:
		SignalBus.emit_signal("GameOver")
		return
	nightsSurived = clamp(nightsSurived + 1, -2, 7) 
	print("Night survived: " + str(nightsSurived))
	nightWon.emit()
	

## Night lost: pull the frontier one section west. Losing again at -1 ends
## the run.
func nightLoss():
	if nightsSurived == -1:
		#game loss
		SignalBus.emit_signal("GameOver")
		return
	nightsSurived = clamp(nightsSurived - 1, -2, 7)
	nightLost.emit()
	map.loseTileMovement()


## Leaves the run entirely and loads the game-over screen. Wired to the
## GameOver signal, which Map emits both on a final loss and on surviving
## all 7 nights.
func changeScene():
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")
