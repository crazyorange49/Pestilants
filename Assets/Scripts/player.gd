## The player: movement, the seed wallet, and placing things from the hotbar.
##
## Placement has two distinct rules, both handled in _input():
##  - plants (itemType 1) may only go on a tilled soil plot, only during the
##    day, and only where no plant already stands
##  - defence items (itemType 0) go anywhere EXCEPT a plot, and drop at the
##    itemSpawn marker rather than snapping to the grid
##
## The PlotSelector Area2D in front of the player is what senses which of
## those situations applies; see updateToolTip().
extends CharacterBody2D

## Movement speed. rotationSpeed is unused.
var speed: float = 400
var rotationSpeed: float = 100
## Set by updateToolTip from what the PlotSelector currently overlaps, and
## read by _input to decide whether placement is legal.
var isInFarmPlot: bool = false
var isInPlant: bool = false
## Grid-snapped centre of the plot under the player, cached on plot entry and
## used as the planting position.
var activePlotPOS: Vector2
## Unused.
var NumberOfCollisions: int
## The seed wallet. Spent by the shop, topped up by Map on every enemy kill.
var renewalSeeds: = 50
## Reached by child index, so hud.tscn's child ORDER matters here: the
## hotbar must stay at index 0 and the tooltip at index 2.
@onready var hud: CanvasLayer = $"../HUD"
@onready var hotbar: Hotbar = hud.get_child(0)
@onready var tooltip: Control = hud.get_child(2)
@onready var map: Map = $"../Map"
## Soil layer, used to snap a world position onto the plot grid.
@onready var soilTiles: TileMapDual = $"../Map/SoilTiles"
## Small area in front of the player that detects plots and plants.
@onready var plot_selector: Area2D = $PlotSelector
## The lantern, switched on at night by DayAndNightCycle.
@onready var light: PointLight2D = $PointLight2D
@onready var lightAni: AnimationPlayer = $PointLight2D/AnimationPlayer
## Unused export.
@export var ML: PackedScene
@onready var sprite: AnimatedSprite2D = $Sprite2D
## Drop point for defence items, so they land in front of the player.
@onready var item_spawn: Marker2D = $itemSpawn
## Declared but unused -- the player cannot currently be damaged. The odd
## starting value of 78 has no effect.
var maxHealth = 100
var health = 78
var minHealth = 0
## Last non-zero facing, so the idle animation faces the right way.
var last_direction: Vector2
## The two items that are placed off-plot rather than on one, special-cased
## throughout the placement logic below.
const ZMOONLIGHT_REFLECTOR = preload("uid://bjriv5fi8rcua")
const ZDECOYSPROUT = preload("uid://cu0nj78id1rtn")

## Lantern starts off; night turns it on.
func _ready():
	light.visible = false

## Movement, plus keeping the tooltip visible while holding a defence item
## somewhere it could legally be dropped.
func _physics_process(_delta: float) -> void:
	var moveInput = Input.get_vector("left","right", "up","down")
	velocity = moveInput * speed
	move_and_slide()
	handleMovementAnimations(moveInput)
	if(hotbar.currentSlot != null):
		if (hotbar.currentSlot.Item == ZMOONLIGHT_REFLECTOR or hotbar.currentSlot.Item == ZDECOYSPROUT) and !isInFarmPlot:
			tooltip.visible = true
		 
## Picks a walk animation from the dominant input axis and remembers the
## facing for the idle pose.
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
			
## Idle pose matching the last direction walked.
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

## Places the held item.
##
## NOTE: line 74 reads hotbar.currentSlot.Item before the null checks below
## it, so an empty hotbar slot would fault here rather than being rejected.
## NOTE: the elif condition mixes `and` with `or` without parentheses, so it
## reduces to "(...moonlight reflector) or (item is a decoy sprout)" -- a
## decoy therefore passes even while standing on a plot.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		var itemInUse = hotbar.currentSlot.Item
		if isInFarmPlot and hotbar.currentSlot != null and !isInPlant and itemInUse != ZMOONLIGHT_REFLECTOR and map.nightEnded:
			if itemInUse != null:
			# Plants are parented into plantStorage and remember where they were
			# planted, so they can walk back to that spot each morning.
				var usedItem: Plant = load(itemInUse.scenePath.resource_path).instantiate()
				map.get_node("plantStorage").add_child(usedItem)
				hotbar.removeItem()
				usedItem.position = activePlotPOS
				usedItem.dayTimePos = activePlotPOS
				usedItem.onPlantPlaced()
		elif !isInFarmPlot and hotbar.currentSlot != null and itemInUse == ZMOONLIGHT_REFLECTOR or itemInUse == ZDECOYSPROUT:
			if itemInUse != null:
			# Defence items go into defenseStorage and are dropped in front of the
			# player instead of snapping to the plot grid.
				var usedItem = load(itemInUse.scenePath.resource_path).instantiate()
				map.get_node("defenseStorage").add_child(usedItem)
				hotbar.removeItem()
				usedItem.position = item_spawn.global_position

## Cache the snapped plot position when the selector touches something, then
## re-evaluate what can be placed.
func _on_plot_selector_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	activePlotPOS = soilTiles.map_to_local(soilTiles.local_to_map(position))
	NumberOfCollisions = len(plot_selector.get_overlapping_bodies())
	updateToolTip()

## Re-evaluate placement legality when the selector stops touching something.
func _on_plot_selector_body_shape_exited(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	updateToolTip()

## Seed wallet accessors, used by the HUD label and the shop.
func getRenewalSeedCount() -> int:
	return renewalSeeds 

func changeRenewalSeedCount(x : int):
	renewalSeeds += x
	
## Works out what the player is standing next to and shows or hides the
## placement tooltip accordingly.
##
## Also the only place isInFarmPlot / isInPlant are set, so _input() depends
## on this having run. It early-returns when no slot is selected, which
## leaves those flags at whatever they were.
func updateToolTip() -> void:
	var overlappingObjects = plot_selector.get_overlapping_bodies()
	var numOverlappingPlants: int = 0
	var numOverlappingPlots: int = 0
	if !hotbar.currentSlot:
		return
	if hotbar.currentSlot.Item:
		for object in overlappingObjects:
			if object.is_in_group("Plant"):
				numOverlappingPlants += 1
			elif object.is_in_group("Plot"):
				numOverlappingPlots += 1
		if numOverlappingPlants > 0:
			isInPlant = true
		else:
			isInPlant = false
		if numOverlappingPlots > 0:
			isInFarmPlot = true
		else:
			isInFarmPlot = false
		# itemType 1 = plant: needs a free plot. itemType 0 = defence item:
		# needs only to not be inside an existing plant.
		if hotbar.currentSlot.Item.itemType == 1 and isInFarmPlot and !isInPlant:
			tooltip.visible = true
		elif hotbar.currentSlot.Item.itemType == 0 and !isInPlant:
			tooltip.visible = true
		else:
			tooltip.visible = false
			print_debug("no item or valid spot to place")
		
	
