extends Label


@onready var timer_label = $"."
@onready var timer = $"../../dayAndNight/Timer"
	
func _process(_delta):
	update_timer_label()
	
func time_between():
	var time_left = timer.time_left
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
func update_timer_label():
	timer_label.text = "%02d:%02d" % time_between()
	
