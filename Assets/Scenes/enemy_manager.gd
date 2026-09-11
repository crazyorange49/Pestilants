class_name EnemyManager
extends Node


## Enemy scenes to instance. "Solder" is the aphid, "worm" is the BigBug.
@export var solder: PackedScene
@export var fly: PackedScene
@export var worm: PackedScene

@onready var enemyStorage: Node2D = $enemyStorage
@onready var plantStorage: Node2D = $plantStorage
@onready var defenseStorage: Node2D = $defenseStorage

var numberOfEnemies: int
var numberOfPlants: int



func prepareSpawn(type, multiplier, mobSpawns, currentNight):
	var mobAmount = float(currentNight) * multiplier
	var mobWaitTime: float = 0.5
	print("mob amount: ", mobAmount)
	var mobSpawnRounds = mobAmount / mobSpawns
	spawn_type(type, mobSpawnRounds, mobWaitTime)


func spawn_type(type, mobSpawnRounds, mobWaitTime):
	var slimeSpawn = $EnemySpawn
	if type == "aphid":
		if mobSpawnRounds >= 1:
			for i in mobSpawnRounds:
				var aphid = solder.instantiate()
				aphid.global_position = slimeSpawn.global_position
				enemyStorage.add_child(aphid)
				mobSpawnRounds -= 1
				numberOfEnemies += 1
				await get_tree().create_timer(mobWaitTime).timeout
	elif type == "fly":
		if mobSpawnRounds >= 1:
			for i in mobSpawnRounds:
				var flyBug = fly.instantiate()
				flyBug.global_position = slimeSpawn.global_position
				enemyStorage.add_child(flyBug)
				mobSpawnRounds -= 1
				numberOfEnemies += 1
				await get_tree().create_timer(mobWaitTime).timeout
	elif type == "worm":
		if mobSpawnRounds >= 1:
			for i in mobSpawnRounds:
				var bigBug = worm.instantiate()
				bigBug.global_position = slimeSpawn.global_position
				enemyStorage.add_child(bigBug)
				mobSpawnRounds -= 1
				numberOfEnemies += 1
				await get_tree().create_timer(mobWaitTime).timeout

## Called at dawn. Clears the field whether or not the player killed
## everything, then decides whether the night was actually lost.
func killAllChildren():
	numberOfEnemies = 0
	var enemyStorageChildren = enemyStorage.get_children()
	for child in enemyStorageChildren:
		child.queue_free()
	if( numberOfPlants <= 0 ):
		nightLoss()