## Floating health bar used by enemies and plants.
##
## Reads its values straight off its parent node each frame, so any parent
## exposing maxHealth / minHealth / health works. Hides itself at full health
## (nothing to report) and again at minimum health (the owner is dying).
extends ProgressBar

## Whatever node this bar is a child of. Must expose maxHealth, minHealth
## and health.
var parent

## Cache the bar range once from the parent. Note this reads the parent at
## its own _ready() time, so the parent must have set maxHealth by then.
func _ready():
	parent = get_parent()
	max_value = parent.maxHealth
	min_value = parent.minHealth

## Polled rather than signal-driven, so the bar tracks damage from any
## source without every damage path having to notify it.
func _process(_delta):
	self.value = parent.health
	if parent.health != max_value:
		self.visible = true
		if parent.health == min_value:
			self.visible = false
	else:
		self.visible = false
