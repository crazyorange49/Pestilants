## Script for the HUD's "Renewal Seeds:" label -- the player's currency readout.
##
## Polls the player every frame rather than listening for a change signal, so
## the label stays correct no matter who spends or awards seeds (the shop on
## purchase, Map on enemy death).
extends Label

## Player lives beside the HUD under the main scene root: Hud -> .. -> Player.
@onready var player: CharacterBody2D = $"../../Player"
## Self-reference; the script is attached to the Label it updates.
@onready var renewal_seeds: Label = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	renewal_seeds.text = "Renewal Seeds: " + str(player.getRenewalSeedCount())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	renewal_seeds.text = "Renewal Seeds: " + str(player.getRenewalSeedCount())
	pass
