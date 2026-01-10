extends CanvasLayer

@onready var hotbar: Hotbar = $Hotbar
@onready var timer: Label = $Timer
@onready var button: Button = $Button
@onready var tooltip: Control = $Tooltip
@onready var days_lived: Label = $DaysLived
@onready var map: Node2D = $"../Map"

func _updateDaysLived() -> void:
	days_lived.text = "Days: " + str(map.nightsSurived)

func _ready() -> void:
	days_lived.text = "Days: " + str(map.nightsSurived)
