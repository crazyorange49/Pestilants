extends CharacterBody2D

var speed: float = 400
var rotationSpeed: float = 100
var isInFarmPlot: bool = false
var isInPlant: bool = false
var activePlotPOS: Vector2
var NumberOfCollisions: int
var renewalSeeds: = 100
@onready var hud: CanvasLayer = $"../HUD"
@onready var hotbar: Hotbar = hud.get_child(0)
@onready var tooltip: Control = hud.get_child(3)
@onready var Map: Node2D = $"../Map"
@onready var soilTiles: TileMapDual = $"../Map/SoilTiles"
@onready var plot_selector: Area2D = $PlotSelector
@onready var light: PointLight2D = $PointLight2D
@onready var lightAni: AnimationPlayer = $PointLight2D/AnimationPlayer
var maxHealth = 100
var health = 78
var minHealth = 0

func _ready():
	light.visible = false

func _physics_process(_delta: float) -> void:
	var moveInput = Input.get_vector("left","right", "up","down")
	velocity = moveInput * speed
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		if isInFarmPlot and hotbar.currentSlot != null and !isInPlant:
			var itemInUse = hotbar.currentSlot.Item
			if itemInUse != null:
				var usedItem: Plant = load(itemInUse.scenePath.resource_path).instantiate()
				Map.get_node("plantStorage").add_child(usedItem)
				hotbar.removeItem()
				usedItem.position = activePlotPOS
				usedItem.dayTimePos = activePlotPOS
				usedItem.onPlantPlaced()


func _on_plot_selector_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	activePlotPOS = soilTiles.map_to_local(soilTiles.local_to_map(position))
	NumberOfCollisions = len(plot_selector.get_overlapping_bodies())
	if body.is_in_group("Plant"):
		isInPlant = true
	elif body.is_in_group("Plot"):
		isInFarmPlot = true
	if body.is_in_group("Item") and !isInPlant:
		tooltip.visible = true

func _on_plot_selector_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body.is_in_group("Plant"):
		isInPlant = false
	elif body.is_in_group("Plot"):
		isInFarmPlot = false
	if body.is_in_group("Item"):
		tooltip.visible = false

func getRenewalSeedCount() -> int:
	return renewalSeeds 

func changeRenewalSeedCount(x : int):
	renewalSeeds += x
	

		
		
	
