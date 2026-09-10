## The "worm": slow, high-health, heavy-hitting enemy. Joins the waves once
## the player has survived 5 nights (see Map.changeNight).
##
## Behaviour is entirely inherited from Enemy (enemySlime.gd); only the
## exported stats on Big_Bug.tscn differ -- more health and damage, slower
## speed, and a longer attack cooldown.
class_name BigBug
extends Enemy


## Enemy declares health with a setter but never initialises it, so each
## subclass fills it from maxHealth before the base _ready() runs.
func _ready():
	health = maxHealth
	super._ready()

## Fired by the child Timer (0.5s, repeating) to re-pick a target.
func _on_timer_timeout() -> void:
	_findNewTarget()
