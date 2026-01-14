extends CharacterBody2D
class_name MoonlightReflector

@export var maxHealth: int = 100
@export var damage = 5
@export var health: int  = 100
@export var minHealth: int = 0
@onready var map: Map = $"../../"
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var damage_timer: Timer = $DamageTimer
var enemies_in_light: Array[Enemy] = []
func _ready():
	SignalBus.connect("DayTime", Callable(self, "Damage") )
	pass

func Damage():
	health -= 20
	if(health <= 0):
		queue_free()

func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	pass

func _process(_float) -> void:
	if(map.nightEnded == true and health > 0):
		point_light_2d.visible = false
		damage_timer.stop()
	else:
		point_light_2d.visible = true
		if enemies_in_light.size() > 0 and damage_timer.is_stopped():
			damage_timer.start()



	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not map.nightEnded:
		enemies_in_light.append(body)
		damage_timer.start()
		

func _on_area_2d_body_exited(body: Node2D) -> void:
		enemies_in_light.erase(body)
		if enemies_in_light.is_empty():
			damage_timer.stop()
			
			
func _on_damage_timer_timeout() -> void:
	for enemy in enemies_in_light:
		if is_instance_valid(enemy):
			enemy.subtractDamage(damage)
