extends Node2D
class_name shopKeep

@onready var sceneToControl = get_node("/root/Shop")
@onready var hudRef = $"../HUD"
@onready var hotbarControl  = hudRef.get_child(0)
var x = "res://Assets/Scenes/UI/Shop/shopMenu.gd"
@onready var shop: CanvasLayer = $"../Shop"



func _on_detection_area_body_entered(body: Node2D) -> void:
	sceneToControl.visible = true
	hotbarControl.isInShop = true
	shop.whenOpened()


func _on_detection_area_body_exited(body: Node2D) -> void:
	sceneToControl.visible = false
	hotbarControl.isInShop = false
