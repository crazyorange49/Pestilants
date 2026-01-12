extends ProgressBar

var parent
var maxValueAmount
var minValueAmount

func _ready():
	parent = get_parent()
	maxValueAmount = parent.maxHealth
	minValueAmount = parent.minHealth
	
func _process(_delta):
	self.value = parent.health
	if parent.health != maxValueAmount:
		self.visible = true
		if parent.health == minValueAmount:
			self.visible = false
	else:
		self.visible = false
