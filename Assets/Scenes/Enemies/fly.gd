class_name Fly
extends Enemy


func _ready():
	health = maxHealth
	super._ready()

func _on_timer_timeout() -> void:
	_findNewTarget()
