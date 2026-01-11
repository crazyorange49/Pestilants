class_name Farmbell
extends CharacterBody2D

@onready var hud: CanvasLayer = $"../HUD"

func _ready() -> void:
	visible = false
	pass


func _on_vision_area_body_entered(body: Node2D) -> void:
	if(visible):
		hud.tooltip.visible = true
	pass # Replace with function body.


func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_vision_area_body_exited(body: Node2D) -> void:
	hud.tooltip.visible = false
	pass # Replace with function body.


func _on_attack_area_body_exited(body: Node2D) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		pass
