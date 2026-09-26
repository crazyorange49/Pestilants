## Root of the playable scene. Holds the Map, HUD, Player and the day/night
## cycle, and owns the jump to the game-over screen.
##
## Mostly a container: the real logic lives in Map (waves and nights) and
## DayAndNightCycle (the clock). The counters below are not currently read by
## anything -- Map keeps the authoritative versions.
class_name MainScene
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
@onready var enemySpawn: Marker2D = $EnemyManager/EnemySpawn
@onready var farmbell: Farmbell = $Farmbell
@onready var shop = $Shop

@export var starterKit: StarterKit
 
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
	currentNight = 0
	nightsSurived = 0
	hud._updateDaysLived()
	currentNumberOfPlants = 0
	SignalBus.connect("GameOver", Callable(self, "changeScene"))
	SignalBus.connect("EnemyDeath", Callable(self, "_enemyDeath"))
	SignalBus.connect("PlantDeath", Callable(self, "_plantDeath"))
	SignalBus.connect("PlantPlaced", Callable(self, "_plantPlaced"))
	SignalBus.connect("DecoyPlanted", Callable(self, "_updateDefence"))
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()	
	applyStarterKit()
	

func _nightEnded() -> void:
	dayAndNight.startDay()
	if currentNumberOfPlants > 0:
		nightSurvived()
	else:
		nightLoss()
	enemyManager.killAllChildren()
	hud._updateDaysLived()
	timer.stop()

## Starts a night directly, without waiting for the timer.
##
## NOTE: nothing calls this yet. It also splits the work that
## DayAndNightCycle._on_timer_timeout() does in one place -- startNight()
## handles the visuals and signals while the caller triggers the wave -- so
## the two paths into night are not currently equivalent.
func nextNight() -> void:
	currentNight += 1
	dayAndNight.startNight()
	enemyManager.prepareSpawn("aphid", 2.0, 1, currentNight) # mob type, multiplier, # of spawn points, current night
	if nightsSurived >= 3:
		enemyManager.prepareSpawn("fly", 1.5, 1, currentNight) # mob type, multiplier, # of spawn points, current night
	if nightsSurived >= 5:
		enemyManager.prepareSpawn("worm", 1.0, 1, currentNight) # mob type, multiplier, # of spawn points	
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()
	print("Night: ", currentNight)
	timer.start()

## Runs on every EnemyDeath. Pays the player, decrements the counters, and
## ends the night early once the kill quota is met.
##
## Forcing the timer to fire is what advances dusk -> dawn immediately, so
## clearing a wave skips the rest of the night.
func _enemyDeath() -> void:
	enemyManager.numberOfEnemies -= 1
	var currentNumberOfEnemies: int = enemyManager.numberOfEnemies
	print("bug death")
	# Reward per kill: 5-14 seeds.
	player.renewalSeeds += randi() % 10 + 5
	if currentNumberOfEnemies == 0:
		_nightEnded()
		

func _plantDeath() -> void:
	currentNumberOfPlants -= 1
	print("Plant death")
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()
	if currentNumberOfPlants == 0:
		pass

func _plantPlaced() -> void:
	itemsOnFeild = enemyManager.plantStorage.get_children() + enemyManager.defenseStorage.get_children()

func _updateDefence() -> void:
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
	map.grassProgression(nightsSurived, true)
	

## Night lost: pull the frontier one section west. Losing again at -1 ends
## the run.
func nightLoss():
	if nightsSurived == -1:
		#game loss
		SignalBus.emit_signal("GameOver")
		return
	nightsSurived = clamp(nightsSurived - 1, -2, 7)
	nightLost.emit()
	map.grassProgression(nightsSurived, false)


## Leaves the run entirely and loads the game-over screen. Wired to the
## GameOver signal, which Map emits both on a final loss and on surviving
## all 7 nights.
func changeScene():
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

func applyStarterKit() -> void:
	if starterKit == null:
		return
	if starterKit.includesFarmBell:
		farmbell.unlock()
		shop.removeItemFromShop(shop.ZFARM_BELL)
	var plots := _kitPlotCells()
	for entry in starterKit.entries:
		if entry == null or entry.item == null:
			continue
		for i in entry.count:
			if entry.item.itemType == 1 and !plots.is_empty():
				_plantPreGrown(entry.item, plots.pop_front())
			else:
				hud.hotbar.addItem(entry.item)
	player.changeRenewalSeedCount(starterKit.bonusSeeds)

func _kitPlotCells() -> Array[Vector2i]:
	var soil: TileMapLayer = map.soil_tiles
	var origin: Vector2i = soil.local_to_map(soil.to_local(player.global_position))
	var cells: Array[Vector2i] = []
	for cell in soil.get_used_cells():
		var data := soil.get_cell_tile_data(cell)
		if data != null and data.get_collision_polygons_count(0) > 0:
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(origin) < b.distance_squared_to(origin))
	var spaced: Array[Vector2i] = []
	for cell in cells:
		var crowded := false
		for taken in spaced:
			if absi(cell.x - taken.x) < 2 and absi(cell.y - taken.y) < 2:
				crowded = true
				break
		if !crowded:
			spaced.append(cell)
	return spaced

func _plantPreGrown(item: itemStats, cell: Vector2i) -> void:
	var soil: TileMapLayer = map.soil_tiles
	var plant: Plant = (item.scenePath as PackedScene).instantiate()
	plant.growthProgress = 2
	plant.position = enemyManager.plantStorage.to_local(soil.to_global(soil.map_to_local(cell)))
	plant.dayTimePos = plant.position
	enemyManager.plantStorage.add_child(plant)
	plant.onPlantPlaced()
	currentNumberOfPlants += 1
