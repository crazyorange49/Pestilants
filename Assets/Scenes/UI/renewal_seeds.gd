extends Label

@onready var player: CharacterBody2D = $"../../Player"
@onready var renewal_seeds: Label = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	renewal_seeds.text = "Renewal Seeds: " + str(player.getRenewalSeedCount())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	renewal_seeds.text = "Renewal Seeds: " + str(player.getRenewalSeedCount())
	pass
