extends CanvasModulate
class_name DayAndNightCycle 

signal changeDayTime(dayTime: DAY_STATE)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer : Timer = $Timer

enum DAY_STATE{NOON, EVENING}
var dayTime : DAY_STATE = DAY_STATE.NOON

func _ready() -> void:
	add_to_group("dayAndNightCycle")
	
func _on_timer_timeout() -> void:
	if dayTime != DAY_STATE.EVENING:
		dayTime = DAY_STATE.EVENING
		changeDayTime.emit(dayTime)
		animation_player.play("dayNNight")
		print("nightTIME!!")
	elif dayTime != DAY_STATE.NOON:
		dayTime = DAY_STATE.NOON
		changeDayTime.emit(dayTime)
		animation_player.play("NightToDay")
		print("dayTIME!!")
