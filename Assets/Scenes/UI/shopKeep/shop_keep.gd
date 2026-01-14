extends Node2D
class_name shopKeep

@onready var sceneToControl = $"../Shop"
@onready var hudRef = $"../HUD"
@onready var hotbarControl  = hudRef.get_child(0)
var x = "res://Assets/Scenes/UI/Shop/shopMenu.gd"
@onready var shop: CanvasLayer = $"../Shop"
@onready var map: Map = $"../Map"
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	if( map.nightEnded == true ):
		sceneToControl.visible = true
		hotbarControl.isInShop = true
		shop.whenOpened()

func _on_detection_area_body_exited(body: Node2D) -> void:
	sceneToControl.visible = false
	hotbarControl.isInShop = false
