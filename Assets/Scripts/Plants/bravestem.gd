class_name Bravestem
extends Plant

var enemysInSight

func _ready() -> void:
	super._ready()
	health = maxHealth


func _on_vision_area_body_entered(_body: Node2D) -> void:
	enemysInSight = visionArea.get_overlapping_bodies()
	attackTarget = getAttackTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == attackTarget:
		victim = attackTarget
		attack()


func _on_vision_area_body_exited(_body: Node2D) -> void:
	enemysInSight = visionArea.get_overlapping_bodies()
	attackTarget = getAttackTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position
	

func _on_attack_area_body_exited(_body: Node2D) -> void:
	pass

func _on_nav_timer_timeout() -> void:
	if attackTarget:
		return
	else:
		getNewPosition()

func getAttackTarget():
	var bestTarget = attackTarget
	var bestScore := -INF
	if len(enemysInSight) > 0:
		for enemy in enemysInSight:
			var score = calculatePriority(enemy)
			
			if score > bestScore:
				bestScore = score
				bestTarget = enemy
		return bestTarget
	else:
		return null
		
