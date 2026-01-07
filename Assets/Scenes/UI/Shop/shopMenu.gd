extends CanvasLayer

const SHOP_ITEM_BUTTON = preload("uid://b85ckxdld6jch")
var plantItemPaths = DirAccess.open("res://Assets/Scripts/Plants/PlantItems/").get_files()
var plantItems: Array[itemStats]
@onready var shop_items_container: VBoxContainer = %ShopItemsContainer

func _ready() -> void:
	for plantItem in plantItemPaths:
		plantItems.append(load("res://Assets/Scripts/Plants/PlantItems/" + plantItem))
	pass
	populatePlantList(plantItems)

func clearItemList() -> void:
	for c in shop_items_container.get_children():
		c.queue_free()
	pass

func populatePlantList(plants : Array[itemStats]) -> void:
	for plant in plants:
		var shop_plant : ShopItemButton = SHOP_ITEM_BUTTON.instantiate()
		shop_plant.setup_item( plant )
		shop_items_container.add_child( shop_plant )
		#connect to signals
		pass
	pass
	
