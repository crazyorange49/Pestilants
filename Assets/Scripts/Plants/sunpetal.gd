class_name Sunpetal
extends Plant

func _ready() -> void:
	super._ready()
	health = maxHealth


func _on_vision_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_vision_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_exited(body: Node2D) -> void:
	pass


func _on_nav_timer_timeout() -> void:
	getNewPosition()
