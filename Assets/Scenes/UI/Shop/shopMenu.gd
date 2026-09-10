## The shop UI ("Town Recovery Center").
##
## Builds one card per purchasable item, shows the details of whichever card
## is hovered or focused, and handles buying. It is opened and closed by
## shopKeep when the player walks into the shop building, not by itself.
##
## Purchases go to the hotbar, with one exception: the Farm Bell is a fixed
## world object, so buying it just makes the existing node visible.
extends CanvasLayer

## The card scene instanced once per item (shop_item_button.tscn).
const SHOP_ITEM_BUTTON = preload("uid://b85ckxdld6jch")
## Unused; items are preloaded explicitly below rather than scanned from disk.
var ItemFolderPath = "res://Assets/Scenes/UI/Shop/Items/"
## The shop stock, in listing order. Order matters only for presentation --
## the four plants first, then the three defence items.
var ItemPaths = [preload("uid://dh5pyc230gwc2"),preload("uid://b413ifushsaor"),preload("uid://c0ljm4521vth4"),preload("uid://e2leq8masu58"),preload("uid://cu0nj78id1rtn"),preload("uid://dtjkdqeeiybvm"),preload("uid://bjriv5fi8rcua")]
var Items: Array[itemStats]
## Card list and currency readout, found by unique name so the shop layout
## can be restructured without breaking these lookups.
@onready var shop_items_container: VBoxContainer = %ShopItemsContainer
@onready var currency_label: Label = %currencyLabel
## The player, the source of truth for the seed balance.
@onready var player: CharacterBody2D = $"../Player"
## Plays the "notEnoughMoney" shake on the currency counter.
@onready var animation_player: AnimationPlayer = $Control/PanelContainer2/AnimationPlayer
@onready var hud: CanvasLayer = $"../HUD"
## NOTE: reached by child index, so the hotbar must stay the first child of
## hud.tscn.
@onready var hotbar: Hotbar = hud.get_child(0)

## The details panel widgets on the right-hand side.
@onready var item_image: TextureRect = %itemImage
@onready var item_name: Label = %itemName
@onready var item_description: Label = %itemDescription
@onready var item_price: Label = %itemPrice

## Special-cased on purchase: see purchase_item.
const ZFARM_BELL = preload("uid://dtjkdqeeiybvm")
@onready var farmbell: Farmbell = $"../Farmbell"

## Cached seed count. Refreshed by updateCurrency, and what purchase_item
## checks against -- so it must be kept in step with the player's real total.
@onready var currency = player.getRenewalSeedCount()

## Re-reads the player's seed count and redraws the counter.
func updateCurrency():
	currency = player.getRenewalSeedCount()
	currency_label.text = str(currency)
	
	pass

## Called by shopKeep each time the shop opens, so the balance shown is
## current even though seeds were earned while the shop was closed.
func whenOpened():
	updateCurrency()
	pass

## Builds the card list once at startup and previews the first item.
func _ready() -> void:
	for Item in ItemPaths:
		Items.append(Item)
	populatePlantList(Items)
	focusedItemChanged(Items[0])

## Creates a card per item and wires its three behaviours: hovering or
## focusing previews the item, and only the card's own buy button purchases.
func populatePlantList(plants : Array[itemStats]) -> void:
	for plant in plants:
		var shop_plant : ShopItemButton = SHOP_ITEM_BUTTON.instantiate()
		shop_plant.setup_item(plant)
		shop_items_container.add_child(shop_plant)
		shop_plant.focus_entered.connect(updateItemDetails.bind(plant))
		shop_plant.mouse_entered.connect(updateItemDetails.bind(plant))
		# Pressing the card only previews it; buying goes through the card's own
		# buy button, so a click anywhere on the row cannot spend seeds.
		shop_plant.pressed.connect(updateItemDetails.bind(plant))
		shop_plant.buy_pressed.connect(purchase_item)
		pass
	pass
	
## Preview helper used for the initial selection.
func focusedItemChanged(plant : itemStats) -> void:
	if plant:
		updateItemDetails( plant )
	pass
	
## Pushes one item's data into the details panel on the right.
func updateItemDetails(plant : itemStats) -> void:
	item_image.texture = plant.icon
	item_name.text = plant.itemName
	item_description.text = plant.description
	item_price.text = str(plant.price)
	pass

## Attempts a purchase. Affordability is checked against the cached currency
## value, then the seeds are deducted from the player and the counter
## refreshed.
func purchase_item( plant : itemStats ) -> void:
	var canPurchase : bool = currency >= plant.price
	if canPurchase:
		player.changeRenewalSeedCount((0 - plant.price))
		updateCurrency()
		# The Farm Bell already exists in the world and starts hidden, so buying
		# it reveals it rather than granting a hotbar item.
		if( plant == ZFARM_BELL):
			farmbell.visible = true
		else:
			hotbar.addItem(plant)
	else:
		# Cannot afford it: shake and flash the currency counter. seek(0) restarts
		# the animation so repeated clicks re-trigger it.
		#play audio
		animation_player.play("notEnoughMoney")
		animation_player.seek(0)
	pass
