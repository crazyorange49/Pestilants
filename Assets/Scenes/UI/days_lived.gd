extends Label

var currentNight = 0
@onready var days_lived: Label = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentNight = 0
	days_lived.text = "Days: " + str(currentNight)

func addNight():
	currentNight += 1
	days_lived.text = "Days: " + str(currentNight)
