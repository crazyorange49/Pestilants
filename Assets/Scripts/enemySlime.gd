extends CharacterBody2D

@export var speed = 150
@export var health = 21
@export var maxHealth = 50
@export var attack_damage = 5
@export var attack_range = 30.0
@export var attack_cooldown = 1.0
var minHealth = 0
var playerChase = false
var victim : Plant = null
var can_attack = true
var is_dead = false
var move_target: Node2D = null
var moving = true
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	var main_scene = get_tree().get_current_scene() 
	if main_scene.has_node("Move_node"):
		move_target = main_scene.get_node("Move_node")
	else:
		print("node not found")
	

func _physics_process(delta):
	if(health == 0):
		queue_free()
		$AnimatedSprite2D.play("death")
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
	

	victim.subtractDamage(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_area_body_entered(body):
	if body is Plant:
		victim = body
		moving = false
func _on_attack_area_body_exited(body):
	if body == victim:
		victim = null
		moving = true  

func move_to_target(delta):
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
