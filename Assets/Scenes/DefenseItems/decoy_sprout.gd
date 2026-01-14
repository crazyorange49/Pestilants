extends Plant
class_name DecoySprout

@onready var timer: Timer = $"../../../dayAndNight/Timer"
@onready var decoySprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	health = maxHealth
	SignalBus.connect("DayTime", Callable(self, "destroy"))
	SignalBus.emit_signal("DecoyPlanted")
	

func _process(_float) -> void:
	if (health <= 0):
		decoySprite.play("death")
		if (decoySprite.frame == 9):
			decoySprite.stop()

func _physics_process(_delta: float) -> void:
	pass

func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	
func growthCheck():
	growthProgress = 2

func destroy():
	if (decoySprite.frame == 9):
		decoySprite.visible = false
