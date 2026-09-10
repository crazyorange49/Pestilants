## The 9-slot item bar along the bottom of the screen.
##
## Owns which slot is selected and the stacking rules; the individual slots
## (HotbarSlot) own their own item, count and artwork. The shop adds items
## here on purchase, and the player consumes them on placement.
class_name Hotbar
extends Control

## Set by shopKeep while the shop is open, to stop the scroll wheel changing
## slots behind the shop UI. Starts as null rather than false.
var isInShop = null
## Index 0-8 of the highlighted slot.
var currentSelection : int = 0
## The highlighted slot itself. player.gd reads this to know what is held.
var currentSlot: HotbarSlot = null
## All nine slots, collected from SlotContainer in _ready.
var slots: Array[HotbarSlot]
@onready var player: CharacterBody2D = $"../../Player"


## Collects the slots, clears them, then grants the starting inventory.
func _ready() -> void:
	
	for child in get_node("SlotContainer").get_children():
		slots.append(child)
		child.setItem(null)
		child.hotbar = self
		updateHotbar()
	currentSelection = 0
	# Three Decoy Sprouts are handed out for free at the start of a run.
	addItem(preload("uid://cu0nj78id1rtn"))
	addItem(preload("uid://cu0nj78id1rtn"))
	addItem(preload("uid://cu0nj78id1rtn"))
	updateHotbar()


## Mouse wheel cycles the selection, wrapping around at both ends. Ignored
## while the shop is open.
func _input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action("hotbarMoveLeft") or event.is_action("hotbarMoveRight")) and !isInShop :
		if currentSelection == 8 and event.is_action("hotbarMoveRight"):
			currentSelection = 0
		elif currentSelection == 0 and event.is_action("hotbarMoveLeft"):
			currentSelection = 8
		else:
			currentSelection = clamp(currentSelection - 1 if event.is_action("hotbarMoveLeft") else currentSelection + 1, 0, 8)
		updateHotbar()
		
## Clicking a slot directly selects it. NOTE: HotbarSlot passes its own node
## name as the index, so the slot nodes must be named "0" through "8".
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
		player.updateToolTip()
	elif slot.Item == Item:
		slot.addItem()

## removes one item from the currently selected slot
func removeItem():
	var slot = currentSlot
	
	if slot == null or slot.Item == null:
		return
	# Last of the stack is about to go, so refresh the placement tooltip.
	if slot.quantity == 1:
		player.updateToolTip()
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
## Currently unused.
	var total = 0
	
	for slot in slots:
		if slot.Item == Item:
			total += slot.quantity
	return total

## updates of the texture of the currently selected hotbar slot
func updateHotbar():
	slots[currentSelection].slotSelected(true)
	player.updateToolTip()
	# Unhighlight the slot being left before adopting the new one. Both
	# branches end up assigning currentSlot; only the deselect differs.
	if currentSlot and currentSlot != slots[currentSelection]:
		currentSlot.slotSelected(false)
		currentSlot = slots[currentSelection]
	else:
		currentSlot = slots[currentSelection]
