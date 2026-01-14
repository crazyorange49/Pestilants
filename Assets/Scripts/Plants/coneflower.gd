class_name Coneflower
extends Plant

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $PointLight2D/AnimationPlayer

func _ready() -> void:
	super._ready()
	health = maxHealth


func _process(_delta: float) -> void:
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

func _on_vision_area_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == attackTarget:
		victim = attackTarget


func _on_vision_area_body_exited(_body: Node2D) -> void:
	pass # Replace with function body.

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == attackTarget:
		animation_player.play("healOff")
		victim = null

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

func getHealTarget():
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

func _on_nav_timer_timeout() -> void:
	if attackTarget and is_instance_valid(attackTarget):
		return
	else:
		getNewPosition()
