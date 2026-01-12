extends Plant
class_name DecoySprout

@onready var timer: Timer = $"../../../dayAndNight/Timer"

func _ready():
	pass

func Damage():
	health -= 20
	if(health <= 0):
		queue_free()

func _process(_float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_vision_area_body_exited(body: Node2D) -> void:
	map.hud.tooltip.visible = false
	pass # Replace with function body.
