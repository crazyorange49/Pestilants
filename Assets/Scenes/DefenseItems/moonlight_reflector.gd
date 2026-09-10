## The Moonlight Reflector: a stationary night turret placed outside farm
## plots.
##
## Damages every enemy standing in its light on a repeating timer, and only
## while it is night. It also decays: each dawn costs it 20 health, so it
## lasts a limited number of nights rather than being permanent.
extends CharacterBody2D
class_name MoonlightReflector

## Health range. Unlike Plant, health is initialised inline here.
@export var maxHealth: int = 100
## Damage dealt per DamageTimer tick to each enemy in the light.
@export var damage = 5
@export var health: int  = 100
@export var minHealth: int = 0
## Map, used to read nightEnded and reach the HUD tooltip.
@onready var map: Map = $"../../"
@onready var point_light_2d: PointLight2D = $PointLight2D
## Repeating timer that drives the damage ticks (wait time set in the scene).
@onready var damage_timer: Timer = $DamageTimer
## Enemies currently standing in the light, kept in sync by the Area2D
## enter/exit callbacks below.
var enemies_in_attack_area: Array[Node2D] = []

## Decay is driven off the shared DayTime signal rather than a local timer.
func _ready():
	SignalBus.connect("DayTime", Callable(self, "Damage") )
	pass

## Called at every dawn: the reflector wears out and is freed once spent.
## Note this ignores minHealth and subtracts a hardcoded 20 rather than
## using the exported damage value.
func Damage():
	health -= 20
	if(health <= 0):
		queue_free()

## Player walked out of range; hide the tooltip.
func _on_vision_area_body_exited(_body: Node2D) -> void:
	map.hud.tooltip.visible = false
	pass

## Idle through the day (light off, timer stopped) and active at night.
## The timer is only started when something is actually in range.
func _process(_float) -> void:
	if(map.nightEnded == true and health > 0):
		point_light_2d.visible = false
		damage_timer.stop()
	else:
		point_light_2d.visible = true
		if enemies_in_attack_area.size() > 0 and damage_timer.is_stopped():
			damage_timer.start()


			
## One damage tick to everything currently in the light.
func _on_damage_timer_timeout() -> void:
	# NOTE: this list only ever contains aphids -- the enter callback filters
	# on the "Enemies" group, which Fly.tscn and Big_Bug.tscn are not in.
	for enemy in enemies_in_attack_area:
		if is_instance_valid(enemy):
			enemy.subtractDamage(damage)
	print("Timer has timed out")


## Track enemies entering the light. The group filter is what limits this
## to aphids.
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies") and !enemies_in_attack_area.has(body):
		enemies_in_attack_area.append(body)
		print(enemies_in_attack_area)


## Stop tracking an enemy that left the light.
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		enemies_in_attack_area.erase(body)
