class_name Coneflower
extends Plant

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $PointLight2D/AnimationPlayer

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

func _on_vision_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_vision_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.

func getHealTarget():
	var availablePlants = map.availableTargets
	var bestTarget = attackTarget
	var bestScore := -INF
	if len(map) > 0:
		for enemy in enemysInSight:
			if !is_instance_valid(enemy):
				continue
			var score = calculatePriority(enemy)
			
			if score > bestScore:
				bestScore = score
				bestTarget = enemy
		return bestTarget
	else:
		return null

#animation_player.play("healOff")  Use these when target is found and when target is null
#animation_player.play("healOn")

func _on_nav_timer_timeout() -> void:
	getNewPosition()
