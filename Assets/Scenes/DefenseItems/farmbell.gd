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
@onready var enemyStorage: Node2D = $"../Map/enemyStorage"

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
	isInRange = false
	pass

## Show the "press use" tooltip, but only if the bell has been bought.
func _on_vision_area_body_entered(body: Node2D) -> void:
	if(visible):
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
	if event.is_action_pressed("use") and isInRange and currentState == DayAndNightCycle.DAY_STATE.EVENING and !isUsed:
		isUsed = true 
		point_light_2d.enabled = true
		animation_player.play("farmBellAni")
		
		# NOTE: only Enemy.tscn (the aphid) is in the "Enemies" group -- Fly.tscn
		# and Big_Bug.tscn are not, so the bell currently cannot damage them.
		for enemy in enemyStorage.get_tree().get_nodes_in_group("Enemies"):
			enemy.subtractDamage(20)
		pass


## Wired from DayAndNightCycle.changeDayTime. Recharges the bell so it can
## be rung once per night.
func _on_day_and_night_change_day_time(dayTime: DayAndNightCycle.DAY_STATE) -> void:
	currentState = dayTime
	isUsed = false
