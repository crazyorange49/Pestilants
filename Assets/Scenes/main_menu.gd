extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Panel/Options


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = true
	options.visible = false
	$Title.visible = true

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/main_scene.tscn")
	

func _on_options_button_pressed() -> void:
	v_box_container.visible = false
	options.visible = true
	$Title.visible = false


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	_ready()
