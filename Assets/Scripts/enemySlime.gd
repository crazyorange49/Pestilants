## Base class for every enemy (the aphid via TestEnemy, Fly and BigBug).
##
## Owns the whole enemy loop: pick the most appealing plant on the map,
## navigate to it, and chew on it once in range. Subclasses add nothing but
## a retarget timer hook -- all the differences between enemy types come from
## the exported stats on their scenes.
##
## Targeting is scored rather than nearest-first: see calculatePriority,
## which weighs a plant's own enemyPriority against how close it is, with a
## small penalty for abandoning the current target.
class_name Enemy
extends CharacterBody2D

## Movement speed, lerped toward rather than applied directly.
@export var speed = 150
## Health bounds. NOTE: health itself is NOT initialised here -- each
## subclass assigns health = maxHealth in its own _ready().
@export var maxHealth = 50
## Damage per bite and the gap between bites.
@export var attack_damage = 5
## Unused; the real reach comes from the attack Area2D on the scene.
@export var attack_range = 30.0
@export var attack_cooldown = 1.0
## Floor for subtractDamage's clamp.
var minHealth = 0
## Unused leftover from when enemies chased the player.
var playerChase = false
## The plant currently being bitten -- set only by the attack-area callbacks,
## so it means "in range right now", unlike move_target.
var victim  = null
## Attack cooldown gate, cleared and re-set by attack().
var can_attack = true
## Never assigned anywhere; attack() checks it but nothing sets it true.
var is_dead = false
## The plant being navigated toward. May be far away, or already freed.
var move_target: Node2D = null
## Cleared once the enemy gives up on having anywhere to go, which stops
## move_to_target from being called again.
var moving = true
## Unused.
var targetsInRange: Array[Node2D]
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var detecion_area: Area2D = $detecionArea
## The Map. Path assumes the enemy sits at Map/enemyStorage/<enemy>.
@onready var map: Map = $"../../"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
## Repeating timer (0.5s) that makes subclasses re-run _findNewTarget, so
## enemies react to plants appearing and dying without polling every frame.
@onready var timer: Timer = $Timer

## priority variables

## Unused weight.
var w_priority = 0.5
## How much closeness contributes to a target's score.
var w_new = 0.25
## Distance falloff scale for closeness(). Small, so distance only matters
## between targets that are nearly on top of the enemy.
var scale_new = 8
## Penalty applied to any plant that is not the current target, to stop
## enemies flip-flopping between two similar plants.
var oldDistaceWeight: float = 0.01

## Health. Hitting zero frees the enemy and announces the death on the
## SignalBus, which is how Map decrements its counters and pays out seeds.
## NOTE: the setter does not clamp -- subtractDamage() is what clamps, so
## all damage should go through it rather than assigning health directly.
@export var health: int:
	set(subtractedHealth):
		health = subtractedHealth
		print(str(health))
		if health <= 0:
			queue_free()
			SignalBus.emit_signal("EnemyDeath")
	get:
		return health
		
		

## Starts the retarget timer. main_scene is fetched but unused.
func _ready():
	var main_scene = get_tree().get_current_scene() 
	timer.start()

	

## Bite whatever is in range, and keep walking while there is somewhere to
## go. Note victim and move_target are independent: an enemy can be biting
## one plant while still navigating toward another.
func _physics_process(delta):
	if victim:
		attack()
	if move_target and moving:
		move_to_target(delta)
	else:
		sprite.play("idle")
			
			
		
		
## Damage the current victim, then sit out the cooldown. Passes itself as the
## attacker so Rosebush can reflect thorn damage back.
func attack():
	if not can_attack or is_dead:
		return

	can_attack = false
	

	victim.subtractDamage(attack_damage, self)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
## Anything in the "Plant" group that touches the attack area becomes the
## victim -- including immature plants, which cannot fight back.
func _on_attack_area_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.is_in_group("Plant"):
		victim = body

## Victim moved out of reach; stop biting.
func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == victim:
		victim = null


## Steps along the navigation path toward move_target, turning the sprite to
## face the direction of travel. If the target has gone, stop and stay
## stopped by clearing `moving`.
func move_to_target(delta):
	if move_target == null:
		_findNewTarget()

	var direction = (navigation_agent_2d.get_next_path_position() - global_position)
	var distance = direction.length()

	if move_target:
		velocity = velocity.lerp(direction.normalized() * speed, delta)
		var new_transform = sprite.transform.looking_at(direction)
		sprite.transform = sprite.transform.interpolate_with(new_transform, delta)
		move_and_slide()
		# Only an idle animation exists so far; there is no walk cycle yet.
		sprite.play("idle") #change to walk later
	else:
		print(distance)
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.play("idle")
		moving = false

## Scores every mature plant on the map plus any defence object that counts
## as a plant, and returns the best. Falls back to the existing move_target,
## so an enemy keeps its current goal when nothing scores better.
func calculateTarget() -> Plant:
	# NOTE: this is Map's own array, not a copy, so the appends below grow the
	# shared list every time any enemy retargets.
	var availableTargets = map.availableTargets
	for defenceObject in map.defenceObjects:
		if !is_instance_valid(defenceObject):
			continue
		if defenceObject.is_in_group("Plant"):
			availableTargets.append(defenceObject)
	var newTarget: Node2D = move_target
	var bestScore := -INF
	for plant in availableTargets:
		# Immature plants are skipped, which is why enemies ignore freshly
		# planted seedlings until they have grown.
		if (!is_instance_valid(plant) or plant.growthProgress < 2 or !plant.is_in_group("Plant")):
			continue

		var score = calculatePriority(plant)

		if score > bestScore:
			bestScore = score
			newTarget = plant
	return newTarget

## Target score: the plant's own draw, plus a closeness bonus, minus a
## switching penalty. Higher is more appealing.
func calculatePriority(plant: Plant):
	var score = plant.enemyPriority
	score += closeness(position.distance_to(plant.position), scale_new) * w_new
	if plant != move_target:
		score -= oldDistaceWeight
	return score

## Exponential distance falloff, 1.0 at zero distance and approaching 0 as
## distance grows.
func closeness(dist: float, distScale: float) -> float:
	return exp(-dist / distScale)

## Re-picks a target and points the navigation agent at it. With nothing
## worth attacking, enemies head back toward their spawn point instead.
func _findNewTarget() -> void:
	move_target = calculateTarget()
	if is_instance_valid(move_target):
		navigation_agent_2d.target_position = move_target.position
	else:
		navigation_agent_2d.target_position = map.enemy_spawn.position

## The damage entry point used by plants, the Farm Bell, the Moonlight
## Reflector and the Decoy Sprout. Clamps into range, so reaching 0 here is
## what triggers the death path in the health setter.
func subtractDamage(damage: int) -> void:
	health = clamp(health - damage, 0, maxHealth)
