extends Button

@export var seed_1 = "res://Assets/Scenes/Plants/Bravestem.tscn"
@onready var hotbar: Hotbar = $"../Hotbar"


func _pressed() -> void:
	var plant = load(seed_1).instantiate()
	hotbar.addItem(plant)
