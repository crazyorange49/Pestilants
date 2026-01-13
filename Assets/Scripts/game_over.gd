extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = true
	$Title.visible = true

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/main_scene.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
