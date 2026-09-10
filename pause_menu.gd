## The in-game pause menu, instanced inside the HUD.
##
## It only owns its two buttons; the actual pausing (and the show/hide of
## this panel) is handled by hud.gd.pauseMenu(), which this calls back into.
extends Control

## The HUD that owns this panel -- the node that actually holds pause state.
@onready var main = $".."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## Hands the toggle back to the HUD so pause state stays in one place.
func _on_resume_pressed() -> void:
	main.pauseMenu()


## Quits the application.
func _on_quit_pressed() -> void:
	get_tree().quit()
