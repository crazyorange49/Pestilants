class_name Hotbar
extends Control

var isInShop = null
var currentSelection : int = 0
var currentSlot: HotbarSlot = null
var slots: Array[HotbarSlot]
@onready var player: CharacterBody2D = $"../../Player"


func _ready() -> void:
	
	for child in get_node("SlotContainer").get_children():
		slots.append(child)
		child.setItem(null)
		child.hotbar = self
		updateHotbar()
	currentSelection = 0
	addItem(preload("uid://cu0nj78id1rtn"))
	addItem(preload("uid://cu0nj78id1rtn"))
	addItem(preload("uid://cu0nj78id1rtn"))
	updateHotbar()


func _input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action("hotbarMoveLeft") or event.is_action("hotbarMoveRight")) and !isInShop :
		if currentSelection == 8 and event.is_action("hotbarMoveRight"):
			currentSelection = 0
		elif currentSelection == 0 and event.is_action("hotbarMoveLeft"):
			currentSelection = 8
		else:
			currentSelection = clamp(currentSelection - 1 if event.is_action("hotbarMoveLeft") else currentSelection + 1, 0, 8)
		updateHotbar()
		
func _hotbar_Button_Pressed(Selction: int) -> void:
	currentSelection = Selction
	updateHotbar()

## main function for adding items to a slot, by either locating a slot with a simaler item or the nearest empty slot
func addItem (Item):
	var slot = getSlotToAdd(Item)
	if slot == null:
		return
	
	if slot.Item == null:
		slot.setItem(Item)
	elif slot.Item == Item:
		slot.addItem()

## removes one item from the currently selected slot
func removeItem():
	var slot = currentSlot
	
	if slot == null or slot.Item == null:
		return
	
	slot.removeItem()

## searches for a slot that has either a simalar item or is empty
func getSlotToAdd(Item) -> HotbarSlot:
	for slot in slots:
		if slot.Item == Item and slot.quantity < Item.maxStackSize:
			return slot
	
	for slot in slots:
		if slot.Item == null:
			return slot
	
	return null

## returns the total number of a specific item in the users hotbar
func getNumberOfItems(Item) -> int:
	var total = 0
	
	for slot in slots:
		if slot.Item == Item:
			total += slot.quantity
	return total

## updates of the texture of the currently selected hotbar slot
func updateHotbar():
	slots[currentSelection].slotSelected(true)
	if currentSlot and currentSlot != slots[currentSelection]:
		currentSlot.slotSelected(false)
		currentSlot = slots[currentSelection]
	else:
		currentSlot = slots[currentSelection]
