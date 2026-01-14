class_name Farmbell
extends CharacterBody2D

@onready var hud: CanvasLayer = $"../HUD"
@onready var animation_player: AnimationPlayer = $PointLight2D/AnimationPlayer
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var enemyStorage: Node2D = $"../Map/enemyStorage"

var isInRange: bool
var isNightTime: bool
var currentState: DayAndNightCycle.DAY_STATE
var isUsed: bool = false

func _ready() -> void:
	visible = false
	isInRange = false
	pass

func _on_vision_area_body_entered(body: Node2D) -> void:
	if(visible):
		hud.tooltip.visible = true
		isInRange = true
	pass # Replace with function body.

func _on_vision_area_body_exited(body: Node2D) -> void:
	hud.tooltip.visible = false
	isInRange = false
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use") and isInRange and currentState == DayAndNightCycle.DAY_STATE.EVENING and !isUsed:
		isUsed = true 
		point_light_2d.enabled = true
		animation_player.play("farmBellAni")
		
		for enemy in enemyStorage.get_tree().get_nodes_in_group("Enemies"):
			enemy.subtractDamage(20)
		pass


func _on_day_and_night_change_day_time(dayTime: DayAndNightCycle.DAY_STATE) -> void:
	currentState = dayTime
	isUsed = false
