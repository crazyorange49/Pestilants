class_name Plant
extends CharacterBody2D

static var group: StringName = "plant"

var dayTimePosition: Vector2

@export var enemyPriority: int
@export var stats: Resource
@export var atkDamage: int
@export var maxHealth: int 
@export var minHealth: int 
@export var atkCoolDownInSeconds: float
@export var visionRadius: float
@export var atkRange: float
@export var speed: float
@onready var TimeState: DayAndNightCycle = $"../../../dayAndNight"
@onready var visionCollisionBox: CollisionShape2D = $VisionArea/Radius
@export var attackRangeCollisionBox: CollisionShape2D
@onready var map: Map = $"../../"
@onready var navRegions = map.navMap.get_children()
@export var navigationAgent2d: NavigationAgent2D
@onready var visionArea: Area2D = $VisionArea
@export var sprite: AnimatedSprite2D


var enemysInSight: Array[Node2D]
var Direction: Vector2 = dayTimePos
var availablePlants: Array[Node]
var isBackHome: bool = true
var isTarget: bool = false
var dayTimePos: Vector2
var attackTarget = null
var can_attack = true
@export var growthProgress: int
var victim

func _init(p_growthProgress: int = 0, p_maxHealth: int = 0, p_atkDamage: int = 0, p_atkCoolDownInSeconds: float = 0.0, p_visionRadius: float = 0.0, p_speed: float = 0.0, p_atkRange: float = 0.0) -> void:
	maxHealth = p_maxHealth
	growthProgress = 0
	atkDamage = p_atkDamage
	atkCoolDownInSeconds  = p_atkCoolDownInSeconds
	visionRadius  = p_visionRadius
	atkRange = p_atkRange
	speed = p_speed

func _ready() -> void:
	SignalBus.connect("EnemyDeath", Callable(self, "onEnemyDeath"))
	SignalBus.connect("NightTime", Callable(self, "growthCheck"))
	SignalBus.connect("DayTime", Callable(self, "growthCheck"))
	sprite.animation = "growth"
	sprite.frame = growthProgress
	visionCollisionBox.shape.radius = visionRadius
	attackRangeCollisionBox.shape.radius = atkRange
	map.numberOfPlants += 1

func _physics_process(delta: float) -> void:
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

@export var health: int:
	set(subtractedHealth):
		health = clamp(subtractedHealth, minHealth, maxHealth)
		if health <= 0:
			die()
	get:
		return health

func die() -> void:
	queue_free()
	SignalBus.emit_signal("PlantDeath")


func onPlantPlaced():
	dayTimePosition = position

func subtractDamage(damage: int, attacker: Node2D = null) -> void:
	health -= damage

func addHealth(healing: int) -> void:
	health += healing

func getNewPosition():
	var navRID: RID
	if map.nightsSurived == -1:
		navRID= navRegions[0].get_rid()
	else:
		navRID= navRegions[randi() % (map.nightsSurived + 1)].get_rid()
	navigationAgent2d.target_position = (NavigationServer2D.region_get_random_point(navRID, 1, false))
	
func calculateVulnerability(currentHealth: int, targetMaxHealth: int):
	return exp(-currentHealth / targetMaxHealth)

func attack():
	if (!can_attack || growthProgress < 2):
		return

	can_attack = false
	victim.subtractDamage(atkDamage)

	await get_tree().create_timer(atkCoolDownInSeconds).timeout
	can_attack = true

func  calculateCloseness(dist: float) -> float:
	var distScale = 8.0
	return exp(-dist / distScale)

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

func onEnemyDeath():
	if attackTarget and !is_instance_valid(attackTarget):
		attackTarget = null
		victim = null
	enemysInSight = visionArea.get_overlapping_bodies()

func growthCheck():
	if(growthProgress < 2):
		growthProgress += 1
		sprite.frame = growthProgress
