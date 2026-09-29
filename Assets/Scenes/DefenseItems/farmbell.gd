## The Farm Bell: a one-shot panic button that damages the whole wave.
##
## Bought from the shop rather than placed. It starts hidden and shopMenu
## makes it visible on purchase (see shopMenu.purchase_item), so an invisible
## bell means "not yet owned". Once owned, standing in range at night and
## pressing "use" rings it. It recharges at every day/night change.
class_name Farmbell
extends CharacterBody2D

## Reached for its tooltip, shown while the player stands in range.
@onready var hud: CanvasLayer = $"../HUD"
## Plays the ring flash on the bell's PointLight2D.
@onready var animation_player: AnimationPlayer = $PointLight2D/AnimationPlayer
@onready var point_light_2d: PointLight2D = $PointLight2D
## Only used to reach the SceneTree in _input(); the group lookup below is
## tree-wide, not limited to this node.
@onready var gameManager: MainScene = $"../"
@onready var hit_box: CollisionShape2D = $HitBox
@onready var ringPurple: PointLight2D = $RingPurple

@export var hitFlashColor: Color = Color(3.5, 1, 4, 1)
@export var zapColor: Color = Color(1.2, 1.2, 1.2, 1)
@export var shakeStrength: float = 7.0

## True while the player is inside the bell's VisionArea.
var isInRange: bool
## Unused; day/night state is tracked in currentState instead.
var isNightTime: bool
## Latest day/night phase, pushed in from DayAndNightCycle's changeDayTime.
var currentState: DayAndNightCycle.DAY_STATE
## Spent for the current night; cleared on every phase change.
var isUsed: bool = false

## Starts hidden: the bell only appears once bought from the shop.
func _ready() -> void:
	visible = false
	hit_box.disabled = true
	isInRange = false
	pass

func unlock() -> void:
	visible = true
	hit_box.disabled = false

## Show the "press use" tooltip, but only if the bell has been bought.
func _on_vision_area_body_entered(body: Node2D) -> void:
	if(visible) and body.is_in_group("Player"):
		hud.tooltip.visible = true
		isInRange = true
	pass # Replace with function body.

## Player left the bell; hide the tooltip either way.
func _on_vision_area_body_exited(body: Node2D) -> void:
	hud.tooltip.visible = false
	isInRange = false
	pass # Replace with function body.

## Ring the bell. Requires all four: the use action, the player in range,
## night time, and the bell not already spent this night.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use") and isInRange and !gameManager.dayAndNight.isDay and !isUsed:
		isUsed = true 
		point_light_2d.enabled = true
		animation_player.stop()
		animation_player.play("farmBellAni")
		_shakeCamera()
		for enemy in gameManager.enemyManager.getEnemies():
			_zap(enemy)
			enemy.subtractDamage(20)
		pass

func _zap(enemy: Node2D) -> void:
	var enemySprite := enemy.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if enemySprite:
		enemySprite.modulate = hitFlashColor
		enemySprite.create_tween().tween_property(enemySprite, "modulate", Color.WHITE, 0.6)
	var zap := PointLight2D.new()
	zap.texture = ringPurple.texture
	zap.color = zapColor
	zap.energy = 2.5
	zap.texture_scale = 0.1
	gameManager.add_child(zap)
	zap.global_position = enemy.global_position
	var tween := zap.create_tween().set_parallel()
	tween.tween_property(zap, "texture_scale", 1.3, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(zap, "energy", 0.0, 0.5)
	tween.chain().tween_callback(zap.queue_free)

func _shakeCamera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var tween := camera.create_tween()
	var steps := 7
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shakeStrength * falloff, 0.045)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.06)


## Wired from DayAndNightCycle.changeDayTime. Recharges the bell so it can
## be rung once per night.
func _on_day_and_night_change_day_time(dayTime: DayAndNightCycle.DAY_STATE) -> void:
	currentState = dayTime
	isUsed = false
