## The Sunpetal: the strongest offensive plant (50 seeds).
##
## Structurally identical to Bravestem -- same targeting and attack loop --
## but its exported stats on Sunpetal.tscn hit harder and faster, which makes
## it the main damage dealer of the roster.
class_name Sunpetal
extends Plant

## Swapped between the day and night idle animations by _process.
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

## super._ready() does the shared Plant setup; health has to be filled in
## afterwards because Plant leaves it at zero.
func _ready() -> void:
	super._ready()
	health = maxHealth

## Per-frame loop: keep the right idle animation playing, attack the current
## victim if there is one, otherwise pick a new target and walk at it.
func _process(_delta: float) -> void:
	# Immature plants do nothing at all.
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
	
	

## Something entered vision range -- re-read what is in sight and re-pick.
func _on_vision_area_body_entered(_body: Node2D) -> void:
	enemysInSight = visionArea.get_overlapping_bodies()
	attackTarget = getAttackTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position


## Close enough to hit: promote the chosen target to victim.
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == attackTarget:
		victim = attackTarget


## Something left vision range -- re-read what is in sight and re-pick.
func _on_vision_area_body_exited(_body: Node2D) -> void:
	enemysInSight = visionArea.get_overlapping_bodies()
	attackTarget = getAttackTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position
	

## Target left attack range, so stop hitting but keep walking toward it.
func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == attackTarget:
		victim = null


## Idle wander when there is nothing to fight.
func _on_nav_timer_timeout() -> void:
	if attackTarget and is_instance_valid(attackTarget):
		return
	else:
		getNewPosition()

## Picks the best enemy in sight using Plant.calculatePriority. Returns null
## when nothing is in sight.
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
