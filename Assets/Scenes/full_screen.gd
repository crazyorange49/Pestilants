## Fullscreen toggle for the options panel.
##
## NOTE: _ready() forces windowed mode every time this node enters the tree,
## so the choice is not remembered between visits to the options screen.
extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)





## Applies the toggle immediately.
func _on_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
