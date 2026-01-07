extends CharacterBody2D

var speed: float = 400
var rotationSpeed: float = 100
var isInFarmPlot: bool = false
var activePlotPOS: Vector2
var NumberOfCollisions: int
var renewalSeeds: = 15
@onready var hud: CanvasLayer = $"../HUD"
@onready var hotbar: Hotbar = hud.get_child(0)
@onready var map: TileMapDual = $"../Map/SoilTiles"
@onready var plot_selector: Area2D = $PlotSelector


func _physics_process(_delta: float) -> void:
	var moveInput = Input.get_vector("left","right", "up","down")
	velocity = moveInput * speed
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		if isInFarmPlot and hotbar.currentSlot != null:
			var itemInUse = hotbar.currentSlot.Item
			if itemInUse != null:
				var usedItem = load(itemInUse.scenePath.resource_path).instantiate()
				map.add_child(usedItem)
				hotbar.removeItem()
				usedItem.position = activePlotPOS


func _on_plot_selector_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	activePlotPOS = map.map_to_local(map.local_to_map(position))
	NumberOfCollisions = len(plot_selector.get_overlapping_bodies())
	if NumberOfCollisions > 1:
		return
	else:
		isInFarmPlot = true

func _on_plot_selector_body_shape_exited(_body_rid: RID, _boddy: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	isInFarmPlot = false

func getRenewalSeedCount() -> int:
	return renewalSeeds 
