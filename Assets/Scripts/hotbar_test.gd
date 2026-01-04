extends Button

@export var seed_1 = preload("res://Assets/Scenes/Plants/TestPlant.tscn")
@onready var hotbar: Hotbar = $".."


func _pressed() -> void:
	hotbar.addItem(seed_1.instantiate())
