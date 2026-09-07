class_name MiniMap
extends Control

## Whole-world minimap drawn from entity positions.
##
## The world here is roughly 13000x3500px and enemies walk in from ~11500px
## west of the house, so this draws the entire map at once rather than a
## window that follows the player -- the useful question is "how close is the
## wave", which a follow-cam minimap cannot answer.
##
## Nothing is rendered through a second camera: blips are plotted straight
## from node positions, so this costs no extra draw pass.

@export_group("Wiring")
## Map node, relative to this control. Default assumes HUD/MiniMap next to Map.
@export var map_path: NodePath = ^"../../Map"
## Player node, relative to this control.
@export var player_path: NodePath = ^"../../Player"
## Optional input action that toggles the minimap. Ignored if unmapped.
@export var toggle_action: StringName = &""

@export_group("World bounds")
## Derive the mapped area from the WorldBorder planes, falling back to the
## painted TileMapLayers. Turn off to use manual_bounds verbatim.
@export var auto_bounds: bool = true
## Used when auto_bounds is off, or when nothing can be derived.
@export var manual_bounds: Rect2 = Rect2(-10113, -1504, 12961, 3565)
## Extra world-space padding around the derived bounds, in pixels.
@export var bounds_padding: float = 128.0

@export_group("Appearance")
@export var background_color: Color = Color(0.06, 0.08, 0.06, 0.72)
@export var border_color: Color = Color(0.85, 0.80, 0.62, 0.9)
@export var border_width: float = 2.0
@export var blip_size: float = 3.0
@export var player_blip_size: float = 5.0
@export var landmark_blip_size: float = 5.0
## Draw an outline of what the player's camera currently sees.
@export var show_view_rect: bool = true

@export_group("Blip colors")
@export var player_color: Color = Color(1.0, 1.0, 1.0)
@export var enemy_color: Color = Color(0.93, 0.25, 0.24)
@export var plant_color: Color = Color(0.42, 0.86, 0.36)
@export var defense_color: Color = Color(0.38, 0.75, 1.0)
@export var house_color: Color = Color(0.98, 0.79, 0.28)
@export var shop_color: Color = Color(0.79, 0.51, 0.24)
@export var spawn_color: Color = Color(0.62, 0.16, 0.35)
@export var view_rect_color: Color = Color(1.0, 1.0, 1.0, 0.35)

var _map: Node2D
var _player: Node2D
var _scene_root: Node
var _world: Rect2 = Rect2()
var _view_scale: float = 1.0
var _view_origin: Vector2 = Vector2.ZERO
# Static markers resolved once: [{ "node": Node2D, "color": Color }]
var _landmarks: Array[Dictionary] = []


func _ready() -> void:
	_map = get_node_or_null(map_path) as Node2D
	if _map == null:
		_map = _find_map()
	_player = get_node_or_null(player_path) as Node2D
	if _map != null:
		_scene_root = _map.get_parent()
		if _player == null:
			_player = _scene_root.get_node_or_null("Player") as Node2D
		_collect_landmarks()
	refresh_bounds()
	resized.connect(queue_redraw)


func _process(_delta: float) -> void:
	if toggle_action != &"" and InputMap.has_action(toggle_action) \
			and Input.is_action_just_pressed(toggle_action):
		visible = not visible
	if visible:
		queue_redraw()


## Recompute the mapped area. Call this if the world is resized at runtime.
func refresh_bounds() -> void:
	_world = _compute_world_bounds()
	queue_redraw()


func _find_map() -> Node2D:
	# Fall back to a tree scan so the HUD still works if it is reparented.
	var root := get_tree().current_scene
	if root == null:
		return null
	for child in root.get_children():
		if child is Map:
			return child
	return null


func _collect_landmarks() -> void:
	_landmarks.clear()
	_add_landmark(_map.get_node_or_null("StaticBody2D/HouseSprite"), house_color)
	_add_landmark(_map.get_node_or_null("ShopSprite"), shop_color)
	_add_landmark(_map.get_node_or_null("EnemySpawn"), spawn_color)


func _add_landmark(node: Node, color: Color) -> void:
	if node is Node2D:
		_landmarks.append({"node": node, "color": color})


func _compute_world_bounds() -> Rect2:
	if not auto_bounds or _map == null:
		return manual_bounds

	# The WorldBorder planes are the honest answer: grass is painted well
	# beyond the playable area, so TileMapLayer.get_used_rect() overshoots by
	# roughly 2x and squashes the whole lane into the middle of the panel.
	var bounds := _bounds_from_world_border()
	var found := bounds.size.x > 0.0 and bounds.size.y > 0.0

	if not found:
		for child in _map.get_children():
			if child is not TileMapLayer:
				continue
			var layer := child as TileMapLayer
			var used := layer.get_used_rect()
			if used.size.x == 0 or used.size.y == 0:
				continue
			# map_to_local returns cell centers; padding covers the half-cell.
			var a := layer.to_global(layer.map_to_local(used.position))
			var b := layer.to_global(layer.map_to_local(used.end))
			var r := Rect2(a, b - a).abs()
			bounds = r if not found else bounds.merge(r)
			found = true

	# Keep the spawn point and the buildings on the map even if they sit
	# slightly outside the derived area.
	for landmark: Dictionary in _landmarks:
		var node: Node2D = landmark["node"]
		if not is_instance_valid(node):
			continue
		var r := Rect2(node.global_position, Vector2.ZERO)
		bounds = r if not found else bounds.merge(r)
		found = true

	if not found:
		return manual_bounds

	return bounds.grow(bounds_padding)


## Rebuild the playable rect from the four WorldBoundaryShape2D planes.
## Returns an empty Rect2 if the world is not closed on all four sides.
func _bounds_from_world_border() -> Rect2:
	var body := _map.get_node_or_null("WorldBorder")
	if body == null:
		return Rect2()

	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF

	for child in body.get_children():
		if child is not CollisionShape2D:
			continue
		var col := child as CollisionShape2D
		if col.shape is not WorldBoundaryShape2D:
			continue
		var plane := col.shape as WorldBoundaryShape2D
		var normal := plane.normal
		# The plane sits at distance along its normal from the node origin;
		# the normal points into the playable side.
		var point := col.global_position + normal * plane.distance
		if normal.x > 0.5:
			min_x = minf(min_x, point.x)
		elif normal.x < -0.5:
			max_x = maxf(max_x, point.x)
		elif normal.y > 0.5:
			min_y = minf(min_y, point.y)
		elif normal.y < -0.5:
			max_y = maxf(max_y, point.y)

	if is_inf(min_x) or is_inf(max_x) or is_inf(min_y) or is_inf(max_y):
		return Rect2()
	if max_x <= min_x or max_y <= min_y:
		return Rect2()
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _update_projection() -> void:
	if _world.size.x <= 0.0 or _world.size.y <= 0.0:
		_view_scale = 1.0
		_view_origin = Vector2.ZERO
		return
	var inner: Vector2 = size - Vector2(border_width, border_width) * 2.0
	_view_scale = minf(inner.x / _world.size.x, inner.y / _world.size.y)
	_view_origin = (size - _world.size * _view_scale) * 0.5


func _project(world_pos: Vector2) -> Vector2:
	return (world_pos - _world.position) * _view_scale + _view_origin


func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, background_color)

	_update_projection()

	if _map != null:
		for landmark: Dictionary in _landmarks:
			var node: Node2D = landmark["node"]
			if is_instance_valid(node):
				_draw_blip(node.global_position, landmark["color"], landmark_blip_size)

		_draw_container(_map.get_node_or_null("plantStorage"), plant_color)
		_draw_container(_map.get_node_or_null("defenseStorage"), defense_color)
		_draw_loose_defenses()
		# Enemies last so they are never hidden under a plant blip.
		_draw_container(_map.get_node_or_null("enemyStorage"), enemy_color)

	if show_view_rect:
		_draw_view_rect()

	if _player != null and is_instance_valid(_player):
		_draw_blip(_player.global_position, player_color, player_blip_size)

	if border_width > 0.0:
		draw_rect(panel, border_color, false, border_width)


func _draw_container(container: Node, color: Color) -> void:
	if container == null:
		return
	for child in container.get_children():
		if child is Node2D:
			_draw_blip((child as Node2D).global_position, color, blip_size)


func _draw_loose_defenses() -> void:
	# The starting Farmbell is a sibling of Map rather than a defenseStorage
	# child, so pick up any defence placed directly in the scene root too.
	if _scene_root == null:
		return
	for child in _scene_root.get_children():
		if child is Farmbell or child is MoonlightReflector:
			_draw_blip((child as Node2D).global_position, defense_color, blip_size)


func _draw_blip(world_pos: Vector2, color: Color, blip: float) -> void:
	var p := _project(world_pos)
	# Clamp so anything beyond the mapped area pins to the edge instead of
	# silently disappearing.
	var half := blip * 0.5
	p.x = clampf(p.x, border_width + half, size.x - border_width - half)
	p.y = clampf(p.y, border_width + half, size.y - border_width - half)
	# Snapped to whole pixels and drawn as squares to match the pixel-art look.
	draw_rect(Rect2((p - Vector2(half, half)).round(), Vector2(blip, blip)), color)


func _draw_view_rect() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var view_size: Vector2 = get_viewport_rect().size / cam.zoom
	var top_left := cam.get_screen_center_position() - view_size * 0.5
	var r := Rect2(_project(top_left), view_size * _view_scale)
	draw_rect(r, view_rect_color, false, 1.0)
