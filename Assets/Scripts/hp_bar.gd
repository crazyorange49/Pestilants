extends ProgressBar

var parent

func _ready():
	parent = get_parent()
	max_value = parent.maxHealth
	min_value = parent.minHealth

func _process(_delta):
	self.value = parent.health
	if parent.health != max_value:
		self.visible = true
		if parent.health == min_value:
			self.visible = false
	else:
		self.visible = false
