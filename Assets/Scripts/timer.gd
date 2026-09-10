## Script for the HUD's countdown label.
##
## Displays the time left on the day/night cycle's Timer as MM:SS. It only
## reads that Timer -- DayAndNightCycle owns it and decides what happens when
## it fires.
extends Label


## Self-reference; the script is attached to the Label it writes to.
@onready var timer_label = $"."
## The shared cycle timer. Path is Hud -> .. (main scene) -> dayAndNight/Timer.
@onready var timer = $"../../dayAndNight/Timer"
	
func _process(_delta):
	update_timer_label()
	
## Splits the Timer's remaining seconds into [minutes, seconds] for display.
func time_between():
	var time_left = timer.time_left
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]
	
## Renders the remaining time zero-padded, e.g. "01:07".
func update_timer_label():
	timer_label.text = "%02d:%02d" % time_between()
	
