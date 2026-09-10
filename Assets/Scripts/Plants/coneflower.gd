## The Coneflower: the support plant (15 seeds).
##
## Heals other plants instead of fighting. It reuses the whole Plant
## targeting machinery but points it at injured allies: attack() is
## overridden to call addHealth(), and atkDamage is read as heal amount.
##
## It ignores vision-area events entirely; getHealTarget() works off Map's
## list of live plants rather than only what is physically nearby.
class_name Coneflower
extends Plant

## Swapped between the day and night idle animations by _process.
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
## Drives the healing glow ("healOn" / "healOff").
@onready var animation_player: AnimationPlayer = $PointLight2D/AnimationPlayer

## super._ready() does the shared Plant setup; health has to be filled in
## afterwards because Plant leaves it at zero.
func _ready() -> void:
	super._ready()
	health = maxHealth


## Per-frame loop: heal the current victim, or walk toward the most injured
## plant it can find. The glow is stopped during the day.
func _process(_delta: float) -> void:
	# Immature plants do nothing at all.
	if(growthProgress < 2):
		return
	if victim and is_instance_valid(victim):
		attack()
	else:
		attackTarget = getHealTarget()
		if attackTarget:
			navigationAgent2d.target_position = attackTarget.position
	if( map.nightEnded == true ):
		animated_sprite_2d.play("dayIdle")
		animation_player.stop()
	else:
		animated_sprite_2d.play("nightIdle")

## Deliberately empty -- Coneflower picks targets from Map.availableTargets
## rather than from its own vision area.
func _on_vision_area_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


## Close enough to heal: promote the chosen target to victim.
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == attackTarget:	
		victim = attackTarget


## Deliberately empty -- see _on_vision_area_body_entered.
func _on_vision_area_body_exited(_body: Node2D) -> void:
	pass # Replace with function body.

## Target moved out of reach; stop the glow and drop the victim.
func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == attackTarget:
		animation_player.play("healOff")
		victim = null

## Overrides Plant.attack() to heal rather than damage. Note it does not
## re-check growthProgress the way the base version does; _process already
## guards that. After the cooldown it immediately re-picks a target so a
## healed-to-full ally is dropped straight away.
func attack():
	if !can_attack:
		return

	can_attack = false
	animation_player.play("healOn")
	victim.addHealth(atkDamage)

	await get_tree().create_timer(atkCoolDownInSeconds).timeout
	attackTarget = getHealTarget()
	if attackTarget:
		navigationAgent2d.target_position = attackTarget.position
	can_attack = true

## Picks the most injured plant worth healing. Skips itself and anything
## already at full health, so it returns null when nothing needs healing.
func getHealTarget():
	# NOTE: this is the shared array from Map, not a copy.
	availablePlants = map.availableTargets
	var bestTarget = attackTarget
	var bestScore := -INF
	if len(availablePlants) > 0:
		for plant in availablePlants:
			if !is_instance_valid(plant) or plant == self or plant.health == plant.maxHealth:
				continue
			var score = calculatePriority(plant)
			
			if score > bestScore:
				bestScore = score
				bestTarget = plant
		return bestTarget
	else:
		return null

#animation_player.play("healOff")  Use these when target is found and when target is null
#animation_player.play("healOn")

## Idle wander when there is nobody to heal.
func _on_nav_timer_timeout() -> void:
	if attackTarget and is_instance_valid(attackTarget):
		return
	else:
		getNewPosition()
