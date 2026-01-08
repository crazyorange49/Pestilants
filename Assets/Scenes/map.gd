extends Node2D

var currentNight: int
@export var enemy: PackedScene
@onready var day_and_night: DayAndNightCycle = $"../dayAndNight"
@onready var enemy_storage: Node2D = $enemyStorage

var startingNodes: int  
var currentNodes: int
var nightEnded: bool
var movingToNextNight: bool


func _ready() -> void:
	currentNight = 0
	startingNodes = get_child_count()
	currentNodes = get_child_count()
	pass 

func changeNight():
	if currentNodes == startingNodes: #all enemies defeated
		nightEnded = false
		currentNight += 1
		prepareSpawn("slimes", 2.0, 1) # mob type, multiplier, # of spawn points
		print("Night:", currentNight)

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
				await get_tree().create_timer(mobWaitTime).timeout
	#nightEnded = true
	
func killAllChildren():
	var enemyStorageChildren = enemy_storage.get_children()
	for enemy in enemyStorageChildren:
		enemy.free()
	nightEnded = true
		

func _process(_delta: float) -> void:
	currentNodes = get_child_count()
	
