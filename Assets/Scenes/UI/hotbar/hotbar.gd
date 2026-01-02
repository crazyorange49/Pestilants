extends Control

var currentSelection : float = 1
@export var slots: Array[HotbarSlot]
@onready var label: Label = $Label


func _ready() -> void:
	for child in get_node("SlotContainer").get_children():
		slots.append(child)
		child.set_item(null)

func _input(event: InputEvent) -> void:
	if event.is_action("hotbarMoveLeft") or event.is_action("hotbarMoveRight"):
		currentSelection = clamp(currentSelection + .5 if event.is_action("hotbarMoveLeft") else currentSelection - .5, 1, 9)
		update_hotbar()
		
func hotbar_Button_Pressed(Selction) -> void:
	currentSelection = Selction
	update_hotbar()


func update_hotbar():
	label.text = str(currentSelection)
