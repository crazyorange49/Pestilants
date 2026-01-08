extends Node2D

var currentNight: int
@export var enemy: PackedScene

@onready var day_and_night: DayAndNightCycle = $"../dayAndNight"

var startingNodes: int  
var currentNodes: int
var nightEnded
var movingToNextNight: bool


func _ready() -> void:
	currentNight = 0
	startingNodes = get_child_count()
	currentNodes = get_child_count()
	changeNight()
	pass 

func changeNight():
	if currentNodes == startingNodes: #all enemies defeated
		if currentNight != 0:
			pass
			
		currentNight += 1
		prepareSpawn("slimes", 4.0, 1) # mob type, multiplier, # of spawn points
		#day_and_night._on_timer_timeout()
		print(currentNight)

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
				add_child(slime1)
				mobSpawnRounds -= 1
				await get_tree().create_timer(mobWaitTime).timeout
		nightEnded = true
	pass

func _process(delta: float) -> void:
	pass
