extends Control

var currentSelection : float = 1
@onready var label: Label = $Label

func _input(event: InputEvent) -> void:
	if event.is_action("hotbarMoveLeft") or event.is_action("hotbarMoveRight"):
		currentSelection = clamp(currentSelection + .5 if event.is_action("hotbarMoveLeft") else currentSelection - .5, 1, 9)
		update_hotbar()
		
func hotbar_Button_Pressed(button) -> void:
	currentSelection = int()
	update_hotbar()


func update_hotbar():
	label.text = str(currentSelection)
