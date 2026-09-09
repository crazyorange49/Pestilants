class_name ShopItemButton extends Button

## Emitted only when the card's own buy button is pressed. Clicking the rest of
## the card just selects it, so a stray click on the row cannot spend seeds.
signal buy_pressed(bought_plant: itemStats)

var plant : itemStats


func _ready() -> void:
	%BuyButton.pressed.connect(_on_buy_button_pressed)


func _on_buy_button_pressed() -> void:
	buy_pressed.emit(plant)


func setup_item( _plant : itemStats):
	plant = _plant
	# Unique names rather than child paths: the card is laid out with containers
	# now, so these are nested rather than direct children of the button.
	%Label.text = plant.itemName
	%priceLabel.text = str(plant.price)
	%TextureRect.texture = plant.icon
