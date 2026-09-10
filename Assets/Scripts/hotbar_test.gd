## Debug button: grants one Bravestem to the hotbar when pressed.
##
## A development shortcut for testing placement without earning seeds. Not
## part of the shipped UI.
extends Button

const BRAVESTEM_ITEM = preload("uid://dh5pyc230gwc2")

## Sibling Hotbar node this button feeds.
@onready var hotbar: Hotbar = $"../Hotbar"


func _pressed() -> void:
	hotbar.addItem(BRAVESTEM_ITEM)
