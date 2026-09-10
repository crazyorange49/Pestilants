## Script for the HUD's "Days:" label.
##
## Note that in practice hud.gd drives this label instead: its
## _updateDaysLived() writes map.nightsSurived straight into `text` whenever
## Map emits night_survived or nightLost. So addNight() and the local
## currentNight counter below are currently unused -- the _ready() text is the
## only part of this script that still takes effect.
extends Label

## Local night tally. Separate from Map.nightsSurived, and only advanced by
## addNight(), which nothing calls at the moment.
var currentNight = 0
## Self-reference; the script is attached to the Label it updates.
@onready var days_lived: Label = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentNight = 0
	days_lived.text = "Days: " + str(currentNight)


## Increments the local tally and redraws the label. Left over from an earlier
## wiring; hud.gd._updateDaysLived() does this job now.
func addNight():
	currentNight += 1
	days_lived.text = "Days: " + str(currentNight)
