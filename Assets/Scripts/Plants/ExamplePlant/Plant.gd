class_name Plant
extends Node2D

@export var stats: item

var icon := stats.icon:
	set(icon):
		stats.icon = icon
	get:
		return icon
		
var maxStackSize:= stats.maxStackSize:
	set(maxSize):
		stats.maxStackSize = maxSize
	get:
		return maxStackSize
