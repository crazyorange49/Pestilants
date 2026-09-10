extends Node2D


# main nodes
@onready var map: Map = $Map
@onready var hud: HUD = $HUD
@onready var player: CharacterBody2D = $Player
@onready var dayAndNight: DayAndNightCycle = $dayAndNight


var currentNumberOfEnemies: int
var currentNumberOfPlants: int
var currentNight: int
var nightsSurived: int
var itemsOnFeild


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("GameOver", Callable(self, "changeScene"))
	currentNumberOfEnemies = map.enemy_storage.get_child_count()
	itemsOnFeild = map.plant_storage.get_children() + map.defense_storage.get_children()
	
	

func nextNight() -> void:
	dayAndNight.startNight()
	map.changeNight()


func changeScene():
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

