extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Panel/Options
var main_scene = preload("res://Assets/Scenes/main_scene.tscn").instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = true
	options.visible = false
	$Title.visible = true

func _on_start_button_pressed() -> void:
	get_tree().root.add_child(main_scene)
	get_tree().root.remove_child(self)
	

func _on_options_button_pressed() -> void:
	v_box_container.visible = false
	options.visible = true
	$Title.visible = false


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	_ready()
