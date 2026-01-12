class_name Enemy
extends CharacterBody2D

@export var speed = 150
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
@onready var timer: Timer = $Timer

## priority variables
var w_priority = 0.5
var w_new = 0.25
var scale_new = 8
var oldDistaceWeight: float = 0.1

@export var health: int:
	set(subtractedHealth):
		health = clamp(health + subtractedHealth, 0, maxHealth) 
		print(str(health))
		if health <= 0:
			queue_free()
			SignalBus.emit_signal("EnemyDeath")
	get:
		return health

func _ready():
	var main_scene = get_tree().get_current_scene() 
	timer.start()
	if main_scene.has_node("Move_node"):
		move_target = main_scene.get_node("Move_node")
		navigation_agent_2d.target_position = move_target.position
	else:
		print("node not found")
	

func _physics_process(delta):
	if victim:
		attack()
	if move_target and moving:
		move_to_target(delta)
		rotation = get_angle_to(navigation_agent_2d.get_next_path_position())
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

	var direction = (navigation_agent_2d.get_next_path_position() - global_position)
	var distance = direction.length()

	if move_target:
		velocity = velocity.lerp(direction.normalized() * speed, delta)
		var new_transform = transform.looking_at(direction)
		transform = new_transform
		move_and_slide()
		sprite.play("idle") #change to walk later
	else:
		print(distance)
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle")
		moving = false

func calculateTarget() -> Plant:
	var avalableTargets = map.avalableTargets
	var newTarget: Node2D = move_target
	var bestScore := -INF
	for plant in avalableTargets:
		if plant.isTarget:
			continue

		var score = calculatePriority(plant)

		if score > bestScore:
			bestScore = score
			newTarget = plant
	return newTarget

func calculatePriority(plant: Plant):
	var score = plant.enemyPriority
	score += closeness(position.distance_to(plant.position), scale_new) * w_new
	if plant != move_target:
		score -= oldDistaceWeight
	return score

func closeness(dist: float, distScale: float) -> float:
	return exp(-dist / distScale)

func _findNewTarget() -> void:
	move_target = calculateTarget()
	navigation_agent_2d.target_position = move_target.position
