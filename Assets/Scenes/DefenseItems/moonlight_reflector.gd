extends CharacterBody2D
class_name MoonlightReflector

@onready var map: Map = $"../../"
@onready var point_light_2d: PointLight2D = $PointLight2D

func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	pass

func _process(_float) -> void:
	if(map.nightEnded == true):
		point_light_2d.visible = false
	else:
		point_light_2d.visible = true
 
