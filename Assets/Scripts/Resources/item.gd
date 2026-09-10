## Data definition for one purchasable item -- the resource type behind every
## .tres in Assets/Scenes/UI/Shop/Items/.
##
## Drives the shop listing, the hotbar slot artwork and stacking, and which
## scene gets instanced when the player places it. @tool so the fields are
## editable on the resource in the inspector.
@tool
class_name itemStats
extends Resource

## Display name, shown in the shop list and details panel.
@export var itemName: StringName
@export_enum("Plant:1", "DefenceItem:0") var itemType: int = -1 # number representation of item type 1 = plant 0 = defence item 
## Cost in renewal seeds.
@export var price: int
## Stack limit per hotbar slot.
@export var maxStackSize: int
## Shop and hotbar artwork. The four plants use seed-packet icons; the
## defence items currently reuse their world sprites.
@export var icon: Texture
## The scene instanced on placement. Typed as Resource rather than
## PackedScene, so player.gd loads it via scenePath.resource_path.
@export var scenePath: Resource
## Flavour text for the shop details panel.
@export_multiline var description: String


## NOTE: has no practical effect for the .tres files in the Items folder.
## Godot calls _init() with no arguments when loading a resource, so these
## defaults are applied and then immediately overwritten by the values saved
## in the file.
func _init(p_description: String = "unfilled item description", p_name: StringName = "seed1", p_maxSS: int = 0, p_price: int = 0, p_icon: Texture = preload("uid://bd46c4etswl3v")) -> void:
	description = p_description
	itemName = p_name
	maxStackSize = p_maxSS
	price = p_price
	icon = p_icon
