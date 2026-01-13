extends Node2D

@onready var map: Map = $Map

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("GameOver", Callable(self, "changeScene"))
	pass # Replace with function body.
	
func changeScene():
	get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
