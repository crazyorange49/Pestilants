## A single hotbar slot: one item type plus a count.
##
## Owns its own artwork and quantity label. The parent Hotbar decides which
## slot is selected and where new items go; this class just holds and
## displays what it was given.
class_name HotbarSlot
extends TextureButton

## The itemStats resource in this slot, or null when empty.
@export var Item: Resource
## How many are stacked here. Meaningless while Item is null.
var quantity
## Back-reference to the owning Hotbar, assigned by Hotbar._ready.
var hotbar: Hotbar
@onready var icon: TextureRect = $icon
@onready var quantityText: Label = $quantityText
## Slot frame textures for the unselected and selected states.
var unfocused = preload("uid://coflil8u4jh7m")
var focused = preload("uid://dhme08djtaf04")

## Clicking a slot tells the Hotbar to select it. NOTE: the index comes from
## this node's NAME, so the slot nodes must be named "0" through "8".
func _pressed() -> void:
	hotbar._hotbar_Button_Pressed(int(self.name))

## Swaps the frame texture to show whether this slot is the active one.
func slotSelected(isSelected: bool) -> void:
	self.texture_normal = focused if isSelected else unfocused
	
## if a slot is not found with a simalar item this will set the item to the empty slot
## Also called with null to clear the slot.
func setItem (new_item):
	Item = new_item
	quantity = 1
	
	if Item == null:
		icon.visible = false
	else:
		icon.visible = true
		icon.texture = Item.icon
	
	updateQuantityText()

## if an item does alrealy exist in the hotbar this will add to the quantity of the item in the respective slot
func addItem ():
	quantity += 1
	updateQuantityText()

## removes one item from the respective slot
func removeItem ():
	quantity -= 1
	updateQuantityText()
	
	# Emptying the stack clears the slot entirely.
	if quantity == 0:
		setItem(null)

## changes or shows the display of number of items in the slot
## A single item shows no number at all.
func updateQuantityText ():
	if quantity <= 1:
		quantityText.text = ""
	else:
		quantityText.text = str(quantity)
