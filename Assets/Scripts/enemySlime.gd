extends CharacterBody2D

@export var speed = 150
@export var health = 21
@export var maxHealth = 50
@export var attack_damage = 5
@export var attack_range = 30.0
@export var attack_cooldown = 1.0
var minHealth = 0
var playerChase = false
var victim  = null
var can_attack = true
var is_dead = false
var move_target: Node2D = null
var moving = true
var targetsInRange: Array[Node2D]
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var detecion_area: Area2D = $detecionArea

func _ready():
	var main_scene = get_tree().get_current_scene() 
	if main_scene.has_node("Move_node"):
		move_target = main_scene.get_node("Move_node")
	else:
		print("node not found")
	

func _physics_process(delta):
	if(health == 0):
		$AnimatedSprite2D.play("death")
		queue_free()
		SignalBus.emit_signal("EnemyDeath")
	if victim:
		attack()
	else:
		if move_target and moving:
			move_to_target(delta)
		else:
			sprite.play("idle")
			
			
		
		
func attack():
	if not can_attack or is_dead:
		return

	can_attack = false
	

	victim.health = attack_damage

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("Plant"):
		victim = calculateTarget()
		moving = false

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == victim:
		victim = calculateTarget()
		if !victim:
			moving = true  

func move_to_target(_delta):
	if move_target == null:
		return

	var direction = move_target.global_position - global_position
	var distance = direction.length()

	if distance > 1:
		velocity = direction.normalized() * speed
		move_and_slide()
		sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle")
		moving = false

func calculateTarget() -> Plant:
	targetsInRange = detecion_area.get_overlapping_bodies()
	var newTarget: Node2D
	var targetPrio = 10
	if len(targetsInRange) > 0:
		print("Number to choose from: " + str(targetsInRange))
		for plant in targetsInRange:
			if plant.is_in_group("Plant") and plant.enemyPriority < targetPrio:
				plant.enemyPriority = targetPrio
				newTarget = plant
			else:
				newTarget = victim
	else:
		return null
	return newTarget
		
		
		
		
		
