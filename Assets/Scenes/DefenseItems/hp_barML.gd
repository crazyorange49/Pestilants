extends ProgressBar

var parent
var maxValueAmount
var currentHealth
var minValueAmount

@onready var map: Map = $"../../../"


func _ready():
	maxValueAmount = map.maxHealth
	currentHealth = map.health
	minValueAmount = map.minHealth
	
func _process(_delta):
	self.value = map.health
	if map.health != maxValueAmount:
		self.visible = true
		if map.health == minValueAmount:
			self.visible = false
	else:
		self.visible = false
