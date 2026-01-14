class_name Sunpetal
extends Plant

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	health = maxHealth

func _process(_delta: float) -> void:
	if(growthProgress < 2):
		return
	if( map.nightEnded == true ):
		animated_sprite_2d.play("dayIdle")
	else:
		animated_sprite_2d.play("nightIdle")

	if victim and is_instance_valid(victim):
		attack()
	else:
		
		attackTarget = getAttackTarget()
		if attackTarget:
			navigationAgent2d.target_position = attackTarget.position
			victim = attackTarget
	
	

func _on_vision_area_body_entered(_body: Node2D) -> void:
	enemysInSight = visionArea.get_overlapping_bodies()
	attackTarget = getAttackTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == attackTarget:
		victim = attackTarget


func _on_vision_area_body_exited(_body: Node2D) -> void:
	enemysInSight = visionArea.get_overlapping_bodies()
	attackTarget = getAttackTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position
	

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == attackTarget:
		victim = null


func _on_nav_timer_timeout() -> void:
	if attackTarget and is_instance_valid(attackTarget):
		return
	else:
		getNewPosition()

func getAttackTarget():
	var bestTarget = attackTarget
	var bestScore := -INF
	if len(enemysInSight) > 0:
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
