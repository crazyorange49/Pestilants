## The shop building's trigger.
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
@onready var gameManager: MainScene = $".."
@onready var player: Node2D = $"../Player"

var playerInRange := false
var isOpen := false
var promptShown := false

func canOpen() -> bool:
	return playerInRange and gameManager.dayAndNight.isDay

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("use") or event.is_echo():
		return
	if isOpen:
		closeShop()
		get_viewport().set_input_as_handled()
	elif canOpen():
		openShop()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if isOpen and not canOpen():
		closeShop()
	var prompt := canOpen()
	if prompt != promptShown:
		promptShown = prompt
		if player.has_method("updateToolTip"):
			player.updateToolTip()

func openShop() -> void:
	isOpen = true
	sceneToControl.visible = true
	hotbarControl.isInShop = true
	shop.whenOpened()

func closeShop() -> void:
	isOpen = false
	sceneToControl.visible = false
	hotbarControl.isInShop = false

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		playerInRange = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		playerInRange = false
		if isOpen:
			closeShop()
