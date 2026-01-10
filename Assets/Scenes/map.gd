extends Node2D

signal night_survived
signal nightLost

var currentNight: int
@export var enemy: PackedScene
@onready var day_and_night: DayAndNightCycle = $"../dayAndNight"
@onready var enemy_storage: Node2D = $enemyStorage
@onready var plant_storage: Node2D = $plantStorage
@onready var navMap: Node2D = $NavMap


var startingNodes: int  
var numberOfEnemies: int
var numberOfPlants: int
var nightEnded: bool
var movingToNextNight: bool
var nightsSurived: int

func _ready() -> void:
	SignalBus.connect("EnemyDeath", Callable(self, "_enemyDeath"))
	currentNight = 0
	startingNodes = enemy_storage.get_child_count()
	numberOfEnemies = enemy_storage.get_child_count()
	pass 

func changeNight():
	if numberOfEnemies == startingNodes: #all enemies defeated
		nightEnded = false
		currentNight += 1
		prepareSpawn("slimes", 2.0, 1) # mob type, multiplier, # of spawn points
		print("Night: ", currentNight)

func prepareSpawn(type, multiplier, mobSpawns):
	var mobAmount = 2 #float(currentNight) * multiplier
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
		

func _enemyDeath() -> void:
	numberOfEnemies -= 1
	print_debug("Enemy death recived" + str(numberOfEnemies))
	if numberOfEnemies == 0:
		nightSurvived()

func nightSurvived():
	nightsSurived += 1
	night_survived.emit()
	
func nightLoss():
	nightsSurived -= 1
	nightLost.emit()


	
