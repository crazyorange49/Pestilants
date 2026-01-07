extends CanvasLayer

const SHOP_ITEM_BUTTON = preload("uid://b85ckxdld6jch")

@onready var shop_items_container: VBoxContainer = %ShopItemsContainer

func _ready() -> void:
	pass

func clearItemList() -> void:
	for c in shop_items_container.get_children():
		c.queue_free()
	pass

func populatePlantList( plants : Array[ Plant ]) -> void:
	for plant in plants:
		var shop_plant : ShopItemButton = SHOP_ITEM_BUTTON.instantiate()
		shop_plant.setup_item( plant )
		shop_items_container.add_child( shop_plant )
		#connect to signals
		pass
	pass
	
