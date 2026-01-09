extends CanvasModulate
class_name DayAndNightCycle 

signal changeDayTime(dayTime: DAY_STATE)

@onready var map: Node2D = $"../Map"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D = $"../Player"
@onready var hud: Label = $"../HUD/DaysLived"

enum DAY_STATE{NOON, EVENING}
var dayTime : DAY_STATE = DAY_STATE.NOON

func _ready() -> void:
	add_to_group("dayAndNightCycle")
	pass
	
func _on_timer_timeout() -> void:
	if dayTime != DAY_STATE.EVENING:
		dayTime = DAY_STATE.EVENING
		map.changeNight()
		player.light.visible = true
		player.lightAni.play("lightOn")   
		changeDayTime.emit(dayTime)
		animation_player.play("dayNNight")
		print("nightTIME!!")
	elif dayTime != DAY_STATE.NOON:
		dayTime = DAY_STATE.NOON
		changeDayTime.emit(dayTime)
		player.lightAni.play("lightOff")  
		map.killAllChildren()
		hud.addNight()
		animation_player.play("NightToDay")
		print("dayTIME!!")
