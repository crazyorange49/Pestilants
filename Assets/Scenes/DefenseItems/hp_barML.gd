## Health bar for the Moonlight Reflector.
##
## Same idea as hp_bar.gd but keeps its own copies of the range values under
## different names. Kept separate because the reflector is not a Plant and
## sits at a different depth in the scene tree.
extends ProgressBar

## The Moonlight Reflector this bar is attached to.
var parent
## Bar range, cached once in _ready().
var maxValueAmount
## Set once in _ready() and never read again -- the live value is taken
## straight from parent.health in _process().
var currentHealth
var minValueAmount

## Unused. Present so the bar could reach Map (e.g. to hide during the day)
## if that is ever needed.
@onready var map: Map = $"../../../"


## Cache the bar range from the reflector.
func _ready():
	parent = get_parent()
	maxValueAmount = parent.maxHealth
	currentHealth = parent.health
	minValueAmount = parent.minHealth
	
## Polled every frame; hides at full health and again at minimum health.
func _process(_delta):
	self.value = parent.health
	if parent.health != maxValueAmount:
		self.visible = true
		if parent.health == minValueAmount:
			self.visible = false
	else:
		self.visible = false
