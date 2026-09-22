## The clock. Owns the day/night timer and drives every phase change.
##
## It is a CanvasModulate, so it also *is* the tint over the world -- the
## AnimationPlayer animates this node's colour to fade between day and night.
##
## On each phase change it swaps the music, toggles the player's lantern,
## broadcasts NightTime/DayTime on the SignalBus (which is what makes plants
## grow and the Moonlight Reflector decay), and tells Map to spawn the wave
## or clear the field.
extends CanvasModulate
class_name DayAndNightCycle 

## Emitted on every phase change. The Farm Bell listens so it knows whether
## it can currently be rung.
signal changeDayTime(dayTime: DAY_STATE)

## Day and night tracks; only one plays at a time.
@onready var dayMusic: AudioStreamPlayer = $AudioStreamPlayer
@onready var nightMusic: AudioStreamPlayer = $AudioStreamPlayer2
## Plays the "dayNNight" and "NightToDay" fades over this node's tint.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D = $"../Player"

## Only two phases: NOON is day, EVENING is night.
enum DAY_STATE{NOON, EVENING}
var dayTime : DAY_STATE = DAY_STATE.NOON
var isDay: bool = true

## Starts the day music. The timer autostarts from the scene.
func _ready() -> void:

	add_to_group("dayAndNightCycle")
	dayMusic.play()
	pass
	
## Alternate way into night, used by main_scene.nextNight().
##
## NOTE: this is the dusk half of _on_timer_timeout minus two things -- it
## does not call map.changeNight() (the caller does that itself) and it does
## not emit changeDayTime, so the Farm Bell would not learn it is night if
## the night were started this way.
func startNight() -> void:
	changeDayTime.emit(dayTime)
	if dayTime != DAY_STATE.EVENING:
		dayTime = DAY_STATE.EVENING
		if(nightMusic.playing == false):
			dayMusic.stop()
			nightMusic.play()
		player.light.visible = true
		player.lightAni.play("lightOn")   
		SignalBus.emit_signal("NightTime")
		animation_player.play("dayNNight")
		isDay = false
		print("nightTIME!!")

func startDay() -> void:
	changeDayTime.emit(dayTime)
	if dayTime != DAY_STATE.NOON:
		SignalBus.emit_signal("DayTime")
		if(dayMusic.playing == false):
			nightMusic.stop()
			dayMusic.play()
		dayTime = DAY_STATE.NOON
		player.lightAni.play("lightOff")  
		animation_player.play("NightToDay")
		isDay = true
		print("dayTIME!!")
