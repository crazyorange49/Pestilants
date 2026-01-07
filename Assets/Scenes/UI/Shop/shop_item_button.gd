class_name ShopItemButton extends Button


var plant : itemStats

func setup_item( _plant : itemStats):
	plant = _plant
	$Label.text = plant.itemName
	$priceLabel.text = str(plant.price)
	$TextureRect.texture = plant.icon
