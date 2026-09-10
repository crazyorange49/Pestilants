## The in-game HUD: seed count, enemy count, day counter, countdown, hotbar,
## tooltip and pause menu all hang off this CanvasLayer.
##
## Most of the labels have their own little scripts, but this node drives the
## day and enemy counters directly and owns pausing.
class_name HUD
extends CanvasLayer

## Child widgets. Several other scripts reach the hotbar and tooltip through
## this node via get_child(index), so the child ORDER in hud.tscn matters:
## the hotbar is expected at index 0 and the tooltip at index 2.
@onready var hotbar: Hotbar = $Hotbar
@onready var timer: Label = $Timer
@onready var tooltip: Control = $Tooltip
@onready var days_lived: Label = $DaysLived
## Map, read for nightsSurived and mobAmount.
@onready var map: Node2D = $"../Map"
@onready var  pause_menu = $PauseMenu
@onready var enemies: Label = $Enemies
## Pause state, toggled by pauseMenu().
var paused = false

## Connected from Map's night_survived and nightLost signals. Shows the raw
## survived count, except at -1 where it warns the run is one loss from over.
func _updateDaysLived() -> void:
	var updatedText = "Days: " + str(map.nightsSurived)
	if map.nightsSurived == -1:
		updatedText = "Last night"
	days_lived.text = updatedText

## Seed the day counter before any night has happened.
func _ready() -> void:
	days_lived.text = "Days: " + str(map.nightsSurived)

## Watches for the pause key and keeps the enemy counter live.
func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
	# NOTE: mobAmount is the night's remaining kill quota, not the number of
	# enemies actually alive; the two differ on nights with several types.
	enemies.text = "Enemies: " + str(map.mobAmount)
## Toggles the pause menu. Uses Engine.time_scale rather than the scene tree's
## pause, so everything keeps processing but with zero delta.
func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale=0
	paused = !paused
