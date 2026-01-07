class_name ShopItemButton extends Button


var plant : Plant

func setup_item( _plant : Plant):
	plant = _plant
	$Label.text = plant.name
	$priceLabel.text = str(plant.cost)
	$TextureRect.texture = plant.texture
