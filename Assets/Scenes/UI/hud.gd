extends CanvasLayer

@onready var hotbar: Hotbar = $Hotbar
@onready var timer: Label = $Timer
@onready var tooltip: Control = $Tooltip
@onready var days_lived: Label = $DaysLived
@onready var map: Node2D = $"../Map"
@onready var  pause_menu = $PauseMenu
var paused = false

func _updateDaysLived() -> void:
	var updatedText = "Days: " + str(map.nightsSurived)
	if map.nightsSurived == -1:
		updatedText = "Last night"
	days_lived.text = updatedText

func _ready() -> void:
	days_lived.text = "Days: " + str(map.nightsSurived)

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
func pauseMenu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale=0
	paused = !paused
