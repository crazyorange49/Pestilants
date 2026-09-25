class_name StarterKitSelect
extends Control

const MAIN_MENU_PATH := "res://Assets/Scenes/main_menu.tscn"
const MAIN_SCENE := preload("res://Assets/Scenes/main_scene.tscn")
const CARD := preload("res://Assets/Scenes/UI/StarterKit/StarterKitCard.tscn")

@export var kits: Array[StarterKit] = [
	preload("res://Assets/Scenes/UI/StarterKit/Kits/farm_bell_kit.tres"),
	preload("res://Assets/Scenes/UI/StarterKit/Kits/decoy_kit.tres"),
	preload("res://Assets/Scenes/UI/StarterKit/Kits/rosebush_kit.tres"),
]

@onready var cardRow: HBoxContainer = %CardRow

var starting := false

func _ready() -> void:
	for kit in kits:
		var card: StarterKitCard = CARD.instantiate()
		card.setup(kit)
		cardRow.add_child(card)
		card.chosen.connect(startWithKit)
	%BackButton.pressed.connect(_backToMenu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_backToMenu()

func startWithKit(kit: StarterKit) -> void:
	if starting:
		return
	starting = true
	var game: MainScene = MAIN_SCENE.instantiate()
	game.starterKit = kit
	get_tree().change_scene_to_node(game)

func _backToMenu() -> void:
	if starting:
		return
	starting = true
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
