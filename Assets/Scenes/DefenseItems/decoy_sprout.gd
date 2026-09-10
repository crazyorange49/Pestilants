## The Decoy Sprout: bait that detonates when it dies.
##
## Extends Plant for its health and targeting hooks but deliberately opts out
## of most plant behaviour -- it does not roam, attack on a cooldown, or grow.
## Its high enemyPriority (set in DecoySprout.tscn) pulls enemies onto it, and
## when it is destroyed it damages whatever was crowded around it.
##
## Placed into Map/defenseStorage rather than plantStorage (see player.gd).
extends Plant
class_name DecoySprout

## Unused here; kept as a handle on the shared day/night timer.
@onready var timer: Timer = $"../../../dayAndNight/Timer"
@onready var decoySprite: AnimatedSprite2D = $AnimatedSprite2D
#@onready var enemies: Node2D = $"../../enemyStorage"
## Guards die() so the detonation and death animation only run once.
var is_dead = false
## Enemies currently inside the AttackArea, damaged on death.
var enemies_in_attack_area: Array[Node2D] = []

## NOTE: does not call super._ready(). Plant._ready() is what applies the
## exported visionRadius/atkRange to the collision shapes, increments
## map.numberOfPlants, and connects the growth signals -- none of that
## happens for a decoy. DecoyPlanted tells Map to refresh its defence list.
func _ready():
	health = maxHealth
	SignalBus.connect("DayTime", Callable(self, "destroy"))
	SignalBus.emit_signal("DecoyPlanted")
	

## Empty on purpose: overrides Plant._process so the decoy stays inert.
func _process(_float) -> void:
	pass

## Detonate. Overrides Plant.die() to damage nearby enemies for a flat 30
## before playing the death animation and freeing the node.
func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	# NOTE: this list only holds aphids -- the enter callback below filters on
	# the "Enemies" group, which Fly.tscn and Big_Bug.tscn are not in.
	for enemy in enemies_in_attack_area:
		if is_instance_valid(enemy):
			enemy.subtractDamage(30)

	enemies_in_attack_area.clear()
	
	decoySprite.play("death")
	await decoySprite.animation_finished
	queue_free()

## Empty on purpose: overrides Plant._physics_process so the decoy never
## walks out at dusk or returns at noon like a real plant.
func _physics_process(_delta: float) -> void:
	pass

## Player walked out of range; hide the placement tooltip.
func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	
## Overrides Plant.growthCheck to skip growth entirely -- a decoy is fully
## active the moment it is placed, where real plants need two day/night
## ticks to reach growthProgress 2.
func growthCheck():
	growthProgress = 2

## Connected to DayTime: hides the sprite at dawn, but only if the death
## animation had reached its final frame.
func destroy():
	if (decoySprite.frame == 9):
		decoySprite.visible = false


## Track enemies entering the blast radius.
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies") and !enemies_in_attack_area.has(body):
		enemies_in_attack_area.append(body)

## NOTE: checks the group as lowercase "enemies" while the enter callback
## above uses "Enemies". The names do not match, so enemies are never
## removed from the list once added.
func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_attack_area.erase(body)
