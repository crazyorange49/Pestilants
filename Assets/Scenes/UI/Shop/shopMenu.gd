extends CanvasLayer

const SHOP_ITEM_BUTTON = preload("uid://b85ckxdld6jch")
var ItemFolderPath = "res://Assets/Scenes/UI/Shop/Items/"
var ItemPaths = DirAccess.open(ItemFolderPath).get_files()
var Items: Array[itemStats]
@onready var shop_items_container: VBoxContainer = %ShopItemsContainer

func _ready() -> void:
	for ItemPath in ItemPaths:
		Items.append(load(ItemFolderPath + ItemPath))
	pass
	populatePlantList(Items)

func populatePlantList(plants : Array[itemStats]) -> void:
	for plant in plants:
		var shop_plant : ShopItemButton = SHOP_ITEM_BUTTON.instantiate()
		shop_plant.setup_item( plant )
		shop_items_container.add_child( shop_plant )
		#connect to signals
		pass
	pass
	
