class_name Map
extends Node2D

signal night_survived
signal nightLost

const tileMapSectionVectors: Array[Vector2i] = [Vector2i(-6,-23),Vector2i(-24,-23),Vector2i(-42,-23),Vector2i(-60,-23),Vector2i(-76,-23),Vector2i(-92,-23),Vector2i(-110,-23),Vector2i(-128,-23)]

var currentNight: int
@export var enemy: PackedScene
@onready var day_and_night: DayAndNightCycle = $"../dayAndNight"
@onready var enemy_storage: Node2D = $enemyStorage
@onready var plant_storage: Node2D = $plantStorage
@onready var defense_storage: Node2D = $defenseStorage
@onready var navMap: Node2D = $NavMap
@onready var grass_tiles: TileMapDual = $GrassTiles
@onready var grass_tileset: TileSet = grass_tiles.tile_set
@onready var hud: CanvasLayer = $"../HUD"
@onready var enemy_spawn: Marker2D = $EnemySpawn

var startingNodes: int  
var numberOfEnemies: int
var numberOfPlants: int
var nightEnded: bool = true
var movingToNextNight: bool
var nightsSurived: int
var navServerMap: RID
var availableTargets
var defenceObjects

func _ready() -> void:
	SignalBus.connect("EnemyDeath", Callable(self, "_enemyDeath"))
	SignalBus.connect("PlantDeath", Callable(self, "_plantDeath"))
	currentNight = 0
	startingNodes = enemy_storage.get_child_count()
	numberOfEnemies = enemy_storage.get_child_count()
	availableTargets = plant_storage.get_children()
	defenceObjects = defense_storage.get_children()
	pass 

func changeNight():
	if numberOfEnemies == startingNodes: #all enemies defeated
		nightEnded = false
		currentNight += 1
		prepareSpawn("slimes", 2.0, 1) # mob type, multiplier, # of spawn points
		availableTargets = plant_storage.get_children()
		defenceObjects = defense_storage.get_children()
		print("Night: ", currentNight)
	
func prepareSpawn(type, multiplier, mobSpawns):
	var mobAmount = 1 #float(currentNight) * multiplier
	var mobWaitTime: float = 2.0
	print("mob amount: ", mobAmount)
	var mobSpawnRounds = mobAmount / mobSpawns
	spawn_type(type, mobSpawnRounds, mobWaitTime)
	
func spawn_type(type, mobSpawnRounds, mobWaitTime):
	if type == "slimes":
		var slimeSpawn = $EnemySpawn
		if mobSpawnRounds >= 1:
			for i in mobSpawnRounds:
				var slime1 = enemy.instantiate()
				slime1.global_position = slimeSpawn.global_position
				enemy_storage.add_child(slime1)
				mobSpawnRounds -= 1
				numberOfEnemies += 1
				await get_tree().create_timer(mobWaitTime).timeout
	#nightEnded = true
	
func killAllChildren():
	var enemyStorageChildren = enemy_storage.get_children()
	for child in enemyStorageChildren:
		child.health = 0
	nightEnded = true
	if( numberOfPlants <= 0 ):
		nightLoss()
		

func _enemyDeath() -> void:
	numberOfEnemies -= 1
	print("bug death")
	if numberOfEnemies == 0 and numberOfPlants > 0:
		nightSurvived()

func _plantDeath() -> void:
	numberOfPlants -= 1
	print("Plant death")
	availableTargets = plant_storage.get_children()
	defenceObjects = defense_storage.get_children()
	if numberOfPlants == 0:
		pass

func nightSurvived():
	if nightsSurived == 7:
		#game won
		return
	nightsSurived = clamp(nightsSurived + 1, -2, 7) 
	print("Night survived: " + str(nightsSurived))
	night_survived.emit()
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 1], grass_tileset.get_pattern(4))
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived], grass_tileset.get_pattern(0))

func nightLoss():
	if nightsSurived == -1:
		#game loss
		SignalBus.emit_signal("GameOver")
		return
	nightsSurived = clamp(nightsSurived - 1, -2, 7)
	nightLost.emit()
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 1], grass_tileset.get_pattern(4))
	grass_tiles.set_pattern(tileMapSectionVectors[nightsSurived + 2], grass_tileset.get_pattern(1))
