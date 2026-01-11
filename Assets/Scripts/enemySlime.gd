class_name Enemy
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
@onready var map: Map = $"../../"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

func _ready():
	var main_scene = get_tree().get_current_scene() 
	if main_scene.has_node("Move_node"):
		move_target = main_scene.get_node("Move_node")
		navigation_agent_2d.target_position = move_target.position
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
		victim = body

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == victim:
		victim = null


func move_to_target(delta):
	if move_target == null:
		_findNewTarget()

	var direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
	var distance = direction.length()

	if distance > 1:
		velocity =  velocity.lerp(direction * speed, delta)
		move_and_slide()
		sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle")
		moving = false

func calculateTarget() -> Plant:
	var avalableTargets = map.avalableTargets
	var newTarget: Node2D = move_target
	var targetPrio = 10
	if len(avalableTargets) > 0:
		for plant in avalableTargets:
			if plant.enemyPriority < targetPrio and position.distance_to(plant.global_position) < position.distance_to(newTarget.global_position) and !plant.isTarget:
				print("plant reconized " + str(plant.position))
				plant.enemyPriority = targetPrio
				newTarget = plant
				plant.isTarget = true
				if move_target.is_in_group("Plant"):
					move_target.isTarget = false
			else:
				newTarget = move_target
	else:
		return null
	return newTarget
		
		
func _findNewTarget() -> void:
	move_target = calculateTarget()
	navigation_agent_2d.target_position = move_target.position
