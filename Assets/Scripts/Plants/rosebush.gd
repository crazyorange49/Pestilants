class_name Rosebush
extends Plant

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var thornDamage: int = 10

var last_attacker: Enemy = null

func _ready() -> void:
	super._ready()
	health = maxHealth

func _process(delta: float) -> void:
	if(growthProgress < 2):
		return
	if( map.nightEnded == true ):
		animated_sprite_2d.play("dayIdle")
	else:
		animated_sprite_2d.play("nightIdle")
	
func subtractDamage(damage: int, attacker: Node2D = null) -> void:
	last_attacker = attacker
	super.subtractDamage(damage)

	if last_attacker and is_instance_valid(last_attacker):
		last_attacker.subtractDamage(thornDamage)
	
func _on_vision_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_vision_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.



func _on_attack_area_body_exited(body: Node2D) -> void:
	pass


func _on_nav_timer_timeout() -> void:
	getNewPosition()
