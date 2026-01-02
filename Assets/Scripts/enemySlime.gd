extends CharacterBody2D

var speed = 150
var playerChase = false
var victim = null

func _physics_process(delta):
	if playerChase:
		velocity = (victim.get_global_position() - position).normalized() * speed * delta
		move_and_collide(velocity)
		$AnimatedSprite2D.play("walk")
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.07)
		move_and_collide(velocity)
		$AnimatedSprite2D.play("idle") 


func _on_detecion_area_body_entered(body: Node2D) -> void:
	victim = body
	playerChase = true


func _on_detecion_area_body_exited(body: Node2D) -> void:
	victim = null
	playerChase = false
