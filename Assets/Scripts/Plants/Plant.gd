## Base class for every placeable plant (Bravestem, Sunpetal, Rosebush,
## Coneflower, and the Decoy Sprout).
##
## Holds the shared pieces: stats, health, growth, night roaming and the
## target-scoring helpers. Subclasses supply the actual combat loop in their
## own _process() and decide what a "target" means -- an enemy to hit for
## Sunpetal/Bravestem, an injured ally to heal for Coneflower.
##
## Two things drive most of the behaviour here:
##  - growthProgress must reach 2 before a plant does anything at all.
##    growthCheck() is connected to BOTH NightTime and DayTime, so it takes
##    two phase changes -- one full night/day cycle -- for a freshly placed
##    plant to become active.
##  - plants are not stationary. They walk out to a random spot at dusk and
##    return to where they were planted at noon (see _physics_process).
class_name Plant
extends CharacterBody2D

## Unused. The group actually checked throughout the codebase is "Plant"
## (capitalised), assigned on the plant scenes themselves rather than here.
static var group: StringName = "plant"

## Where the plant was planted; it walks back here each morning. Set by
## onPlantPlaced(), which player.gd calls after placing.
var dayTimePosition: Vector2

## How strongly enemies are drawn to this plant, used by
## Enemy.calculatePriority. The Decoy Sprout sets this high to pull aggro.
@export var enemyPriority: int
## Unused hook for a stats resource.
@export var stats: Resource
@export var atkDamage: int
## Health bounds. The exported values live on each plant scene, and each
## subclass copies maxHealth into health in its own _ready().
@export var maxHealth: int 
@export var minHealth: int 
## Seconds between attacks (or heals, for Coneflower).
@export var atkCoolDownInSeconds: float
## Radius of VisionArea -- how far the plant notices things.
@export var visionRadius: float
## Radius of the attack area -- how close before it can actually strike.
@export var atkRange: float
## Roaming speed, used only while walking out at dusk or home at noon.
@export var speed: float
## Shared day/night state, read to decide whether to roam or return.
@onready var TimeState: DayAndNightCycle = $"../../../dayAndNight"
@onready var visionCollisionBox: CollisionShape2D = $VisionArea/Radius
@export var attackRangeCollisionBox: CollisionShape2D
## The Map, used for numberOfPlants, availableTargets and the nav regions.
@onready var map: Map = $"../../"
## The NavigationRegion2Ds under Map/NavMap. getNewPosition() picks one of
## these to wander into, and how many are eligible grows with nightsSurived.
@onready var navRegions = map.navMap.get_children()
@export var navigationAgent2d: NavigationAgent2D
@onready var visionArea: Area2D = $VisionArea
@export var sprite: AnimatedSprite2D


## Enemies currently inside VisionArea; refreshed on enter/exit and whenever
## any enemy dies.
var enemysInSight: Array[Node2D]
## NOTE: dayTimePos is declared further down, so it is still (0, 0) when this
## initialiser runs. Harmless -- _physics_process overwrites Direction.
var Direction: Vector2 = dayTimePos
var availablePlants: Array[Node]
## False while the plant is out roaming, true once it is back at dayTimePos.
var isBackHome: bool = true
## Unused flag.
var isTarget: bool = false
var dayTimePos: Vector2
## What the plant currently wants to act on. victim is the same thing once it
## is actually within attack range.
var attackTarget = null
## Attack cooldown gate, cleared and re-set by attack().
var can_attack = true
## 0 and 1 are seedling stages; at 2 the plant is mature and can act. Also
## used as the sprite frame for the "growth" animation.
@export var growthProgress: int
var victim

## NOTE: has no practical effect for plants instantiated from a scene. Godot
## calls _init() with no arguments, so every parameter takes its default of
## zero, and the exported values from the .tscn are applied afterwards --
## overwriting everything assigned here.
func _init(p_growthProgress: int = 0, p_maxHealth: int = 0, p_atkDamage: int = 0, p_atkCoolDownInSeconds: float = 0.0, p_visionRadius: float = 0.0, p_speed: float = 0.0, p_atkRange: float = 0.0) -> void:
	maxHealth = p_maxHealth
	growthProgress = 0
	atkDamage = p_atkDamage
	atkCoolDownInSeconds  = p_atkCoolDownInSeconds
	visionRadius  = p_visionRadius
	atkRange = p_atkRange
	speed = p_speed

## Applies the exported radii to the actual collision shapes and registers
## the plant with Map. Subclasses call this via super._ready() -- Decoy
## Sprout is the one that does not, and so skips all of it.
func _ready() -> void:
	SignalBus.connect("EnemyDeath", Callable(self, "onEnemyDeath"))
	SignalBus.connect("NightTime", Callable(self, "growthCheck"))
	SignalBus.connect("DayTime", Callable(self, "growthCheck"))
	sprite.animation = "growth"
	sprite.frame = growthProgress
	visionCollisionBox.shape.radius = visionRadius
	attackRangeCollisionBox.shape.radius = atkRange
	map.numberOfPlants += 1

## Roaming. At dusk the plant walks toward whatever nav target it was given;
## at noon it heads back to where it was planted and then stops.
func _physics_process(delta: float) -> void:
	# Immature plants are completely inert -- no roaming, no combat.
	if(growthProgress < 2):
		return
	Direction = Vector2.ZERO
	if TimeState.dayTime == TimeState.DAY_STATE.EVENING:
		isBackHome = false
		Direction = (navigationAgent2d.get_next_path_position() - global_position).normalized()
		velocity =  velocity.lerp(Direction * speed, delta)
		move_and_slide()
	elif !isBackHome and TimeState.dayTime == TimeState.DAY_STATE.NOON:
		navigationAgent2d.target_position = dayTimePos
		Direction = (navigationAgent2d.get_next_path_position() - global_position).normalized()
		velocity =  velocity.lerp(Direction * speed, delta)
		move_and_slide()
		if navigationAgent2d.is_target_reached():
			isBackHome = true
			isTarget = false

## Health, clamped to the plant's bounds. Assigning 0 or less triggers die(),
## so all damage and healing funnels through this one setter.
@export var health: int:
	set(subtractedHealth):
		health = clamp(subtractedHealth, minHealth, maxHealth)
		if health <= 0:
			die()
	get:
		return health

## Frees the plant and tells Map to recount. NOTE: queue_free() is deferred,
## so the node is still a child of plantStorage when Map._plantDeath() runs.
func die() -> void:
	queue_free()
	SignalBus.emit_signal("PlantDeath")


## Called by player.gd once the plant is placed, recording the spot it should
## return to each morning.
func onPlantPlaced():
	dayTimePosition = position

## Standard damage entry point. The attacker is ignored here; Rosebush
## overrides this to hit back with thorns.
func subtractDamage(damage: int, attacker: Node2D = null) -> void:
	health -= damage

## Healing entry point, used by Coneflower.
func addHealth(healing: int) -> void:
	health += healing

## Picks a random point inside one of the map's nav regions to wander to.
## The number of regions in play grows with nightsSurived, so the plant's
## roaming range widens as the safe zone is reclaimed.
func getNewPosition():
	var navRID: RID
	if map.nightsSurived == -1:
		navRID= navRegions[0].get_rid()
	else:
		navRID= navRegions[randi() % (map.nightsSurived + 1)].get_rid()
	navigationAgent2d.target_position = (NavigationServer2D.region_get_random_point(navRID, 1, false))
	
## Scores how badly hurt a target is; lower health should mean a higher
## score. NOTE: both arguments are ints, so the division is integer
## division and truncates to 0 for any partially damaged target and -1 only
## at full health. In practice this returns 1.0 for anything damaged at all
## and ~0.368 for a full-health target, rather than scaling smoothly.
func calculateVulnerability(currentHealth: int, targetMaxHealth: int):
	return exp(-currentHealth / targetMaxHealth)

## Default attack: damage the current victim, then sit on cooldown.
## Coneflower overrides this to heal instead.
func attack():
	if (!can_attack || growthProgress < 2):
		return

	can_attack = false
	victim.subtractDamage(atkDamage)

	await get_tree().create_timer(atkCoolDownInSeconds).timeout
	can_attack = true

## Distance falloff for scoring. distScale is small (8), so this drops off
## very sharply -- effectively only near-touching targets score on distance.
func  calculateCloseness(dist: float) -> float:
	var distScale = 8.0
	return exp(-dist / distScale)

## Combined target score: mostly "how hurt is it", a little "how close is
## it", minus a penalty for switching away from the current target so plants
## do not flip-flop between targets every frame.
func calculatePriority(target) -> float:
	var score = 0.0
	var pentaltyForSwitch = 1
	var healthWeight = 0.6
	var distanceWeight = 0.1
	score += calculateVulnerability(target.health, target.maxHealth) * healthWeight
	score += calculateCloseness(position.distance_to(target.position)) * distanceWeight
	if target != attackTarget:
		score -= pentaltyForSwitch
	
	return score

## Any enemy dying invalidates cached targets, so clear them and re-read what
## is actually still in sight.
func onEnemyDeath():
	if attackTarget and !is_instance_valid(attackTarget):
		attackTarget = null
		victim = null
	enemysInSight = visionArea.get_overlapping_bodies()

## Advances one growth stage, up to the mature stage 2. Connected to both
## NightTime and DayTime, so a plant matures over one full day/night cycle.
func growthCheck():
	if(growthProgress < 2):
		growthProgress += 1
		sprite.frame = growthProgress
