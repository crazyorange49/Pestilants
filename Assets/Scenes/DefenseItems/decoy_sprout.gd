extends Plant
class_name DecoySprout

@onready var timer: Timer = $"../../../dayAndNight/Timer"
@onready var decoySprite: AnimatedSprite2D = $AnimatedSprite2D
#@onready var enemies: Node2D = $"../../enemyStorage"
var is_dead = false
var enemies_in_attack_area: Array[Node2D] = []

func _ready():
	health = maxHealth
	SignalBus.connect("DayTime", Callable(self, "destroy"))
	SignalBus.emit_signal("DecoyPlanted")
	

func _process(_float) -> void:
	pass

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	for enemy in enemies_in_attack_area:
		if is_instance_valid(enemy):
			enemy.subtractDamage(30)

	enemies_in_attack_area.clear()
	
	decoySprite.play("death")
	await decoySprite.animation_finished
	queue_free()

func _physics_process(_delta: float) -> void:
	pass

func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	
func growthCheck():
	growthProgress = 2

func destroy():
	if (decoySprite.frame == 9):
		decoySprite.visible = false


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies") and !enemies_in_attack_area.has(body):
		enemies_in_attack_area.append(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_attack_area.erase(body)
