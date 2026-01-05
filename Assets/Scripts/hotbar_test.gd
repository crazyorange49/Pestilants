extends Button

const BRAVESTEM_ITEM = preload("uid://dh5pyc230gwc2")

@onready var hotbar: Hotbar = $"../Hotbar"


func _pressed() -> void:
	hotbar.addItem(BRAVESTEM_ITEM)
