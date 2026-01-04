class_name Plant
extends Node2D

@export var stats: Resource = preload("uid://csr8dxvj1ns2l")
@export var health: int
@export var atkDamage: int
@export var atkCoolDownInSeconds: float
@export var visionRadius: float
@export var movementSpeed: float

func _init(p_health: int = 0, p_atkDamage: int = 0, p_atkCoolDownInSeconds: float = 0.0, p_visionRadius: float = 0.0, p_movementSpeed: float = 0.0) -> void:
	health = p_health
	atkDamage = p_atkDamage
	atkCoolDownInSeconds  = p_atkCoolDownInSeconds
	visionRadius  = p_visionRadius
	movementSpeed  = p_movementSpeed

var icon : Texture = stats.icon:
	set(icon):
		stats.icon = icon
	get:
		return icon
		
var maxStackSize: int = stats.maxStackSize:
	set(maxSize):
		stats.maxStackSize = maxSize
	get:
		return maxStackSize
		
var itemName: StringName = stats.itemName:
	set(name):
		stats.itemName = name
	get:
		return itemName
