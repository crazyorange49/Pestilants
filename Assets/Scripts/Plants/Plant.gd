class_name Plant
extends CharacterBody2D

static var group: StringName = "plant"

var dayTimePosition: Vector2

@export var enemyPriority: int
@export var stats: Resource = preload("uid://csr8dxvj1ns2l")
@export var atkDamage: int
@export var maxHealth: int
@export var minHealth: int
@export var atkCoolDownInSeconds: float
@export var visionRadius: float
@export var movementSpeed: float
@export var atkRange: float
@export var speed: float
@onready var TimeState: DayAndNightCycle = $"../../dayAndNight"
@onready var visionCollisionBox: CollisionShape2D = $VisionArea/Radius
@onready var attackRangeCollisionBox: CollisionShape2D = $AttackArea/Range
@onready var navMap: Node2D = $"../NavMap"
@onready var navRegions = navMap.get_children()


var dayTimePos: Vector2
var direction
func _init(p_maxHealth: int = 0, p_atkDamage: int = 0, p_atkCoolDownInSeconds: float = 0.0, p_visionRadius: float = 0.0, p_movementSpeed: float = 0.0, p_atkRange: float = 0.0) -> void:
	maxHealth = p_maxHealth
	atkDamage = p_atkDamage
	atkCoolDownInSeconds  = p_atkCoolDownInSeconds
	visionRadius  = p_visionRadius
	movementSpeed  = p_movementSpeed
	atkRange = p_atkRange

func _ready() -> void:
	visionCollisionBox.shape.radius = visionRadius
	attackRangeCollisionBox.shape.radius = atkRange
	
func _physics_process(delta: float) -> void:
	if TimeState.dayTime == TimeState.DAY_STATE.EVENING:
		var navRID: RID = navRegions[0].get_rid()
		direction = Vector2.ZERO
		direction = (NavigationServer2D.region_get_random_point(navRID, 1, false) - global_position).normalized()
		velocity = velocity.lerp(direction * speed, delta)
		print_debug(velocity)
		move_and_collide(velocity)


var icon : Texture = stats.icon:
	set(icon):
		stats.icon = icon
	get:
		return icon
		
var maxStackSize: int = stats.maxStackSize:
	set(maxSize):
		stats.maxStackSize = maxSize
	get:
		return maxStackSize
		
var itemName: StringName = stats.itemName:
	set(name):
		stats.itemName = name
	get:
		return itemName

@export var health: int:
	set(newHealth):
		health = clamp(newHealth, 0, maxHealth) 
	get:
		return health

func onPlantPlaced():
	dayTimePosition = position

func subtractDamage(damage: int) -> void:
	health -= damage
