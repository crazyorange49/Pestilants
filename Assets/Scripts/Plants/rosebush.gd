## The Rosebush: the defensive plant (25 seeds).
##
## Purely reactive -- it never attacks on its own. Instead it overrides
## subtractDamage() so that anything hitting it takes thorn damage back.
## That makes it a wall meant to soak hits near the other plants.
##
## Because it has no attack loop, the atkDamage and atkCoolDownInSeconds
## exports on Rosebush.tscn are unused; thornDamage below is what matters.
class_name Rosebush
extends Plant

## Swapped between the day and night idle animations by _process.
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
## Damage reflected back at whatever just hit this plant.
@export var thornDamage: int = 10

## Whoever landed the most recent hit, captured from the attacker argument.
var last_attacker: Enemy = null

## super._ready() does the shared Plant setup; health has to be filled in
## afterwards because Plant leaves it at zero.
func _ready() -> void:
	super._ready()
	health = maxHealth

## Only keeps the idle animation in sync -- no combat loop here.
func _process(delta: float) -> void:
	# Immature plants do nothing at all.
	if(growthProgress < 2):
		return
	if( map.nightEnded == true ):
		animated_sprite_2d.play("dayIdle")
	else:
		animated_sprite_2d.play("nightIdle")
	
## Takes the hit through the base implementation, then punishes the attacker.
## This is the only place the attacker argument on subtractDamage is used;
## Enemy.attack() passes itself in for exactly this.
func subtractDamage(damage: int, attacker: Node2D = null) -> void:
	last_attacker = attacker
	super.subtractDamage(damage)

	if last_attacker and is_instance_valid(last_attacker):
		last_attacker.subtractDamage(thornDamage)
	
## Unused: the Rosebush does not seek or track targets.
func _on_vision_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


## Unused: retaliation happens in subtractDamage, not on contact.
func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


## Unused: the Rosebush does not seek or track targets.
func _on_vision_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.



## Unused: the Rosebush does not seek or track targets.
func _on_attack_area_body_exited(body: Node2D) -> void:
	pass


## Wanders unconditionally -- unlike the attacking plants, it has no target
## to stay put for.
func _on_nav_timer_timeout() -> void:
	getNewPosition()
