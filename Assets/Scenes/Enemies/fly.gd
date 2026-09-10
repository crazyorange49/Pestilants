## Fast, fragile flier. Joins the waves once the player has survived 3
## nights (see Map.changeNight).
##
## Behaviour is entirely inherited from Enemy (enemySlime.gd); only the
## exported stats on Fly.tscn differ -- higher speed, lower health.
class_name Fly
extends Enemy


## Enemy declares health with a setter but never initialises it, so each
## subclass fills it from maxHealth before the base _ready() runs.
func _ready():
	health = maxHealth
	super._ready()

## Fired by the child Timer (0.5s, repeating) to re-pick a target.
func _on_timer_timeout() -> void:
	_findNewTarget()
