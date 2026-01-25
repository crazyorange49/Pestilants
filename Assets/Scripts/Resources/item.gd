@tool
class_name itemStats
extends Resource

@export var itemName: StringName
@export_enum("Plant:1", "DefenceItem:0") var itemType: int = -1 # number representation of item type 1 = plant 0 = defence item 
@export var price: int
@export var maxStackSize: int
@export var icon: Texture
@export var scenePath: Resource
@export_multiline var description: String


func _init(p_description: String = "unfilled item description", p_name: StringName = "seed1", p_maxSS: int = 0, p_price: int = 0, p_icon: Texture = preload("uid://bd46c4etswl3v")) -> void:
	description = p_description
	itemName = p_name
	maxStackSize = p_maxSS
	price = p_price
	icon = p_icon
