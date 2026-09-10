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
## Map, told when to start a wave (changeNight) and when to clear it
## (killAllChildren).
@onready var map: Node2D = $"../Map"
## Plays the "dayNNight" and "NightToDay" fades over this node's tint.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D = $"../Player"
## The single repeating timer for the whole cycle -- its wait time is the
## length of one phase. Map can stop and re-fire it to end a night early.
@onready var timer: Timer = $Timer

## Only two phases: NOON is day, EVENING is night.
enum DAY_STATE{NOON, EVENING}
var dayTime : DAY_STATE = DAY_STATE.NOON

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
	if dayTime != DAY_STATE.EVENING:
		dayTime = DAY_STATE.EVENING
		if(nightMusic.playing == false):
			dayMusic.stop()
			nightMusic.play()
		player.light.visible = true
		player.lightAni.play("lightOn")   
		SignalBus.emit_signal("NightTime")
		animation_player.play("dayNNight")
		print("nightTIME!!")




## The main phase switch, fired by the Timer.
##
## First firing takes NOON -> EVENING: spawn the wave, lights on, night music.
## Second takes EVENING -> NOON: clear the field, lights off, day music.
## Map forces this to fire early when a wave is cleared.
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
	# Dawn. killAllChildren wipes any surviving enemies and is also where a
	# loss is detected.
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
