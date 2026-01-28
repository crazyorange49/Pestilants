extends CharacterBody2D

var speed: float = 400
var rotationSpeed: float = 100
var isInFarmPlot: bool = false
var isInPlant: bool = false
var activePlotPOS: Vector2
var NumberOfCollisions: int
var renewalSeeds: = 50
@onready var hud: CanvasLayer = $"../HUD"
@onready var hotbar: Hotbar = hud.get_child(0)
@onready var tooltip: Control = hud.get_child(2)
@onready var map: Map = $"../Map"
@onready var soilTiles: TileMapDual = $"../Map/SoilTiles"
@onready var plot_selector: Area2D = $PlotSelector
@onready var light: PointLight2D = $PointLight2D
@onready var lightAni: AnimationPlayer = $PointLight2D/AnimationPlayer
@export var ML: PackedScene
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var item_spawn: Marker2D = $itemSpawn
var maxHealth = 100
var health = 78
var minHealth = 0
var last_direction: Vector2
const ZMOONLIGHT_REFLECTOR = preload("uid://bjriv5fi8rcua")
const ZDECOYSPROUT = preload("uid://cu0nj78id1rtn")

func _ready():
	light.visible = false

func _physics_process(_delta: float) -> void:
	var moveInput = Input.get_vector("left","right", "up","down")
	velocity = moveInput * speed
	move_and_slide()
	handleMovementAnimations(moveInput)
	if(hotbar.currentSlot != null):
		if (hotbar.currentSlot.Item == ZMOONLIGHT_REFLECTOR or hotbar.currentSlot.Item == ZDECOYSPROUT) and !isInFarmPlot:
			tooltip.visible = true
		 
func handleMovementAnimations(Direction):
	if Direction == Vector2.ZERO:
		playIdleAnimation(last_direction)
		return
	
	if abs(Direction.x) > abs(Direction.y):
		if Direction.x > 0:
			sprite.play("walkRight")
			last_direction = Vector2.RIGHT
		else:
			sprite.play("walkLeft")
			last_direction = Vector2.LEFT
	else:
		if Direction.y > 0:
			sprite.play("walkDown")
			last_direction = Vector2.DOWN
		else:
			sprite.play("walkUp")
			last_direction = Vector2.UP
			
func playIdleAnimation(last_direction):
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			sprite.play("idleRight")
		else:
			sprite.play("idleLeft")
	else:
		if last_direction.y > 0:
			sprite.play("idleForward")
		else:
			sprite.play("idleBackward")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		var itemInUse = hotbar.currentSlot.Item
		if isInFarmPlot and hotbar.currentSlot != null and !isInPlant and itemInUse != ZMOONLIGHT_REFLECTOR and map.nightEnded:
			if itemInUse != null:
				var usedItem: Plant = load(itemInUse.scenePath.resource_path).instantiate()
				map.get_node("plantStorage").add_child(usedItem)
				hotbar.removeItem()
				usedItem.position = activePlotPOS
				usedItem.dayTimePos = activePlotPOS
				usedItem.onPlantPlaced()
		elif !isInFarmPlot and hotbar.currentSlot != null and itemInUse == ZMOONLIGHT_REFLECTOR or itemInUse == ZDECOYSPROUT:
			if itemInUse != null:
				var usedItem = load(itemInUse.scenePath.resource_path).instantiate()
				map.get_node("defenseStorage").add_child(usedItem)
				hotbar.removeItem()
				usedItem.position = item_spawn.global_position

func _on_plot_selector_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	activePlotPOS = soilTiles.map_to_local(soilTiles.local_to_map(position))
	NumberOfCollisions = len(plot_selector.get_overlapping_bodies())
	updateToolTip()

func _on_plot_selector_body_shape_exited(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	updateToolTip()

func getRenewalSeedCount() -> int:
	return renewalSeeds 

func changeRenewalSeedCount(x : int):
	renewalSeeds += x
	
func updateToolTip() -> void:
	var overlappingObjects = plot_selector.get_overlapping_bodies()
	if !hotbar.currentSlot:
		return
	if !hotbar.currentSlot.Item:
			return
	for object in overlappingObjects:
		if object.is_in_group("Plant"):
			isInPlant = true
		elif object.is_in_group("Plot"):
			isInFarmPlot = true
	if hotbar.currentSlot.Item.itemType == 1 and isInFarmPlot and !isInPlant:
		tooltip.visible = true
	elif hotbar.currentSlot.Item.itemType == 0 and !isInPlant:
		tooltip.visible = true
	else:
		tooltip.visible = false
		print_debug("no item or valid spot to place")
	isInFarmPlot = false
	isInFarmPlot = false
		
	
