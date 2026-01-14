extends Plant
class_name DecoySprout

@onready var timer: Timer = $"../../../dayAndNight/Timer"

func _ready():
	health = maxHealth

func _process(_float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass

func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
