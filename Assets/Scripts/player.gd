extends CharacterBody2D

var speed: float = 400
var rotationSpeed: float = 100
var isInFarmPlot: bool = false
@onready var label: Label = $Label
@onready var hud: CanvasLayer = $"../HUD"
@onready var hotbar: Hotbar = hud.get_child(0)


func _physics_process(_delta: float) -> void:
	var moveInput = Input.get_vector("left","right", "up","down")
	velocity = moveInput * speed
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use"):
		if isInFarmPlot:
			var slotInUse = hotbar.currentSlot
			var itemInUse = slotInUse.Item
			if itemInUse != null:
				hotbar.removeItem()
				itemInUse.position = position


func _on_plot_selector_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	isInFarmPlot = true

func _on_plot_selector_body_shape_exited(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	isInFarmPlot = false
