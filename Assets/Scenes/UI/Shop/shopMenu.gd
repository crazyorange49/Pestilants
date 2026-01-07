extends CanvasLayer

const SHOP_ITEM_BUTTON = preload("uid://b85ckxdld6jch")
var ItemFolderPath = "res://Assets/Scenes/UI/Shop/Items/"
var ItemPaths = DirAccess.open(ItemFolderPath).get_files()
var Items: Array[itemStats]
@onready var shop_items_container: VBoxContainer = %ShopItemsContainer
@onready var currency_label: Label = %currencyLabel
@onready var player: CharacterBody2D = $"../Player"

@onready var item_image: TextureRect = %itemImage
@onready var item_name: Label = %itemName
@onready var item_description: Label = %itemDescription
@onready var item_price: Label = %itemPrice



@onready var currency = player.getRenewalSeedCount()

func updateCurrency():
	currency_label.text = str(currency)
	pass

func whenOpened():
	updateCurrency()
	pass

func _ready() -> void:
	for ItemPath in ItemPaths:
		Items.append(load(ItemFolderPath + ItemPath))
	populatePlantList(Items)

func populatePlantList(plants : Array[itemStats]) -> void:
	for plant in plants:
		var shop_plant : ShopItemButton = SHOP_ITEM_BUTTON.instantiate()
		shop_plant.setup_item( plant )
		shop_items_container.add_child( shop_plant )
		shop_plant.focus_entered.connect( updateItemDetails.bind( plant ) )
		#connect to signals
		pass
	pass
	
func focusedItemChanged(plant : itemStats) -> void:
	if plant:
		updateItemDetails( plant )
	pass
	
func updateItemDetails(plant : itemStats) -> void:
	item_image.texture = plant.icon
	item_name.text = plant.itemName
	item_description.text = plant.description
	item_price.text = str(plant.price)
	pass
