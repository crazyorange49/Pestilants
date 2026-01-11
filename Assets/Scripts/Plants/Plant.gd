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
@export var atkRange: float
@export var speed: float
@onready var TimeState: DayAndNightCycle = $"../../../dayAndNight"
@onready var visionCollisionBox: CollisionShape2D = $VisionArea/Radius
@onready var attackRangeCollisionBox: CollisionShape2D = $AttackArea/Range
@onready var map: Map = $"../../"
@onready var navRegions = map.navMap.get_children()
@onready var navigationAgent2d: NavigationAgent2D = $NavigationAgent2D


var dayTimePos: Vector2
var Direction: Vector2 = dayTimePos
var isBackHome: bool = true
var isTarget: bool = false

func _init(p_maxHealth: int = 0, p_atkDamage: int = 0, p_atkCoolDownInSeconds: float = 0.0, p_visionRadius: float = 0.0, p_movementSpeed: float = 0.0, p_atkRange: float = 0.0) -> void:
	maxHealth = p_maxHealth
	atkDamage = p_atkDamage
	atkCoolDownInSeconds  = p_atkCoolDownInSeconds
	visionRadius  = p_visionRadius
	atkRange = p_atkRange

func _ready() -> void:
	visionCollisionBox.shape.radius = visionRadius
	attackRangeCollisionBox.shape.radius = atkRange
	map.numberOfPlants += 1
	print_debug("plant added: " + str(map.numberOfPlants))

func _physics_process(delta: float) -> void:
	pass
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
	set(subtractedHealth):
		health = clamp(health - subtractedHealth, 0, maxHealth) 
		if health <= 0:
			pass
	get:
		return health

func onPlantPlaced():
	dayTimePosition = position

func subtractDamage(damage: int) -> void:
	health -= damage
	
func getNewPosition():
	var navRID: RID = navRegions[randi() % (map.nightsSurived + 1)].get_rid()
	navigationAgent2d.target_position = (NavigationServer2D.region_get_random_point(navRID, 1, false))
	


	
