## The basic night-one enemy (the "aphid"), spawned from Enemy.tscn.
##
## Adds no behaviour of its own beyond retargeting on the Timer tick; all
## movement, target scoring and combat live in Enemy (enemySlime.gd). Its
## stats come from the exported values on Enemy.tscn, not from this script.
class_name TestEnemy
extends Enemy


## Fill health from maxHealth before Enemy._ready() runs. Enemy declares
## health with a setter but never initialises it, so each subclass must do
## this itself or the enemy would spawn on 0 hp and die to a single hit.
func _ready():
	health = maxHealth
	super._ready()

## Fired by the child Timer (0.5s, repeating) to re-pick a target, so enemies
## react to plants being placed or killed without checking every frame.
func _on_timer_timeout() -> void:
	_findNewTarget()
