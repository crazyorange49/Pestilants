## One row in the shop list: icon, name, and a gold buy button.
##
## The card itself is a Button so it can be hovered and focused to preview an
## item, but it deliberately does not purchase. Buying is a separate nested
## button, surfaced to the shop through the buy_pressed signal below.
class_name ShopItemButton extends Button

## Emitted only when the card's own buy button is pressed. Clicking the rest of
## the card just selects it, so a stray click on the row cannot spend seeds.
signal buy_pressed(bought_plant: itemStats)

## The item this card represents, supplied by setup_item.
var plant : itemStats


## Forwards the nested buy button's press as this card's own signal, so the
## shop never needs to reach inside the card's layout.
func _ready() -> void:
	%BuyButton.pressed.connect(_on_buy_button_pressed)


func _on_buy_button_pressed() -> void:
	buy_pressed.emit(plant)


## Fills the card in from an item. Called by shopMenu before the card is
## added to the tree.
func setup_item( _plant : itemStats):
	plant = _plant
	# Unique names rather than child paths: the card is laid out with containers
	# now, so these are nested rather than direct children of the button.
	%Label.text = plant.itemName
	%priceLabel.text = str(plant.price)
	%TextureRect.texture = plant.icon
