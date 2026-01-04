class_name item
extends Resource

@export var itemName: StringName
@export var maxStackSize: int
@export var icon: Texture
@export var price: int

func _init(p_name: StringName = "seed1", p_maxSS: int = 0, p_price: int = 0, p_icon: Texture = preload("uid://bd46c4etswl3v")) -> void:
	itemName = p_name
	maxStackSize = p_maxSS
	price = p_price
	icon = p_icon
