extends Plant
class_name DecoySprout

@onready var timer: Timer = $"../../../dayAndNight/Timer"
@onready var decoySprite: AnimatedSprite2D = $AnimatedSprite2D

var is_dead = false

func _ready():
	health = maxHealth
	#decoySprite.animation_finished.connect(_on_animation_finished)
	SignalBus.connect("DayTime", Callable(self, "destroy"))
	SignalBus.emit_signal("DecoyPlanted")
	

func _process(_float) -> void:
	pass

func die() -> void:
	if is_dead:
		return
	is_dead = true
	decoySprite.play("death")
	await decoySprite.animation_finished
	queue_free()

#func _on_animation_finished() -> void:
	#if decoySprite.animation == "death":
		#queue_free()


func _physics_process(_delta: float) -> void:
	pass

func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	
func growthCheck():
	growthProgress = 2

func destroy():
	if (decoySprite.frame == 9):
		decoySprite.visible = false
