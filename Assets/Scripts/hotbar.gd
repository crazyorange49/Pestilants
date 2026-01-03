class_name Hotbar
extends Control

var currentSelection : float = 0
var currentSlot: HotbarSlot = null
var slots: Array[HotbarSlot]
@onready var label: Label = $Label


func _ready() -> void:
	for child in get_node("SlotContainer").get_children():
		slots.append(child)
		child.set_item(null)
		child.hotbar = self

func _input(event: InputEvent) -> void:
	if event.is_action("hotbarMoveLeft") or event.is_action("hotbarMoveRight"):
		currentSelection = clamp(currentSelection + .5 if event.is_action("hotbarMoveLeft") else currentSelection - .5, 0.0, 8.0)
		updateHotbar()
		
func _hotbar_Button_Pressed(Selction) -> void:
	currentSelection = Selction
	updateHotbar()

func add_item (Item: item):
	var slot = getSlotToAdd(Item)
	if slot == null:
		return
	
	if slot.Item == null:
		slot.setItem(item)
	elif slot.Item == item:
		slot.addItem()

func removeItem(Item: item):
	var slot = getSlotToRemove(Item)
	
	if slot == null or slot.Item != Item:
		return
	
	slot.remove_item()

func getSlotToAdd(Item: item) -> HotbarSlot:
	for slot in slots:
		if slot.Item == Item and slot.quantity < Item.maxStackSize:
			return slot
	
	for slot in slots:
		if slot.Item == null:
			return slot
	
	return null

func getSlotToRemove(Item: item) -> HotbarSlot:
	for slot in slots:
		if slot.Item == Item:
			return slot
	return null
	
func getNumberOfItems(Item: item) -> int:
	var total = 0
	
	for slot in slots:
		if slot.Item == Item:
			total += slot.quantity
	return total

func updateHotbar():
	var currentSelectionInt = int(currentSelection)
	slots[currentSelectionInt].slotSelected(true)
	if currentSlot:
		currentSlot.slotSelected(false)
		currentSlot = slots[currentSelectionInt]
	else:
		currentSlot = slots[currentSelectionInt]
	label.text = str(currentSelectionInt)
