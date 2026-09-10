## The title screen (main_menu.tscn) -- the project's startup scene.
##
## Toggles between the button column and the options panel in place rather
## than changing scenes, then hands over to the game by swapping itself out
## for the main scene under the tree root.
extends Control

## The Start / Options / Exit column, and the options panel it toggles with.
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Panel/Options
## NOTE: the game scene is instanced at load time, before Start is pressed,
## so the whole game exists in memory while the menu is showing.
var main_scene = preload("res://Assets/Scenes/main_scene.tscn").instantiate()

## Also used as the "back to menu" handler, since re-running it restores the
## default menu visibility.
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = true
	options.visible = false
	$Title.visible = true

## Swaps this menu out for the game. The menu node is removed but not freed,
## so it lingers in memory.
func _on_start_button_pressed() -> void:
	get_tree().root.add_child(main_scene)
	get_tree().root.remove_child(self)
	

## Show the options panel and hide the main column.
func _on_options_button_pressed() -> void:
	v_box_container.visible = false
	options.visible = true
	$Title.visible = false


## Quits the application.
func _on_exit_button_pressed() -> void:
	get_tree().quit()


## Returns to the main column by re-applying the initial visibility state.
func _on_back_pressed() -> void:
	_ready()
