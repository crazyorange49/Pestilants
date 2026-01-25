class_name HotbarSlot
extends TextureButton

@export var Item: Resource
var quantity
var hotbar: Hotbar
@onready var icon: TextureRect = $icon
@onready var quantityText: Label = $quantityText
var unfocused = preload("uid://coflil8u4jh7m")
var focused = preload("uid://dhme08djtaf04")

func _pressed() -> void:
	hotbar._hotbar_Button_Pressed(int(self.name))

func slotSelected(isSelected: bool) -> void:
	self.texture_normal = focused if isSelected else unfocused
	
## if a slot is not found with a simalar item this will set the item to the empty slot
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
	
	if quantity == 0:
		setItem(null)

## changes or shows the display of number of items in the slot
func updateQuantityText ():
	if quantity <= 1:
		quantityText.text = ""
	else:
		quantityText.text = str(quantity)
