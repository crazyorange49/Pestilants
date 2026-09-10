## The game-over screen (game_over.tscn).
##
## Reached by a full scene change from main_scene.gd when SignalBus emits
## GameOver -- which happens both on a loss (nightsSurived drops past -1) and
## on a win (surviving all 7 nights), so this screen currently covers both.
extends Control

## The Play Again / Exit button column.
@onready var v_box_container: VBoxContainer = $VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = true
	$Title.visible = true

## Restarts by reloading the whole main scene, so all run state is discarded.
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/main_scene.tscn")

## Quits the application.
func _on_exit_button_pressed() -> void:
	get_tree().quit()
