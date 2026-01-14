extends CanvasModulate
class_name DayAndNightCycle 

signal changeDayTime(dayTime: DAY_STATE)

@onready var dayMusic: AudioStreamPlayer = $AudioStreamPlayer
@onready var nightMusic: AudioStreamPlayer = $AudioStreamPlayer2
@onready var map: Node2D = $"../Map"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D = $"../Player"

enum DAY_STATE{NOON, EVENING}
var dayTime : DAY_STATE = DAY_STATE.NOON

func _ready() -> void:
	add_to_group("dayAndNightCycle")
	dayMusic.play()
	pass
	
func _on_timer_timeout() -> void:
	if dayTime != DAY_STATE.EVENING:
		dayTime = DAY_STATE.EVENING
		map.changeNight()
		if(nightMusic.playing == false):
			dayMusic.stop()
			nightMusic.play()
		player.light.visible = true
		player.lightAni.play("lightOn")   
		SignalBus.emit_signal("NightTime")
		changeDayTime.emit(dayTime)
		animation_player.play("dayNNight")
		print("nightTIME!!")
	elif dayTime != DAY_STATE.NOON:
		SignalBus.emit_signal("DayTime")
		if(dayMusic.playing == false):
			nightMusic.stop()
			dayMusic.play()
		dayTime = DAY_STATE.NOON
		changeDayTime.emit(dayTime)
		player.lightAni.play("lightOff")  
		map.killAllChildren()
		animation_player.play("NightToDay")
		print("dayTIME!!")
