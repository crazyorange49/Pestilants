class_name HotbarSlot
extends TextureButton

@export var Item: item
var quantity
var hotbar: Hotbar
@onready var icon: TextureRect = $icon
@onready var quantityText: Label = $quantityText
var unfocused = preload("res://Assets/Scenes/UI/hotbar/Textures/HotbarButtonNormalTexture.tres")
var focused = preload("res://Assets/Scenes/UI/hotbar/Textures/HotbarButtonFocusedTexture.tres")


func slotSelected(isSelected: bool) -> void:
	self.texture_normal = focused if isSelected else unfocused
	

func set_item (new_item: item):
	Item = new_item
	quantity = 1
	
	if Item == null:
		icon.visible = false
	else:
		icon.visible = true
		icon.texture = Item.icon
	
	update_quantity_text()

func add_item ():
	quantity += 1
	update_quantity_text()

func remove_item ():
	quantity -= 1
	update_quantity_text()
	
	if quantity == 0:
		set_item(null)

func update_quantity_text ():
	if quantity <= 1:
		quantityText.text = ""
	else:
		quantityText.text = str(quantity)
