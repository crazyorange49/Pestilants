extends CharacterBody2D

var speed = 150
var health = 21
var maxHealth = 50
var minHealth = 0
var playerChase = false
var victim = null
@onready var enemy_target: Marker2D = $"../../EnemyTarget"

func _physics_process(delta):
	if(health == 0):
		queue_free()
	if playerChase:
		velocity = (victim.get_global_position() - position).normalized() * speed * delta
		move_and_collide(velocity)
		$AnimatedSprite2D.play("walk")
	else:
		#velocity = lerp(velocity, Vector2.ZERO, 0.07) #idles
		velocity = (enemy_target.get_global_position() - position).normalized() * speed * delta
		move_and_collide(velocity)
		$AnimatedSprite2D.play("idle") 


func _on_detecion_area_body_entered(body: Node2D) -> void:
	victim = body
	playerChase = true


func _on_detecion_area_body_exited(_body: Node2D) -> void:
	victim = null
	playerChase = false
