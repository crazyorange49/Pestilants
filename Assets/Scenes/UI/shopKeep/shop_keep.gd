## The shop building's trigger. Opens and closes the shop UI as the player
## walks in and out of its detection area.
##
## The shop is day-only: entering at night does nothing. Note the exit
## handler is unconditional, so a shop left open when night falls still
## closes correctly when the player walks away.
extends Node2D
class_name shopKeep

## The Shop CanvasLayer. sceneToControl and shop below are the same node,
## reached twice under two names.
@onready var sceneToControl = $"../Shop"
@onready var hudRef = $"../HUD"
## The hotbar, flagged while the shop is open so the scroll wheel does not
## change hotbar slots behind the shop UI. NOTE: reached by child index, so
## the hotbar must stay the first child of hud.tscn.
@onready var hotbarControl  = hudRef.get_child(0)
## Unused.
var x = "res://Assets/Scenes/UI/Shop/shopMenu.gd"
@onready var shop: CanvasLayer = $"../Shop"
## Map, read for nightEnded to enforce the day-only rule.
@onready var map: Map = $"../Map"
	
## Player entered the shop: show the UI, lock the hotbar, and refresh the
## displayed seed balance.
func _on_detection_area_body_entered(body: Node2D) -> void:
	if( map.nightEnded == true ):
		sceneToControl.visible = true
		hotbarControl.isInShop = true
		shop.whenOpened()

## Player walked away: hide the UI and hand input back to the hotbar.
func _on_detection_area_body_exited(body: Node2D) -> void:
	sceneToControl.visible = false
	hotbarControl.isInShop = false
