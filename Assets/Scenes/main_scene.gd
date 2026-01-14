extends Node2D

@onready var map: Map = $Map
@onready var  pause_menu = $Player/PauseMenu
var paused = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("GameOver", Callable(self, "changeScene"))
	pass # Replace with function body.
	
func changeScene():
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale=0
	paused = !paused
