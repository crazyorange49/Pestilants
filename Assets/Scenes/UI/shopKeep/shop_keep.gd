## The shop building. Opens and closes the shop UI when the player presses
## the "use" action (E) while standing in its detection area.
##
## The shop is day-only: it cannot be opened at night, and one left open when
## night falls is closed automatically on the next frame. Walking out of the
## detection area also closes it.
##
## While the player can open the shop, E belongs to the shop rather than to
## item placement -- player.gd checks isOpen / canOpen() and skips placing
## its held item, so opening the shop never drops a Decoy Sprout. At night
## canOpen() is false, so E near the shop places items as normal.
extends Node2D
class_name shopKeep

@onready var hudRef = $"../HUD"
@onready var hotbarControl  = hudRef.get_child(0)
@onready var shop: CanvasLayer = $"../Shop"
## (GameManager) used to check day night cycle.
@onready var gameManager: MainScene = $".."
## Checks only for the player, ignore plants and bugs.
@onready var player: Node2D = $"../Player"

var playerInRange := false
var isOpen := false
var promptShown := false

## Whether pressing E right now would open the shop: in range and daytime.
## Also read by player.gd to decide whether E should place an item instead.
func canOpen() -> bool:
	return playerInRange and gameManager.dayAndNight.isDay

## E toggles the shop while the "is_echo" function checks if E is being held down for a long time.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("use") or event.is_echo(): ## Prevents flickering shop UI.
		return
	if isOpen: ## Pressing E while isOpen is true will close the shop UI.
		closeShop()
		get_viewport().set_input_as_handled() ## Stops the input from doing anything else (like planting).
	elif canOpen(): ## Pressing E if isOpen is false will open it.
		openShop()
		get_viewport().set_input_as_handled()

## Polled rather than signal-driven because changeDayTime is emitted before
## isDay flips. Closes the shop once it can no longer be open (night fell or
## the player left), and asks the player to refresh the "E" tooltip whenever
## the shop becomes available or unavailable.
func _process(_delta: float) -> void:
	if isOpen and not canOpen():
		closeShop()
	var prompt := canOpen()
	if prompt != promptShown:
		promptShown = prompt
		if player.has_method("updateToolTip"):
			player.updateToolTip()

## Shows the shop UI, locks the hotbar, and refreshes the displayed seed
## balance, since seeds may have been earned while the shop was closed.
func openShop() -> void:
	isOpen = true
	shop.visible = true
	hotbarControl.isInShop = true
	shop.whenOpened()

## Hides the shop UI and hands scroll input back to the hotbar.
func closeShop() -> void:
	isOpen = false
	shop.visible = false
	hotbarControl.isInShop = false

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		playerInRange = true

## Closes the shop if it was open.
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		playerInRange = false
		if isOpen:
			closeShop()
