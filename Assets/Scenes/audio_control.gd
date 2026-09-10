## Volume slider for one audio bus, used on the options panel.
##
## Set audio_bus_name in the inspector to the bus this slider should control
## (as named in default_bus_layout.tres), so the same script drives several
## independent sliders.
extends HSlider
## Name of the bus to control, e.g. "Master".
@export var audio_bus_name : String
## Resolved bus index, looked up once at startup.
var audio_bus_id

func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	print(audio_bus_id)

## Slider values are linear 0-1 but bus volume is in decibels, so the value
## is converted rather than assigned directly.
func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	
	
	
