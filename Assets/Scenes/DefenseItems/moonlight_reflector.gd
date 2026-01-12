extends CharacterBody2D
class_name MoonlightReflector

@export var maxHealth: int = 100
@export var health: int  = 80
@export var minHealth: int = 0
@onready var map: Map = $"../../"
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var timer: Timer = $"../../../dayAndNight/Timer"


func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	pass

func _process(_float) -> void:
	if(map.nightEnded == true and health > 0):
		point_light_2d.visible = false
	else:
		point_light_2d.visible = true
	if(map.health == 0):
		queue_free()
	
