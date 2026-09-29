## The game-over screen (game_over.tscn).
##
## Reached by a full scene change from main_scene.gd when SignalBus emits
## GameOver -- which happens both on a loss (nightsSurived drops past -1) and
## on a win (surviving all 7 nights).
class_name GameOverScreen
extends Control

static var playerWon := false
static var nightsPlayed := 0

@export var winColor: Color = Color(0.45, 0.85, 0.35, 1)
@export var lossColor: Color = Color(0.84, 0.6, 1, 1)

## The Play Again / Exit button column.
@onready var v_box_container: VBoxContainer = $VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = true
	$Title.visible = true
	showResult()

func showResult() -> void:
	if playerWon:
		$Title.text = "Farm Saved!"
		$Title.add_theme_color_override("font_color", winColor)
		$Subtitle.text = "You held off the pests for %d nights!" % nightsPlayed
	else:
		$Title.text = "Overrun!"
		$Title.add_theme_color_override("font_color", lossColor)
		$Subtitle.text = "The pests took the farm after %d nights." % nightsPlayed

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/UI/StarterKit/StarterKitSelect.tscn")

## Quits the application.
func _on_exit_button_pressed() -> void:
	get_tree().quit()
