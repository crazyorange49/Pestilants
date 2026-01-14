class_name Coneflower
extends Plant

func _ready() -> void:
	super._ready()
	health = maxHealth


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

func _on_nav_timer_timeout() -> void:
	getNewPosition()
