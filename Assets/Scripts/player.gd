extends CharacterBody2D

var speed: float = 400
var rotationSpeed: float = 100

func _physics_process(_delta: float) -> void:
	var moveInput = Input.get_vector("left","right", "up","down")
	velocity = moveInput * speed
	move_and_slide()
