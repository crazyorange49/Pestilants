class_name MiniMap
extends Control

## Minimap that follows the player over a baked image of the terrain.
##
## Terrain is baked once into a small ImageTexture (a few pixels per tile
## cell) and then drawn as a single textured rect, so showing real ground
## costs one draw call rather than thousands. Entities are plotted on top as
## blips straight from their node positions -- there is no second camera and
## no extra render pass.
##
## The bake reproduces the grassTiles.gdshader rule: pixels with red == 1.0
## are a mask that the shader swaps for the scrolling grass texture, so they
## are swapped here too. Everything else (the purple stone) keeps its colour.

@export_group("Wiring")
## Map node, relative to this control. Default assumes HUD/MiniMap next to Map.
@export var map_path: NodePath = ^"../../Map"
## Player node, relative to this control.
@export var player_path: NodePath = ^"../../Player"
## Optional input action that toggles the minimap. Ignored if unmapped.
@export var toggle_action: StringName = &""

@export_group("View")
## Scroll the view to keep the player centred. Off shows the whole world.
@export var follow_player: bool = true
## World pixels per minimap pixel when following. Higher shows more ground.
## The default keeps the purple frontier in view from the home base.
@export var world_per_pixel: float = 22.0
## Stop the view scrolling past the edge of the world.
@export var clamp_to_world: bool = true

@export_group("Terrain")
## Draw the baked terrain image under the blips.
@export var show_terrain: bool = true
## Baked image pixels per tile cell. 1 is one flat colour per tile.
@export_range(1, 8, 1) var terrain_resolution: int = 3
## Multiplied over the baked terrain, to mute it behind the blips.
@export var terrain_tint: Color = Color(0.82, 0.82, 0.82, 1.0)
## Used for the shader's red mask if the grass texture cannot be read.
@export var fallback_grass_color: Color = Color(0.51, 0.79, 0.31)

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
@export var blip_size: float = 4.0
@export var player_blip_size: float = 6.0
@export var landmark_blip_size: float = 6.0
## Draw an outline of what the player's camera currently sees.
@export var show_view_rect: bool = true

@export_group("Blip colors")
@export var player_color: Color = Color(1.0, 1.0, 1.0)
@export var enemy_color: Color = Color(1.0, 0.24, 0.22)
@export var plant_color: Color = Color(0.42, 0.98, 0.36)
@export var defense_color: Color = Color(0.38, 0.78, 1.0)
@export var house_color: Color = Color(1.0, 0.82, 0.28)
@export var shop_color: Color = Color(0.95, 0.60, 0.26)
@export var spawn_color: Color = Color(0.78, 0.18, 0.44)
@export var view_rect_color: Color = Color(1.0, 1.0, 1.0, 0.35)

var _map: Node2D
var _player: Node2D
var _scene_root: Node
var _world: Rect2 = Rect2()
# World-space area currently shown in the panel; recomputed every draw.
var _view: Rect2 = Rect2()
# Static markers resolved once: [{ "node": Node2D, "color": Color }]
var _landmarks: Array[Dictionary] = []

var _terrain_tex: ImageTexture
# World-space area the baked texture covers.
var _terrain_rect: Rect2 = Rect2()
var _baking: bool = false


func _ready() -> void:
	# Keep the baked terrain crisp instead of smearing it when magnified.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_map = get_node_or_null(map_path) as Node2D
	if _map == null:
		_map = _find_map()
	_player = get_node_or_null(player_path) as Node2D
	if _map != null:
		_scene_root = _map.get_parent()
		if _player == null:
			_player = _scene_root.get_node_or_null("Player") as Node2D
		_collect_landmarks()
		# The ground is repainted as nights are won and lost.
		if _map.has_signal("night_survived"):
			_map.night_survived.connect(_on_world_changed)
		if _map.has_signal("nightLost"):
			_map.nightLost.connect(_on_world_changed)
	refresh_bounds()
	resized.connect(queue_redraw)
	bake_terrain()


func _process(_delta: float) -> void:
	if toggle_action != &"" and InputMap.has_action(toggle_action) \
			and Input.is_action_just_pressed(toggle_action):
		visible = not visible
	if visible:
		queue_redraw()


func _on_world_changed() -> void:
	bake_terrain()


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


# --- World bounds ------------------------------------------------------------

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


# --- Terrain bake ------------------------------------------------------------

## Re-render the terrain image. Safe to call at any time; it waits a frame so
## TileMapDual has rebuilt its display layers first.
func bake_terrain() -> void:
	if not show_terrain or _map == null or _baking:
		return
	_baking = true
	# TileMapDual builds its display layers in _ready and refreshes them
	# deferred, so let those land before reading cells.
	await get_tree().process_frame
	await get_tree().process_frame
	_bake_terrain_now()
	_baking = false
	queue_redraw()


func _bake_terrain_now() -> void:
	var layers: Array[TileMapLayer] = []
	_collect_tile_layers(_map, layers)
	if layers.is_empty():
		return

	var cell := Vector2(layers[0].tile_set.tile_size)
	if cell.x <= 0.0 or cell.y <= 0.0:
		return

	var res: int = maxi(terrain_resolution, 1)
	var per_world := Vector2(res / cell.x, res / cell.y)
	_terrain_rect = _world
	var img_size := Vector2i(
		maxi(int(ceil(_terrain_rect.size.x * per_world.x)), 1),
		maxi(int(ceil(_terrain_rect.size.y * per_world.y)), 1))
	# Guard against a pathological world rect eating memory.
	if img_size.x > 4096 or img_size.y > 4096:
		push_warning("MiniMap: terrain bake skipped, %s is too large" % img_size)
		return

	var canvas := Image.create_empty(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))

	# Cached per distinct tile, since a map reuses a handful of tiles.
	var blocks: Dictionary = {}
	var source_images: Dictionary = {}

	for layer in layers:
		var tile_set := layer.tile_set
		if tile_set == null:
			continue
		var grass := _grass_color_for(layer)
		for coords in layer.get_used_cells():
			var source_id := layer.get_cell_source_id(coords)
			if source_id < 0:
				continue
			var atlas := layer.get_cell_atlas_coords(coords)
			var key := "%d:%d,%d" % [source_id, atlas.x, atlas.y]
			if not blocks.has(key):
				blocks[key] = _build_tile_block(
					tile_set, source_id, atlas, res, grass, source_images)
			var block: Image = blocks[key]
			if block == null:
				continue
			# map_to_local gives the cell centre, and display layers are
			# offset half a tile, so go through the layer transform.
			var centre := layer.to_global(layer.map_to_local(coords))
			var top_left := centre - cell * 0.5
			var dst := Vector2i(
				int(round((top_left.x - _terrain_rect.position.x) * per_world.x)),
				int(round((top_left.y - _terrain_rect.position.y) * per_world.y)))
			if dst.x <= -res or dst.y <= -res \
					or dst.x >= img_size.x or dst.y >= img_size.y:
				continue
			canvas.blend_rect(block, Rect2i(Vector2i.ZERO, Vector2i(res, res)), dst)

	_terrain_tex = ImageTexture.create_from_image(canvas)


## Gather the TileMapLayers that actually get rendered. A TileMapDual holds
## the grid the designer painted, while its DisplayLayer children hold the
## autotiled result that is really on screen, so prefer those.
func _collect_tile_layers(root: Node, out: Array[TileMapLayer]) -> void:
	for child in root.get_children():
		if child is DisplayLayer:
			out.append(child)
		elif child is TileMapDual:
			var before := out.size()
			_collect_tile_layers(child, out)
			if out.size() == before:
				out.append(child)  # Display not built yet; use the world grid.
		elif child is TileMapLayer:
			out.append(child)
		else:
			_collect_tile_layers(child, out)


## Average colour the shader's red mask resolves to, read from the layer's
## own overlay texture so the minimap matches whatever the ground looks like.
func _grass_color_for(layer: TileMapLayer) -> Color:
	var mat := layer.material
	if mat is ShaderMaterial:
		var tex = (mat as ShaderMaterial).get_shader_parameter("overlay_tex")
		if tex is Texture2D:
			var avg := _average_texture(tex as Texture2D)
			if avg.a > 0.0:
				return avg
	return fallback_grass_color


func _average_texture(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img == null:
		return Color(0, 0, 0, 0)
	img = img.duplicate()
	if img.is_compressed():
		if img.decompress() != OK:
			return Color(0, 0, 0, 0)
	img.convert(Image.FORMAT_RGBA8)
	# Downsample first; averaging every pixel of a large sheet is wasteful.
	img.resize(8, 8, Image.INTERPOLATE_BILINEAR)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var a := 0.0
	for y in 8:
		for x in 8:
			var px := img.get_pixel(x, y)
			r += px.r * px.a
			g += px.g * px.a
			b += px.b * px.a
			a += px.a
	if a <= 0.0:
		return Color(0, 0, 0, 0)
	return Color(r / a, g / a, b / a, a / 64.0)


func _build_tile_block(tile_set: TileSet, source_id: int, atlas: Vector2i,
		res: int, grass: Color, source_images: Dictionary) -> Image:
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null or source.texture == null:
		return null

	if not source_images.has(source_id):
		var src := source.texture.get_image()
		if src != null:
			src = src.duplicate()
			if src.is_compressed():
				if src.decompress() != OK:
					src = null
		if src != null:
			src.convert(Image.FORMAT_RGBA8)
		source_images[source_id] = src
	var src_img: Image = source_images[source_id]
	if src_img == null:
		return null

	var region := source.get_tile_texture_region(atlas)
	region = region.intersection(Rect2i(Vector2i.ZERO, src_img.get_size()))
	if region.size.x <= 0 or region.size.y <= 0:
		return null

	var block := Image.create_empty(res, res, false, Image.FORMAT_RGBA8)
	var bw := float(region.size.x) / float(res)
	var bh := float(region.size.y) / float(res)

	for by in res:
		for bx in res:
			var x0: int = region.position.x + int(floor(bx * bw))
			var y0: int = region.position.y + int(floor(by * bh))
			var x1: int = maxi(region.position.x + int(floor((bx + 1) * bw)), x0 + 1)
			var y1: int = maxi(region.position.y + int(floor((by + 1) * bh)), y0 + 1)
			x1 = mini(x1, region.end.x)
			y1 = mini(y1, region.end.y)

			var r := 0.0
			var g := 0.0
			var b := 0.0
			var a := 0.0
			var n := 0
			for y in range(y0, y1):
				for x in range(x0, x1):
					var px := src_img.get_pixel(x, y)
					# grassTiles.gdshader: floor(COLOR.r) selects the overlay,
					# so a fully red texel is really a grass mask.
					if px.r >= 0.999:
						px = Color(grass.r, grass.g, grass.b, px.a)
					r += px.r * px.a
					g += px.g * px.a
					b += px.b * px.a
					a += px.a
					n += 1
			if n == 0 or a <= 0.0:
				block.set_pixel(bx, by, Color(0, 0, 0, 0))
			else:
				block.set_pixel(bx, by, Color(r / a, g / a, b / a, a / float(n)))

	return block


# --- Projection --------------------------------------------------------------

func _update_view() -> void:
	if _world.size.x <= 0.0 or _world.size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		_view = Rect2(Vector2.ZERO, Vector2.ONE)
		return

	if follow_player and _player != null and is_instance_valid(_player):
		var view_size: Vector2 = size * maxf(world_per_pixel, 0.01)
		var centre := _player.global_position
		if clamp_to_world:
			centre = _clamp_centre(centre, view_size)
		_view = Rect2(centre - view_size * 0.5, view_size)
		return

	# Whole-world mode: letterbox the world into the panel so the terrain
	# keeps its aspect ratio instead of stretching.
	var panel_aspect: float = size.x / size.y
	var world_aspect: float = _world.size.x / _world.size.y
	var centre_w := _world.get_center()
	if world_aspect > panel_aspect:
		var h: float = _world.size.x / panel_aspect
		_view = Rect2(_world.position.x, centre_w.y - h * 0.5, _world.size.x, h)
	else:
		var w: float = _world.size.y * panel_aspect
		_view = Rect2(centre_w.x - w * 0.5, _world.position.y, w, _world.size.y)


func _clamp_centre(centre: Vector2, view_size: Vector2) -> Vector2:
	var world_centre := _world.get_center()
	if view_size.x < _world.size.x:
		centre.x = clampf(centre.x,
			_world.position.x + view_size.x * 0.5,
			_world.end.x - view_size.x * 0.5)
	else:
		centre.x = world_centre.x
	if view_size.y < _world.size.y:
		centre.y = clampf(centre.y,
			_world.position.y + view_size.y * 0.5,
			_world.end.y - view_size.y * 0.5)
	else:
		centre.y = world_centre.y
	return centre


func _project(world_pos: Vector2) -> Vector2:
	return (world_pos - _view.position) / _view.size * size


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, background_color)

	_update_view()

	if show_terrain and _terrain_tex != null \
			and _terrain_rect.size.x > 0.0 and _terrain_rect.size.y > 0.0:
		var tex_size := Vector2(_terrain_tex.get_size())
		var src := Rect2(
			(_view.position - _terrain_rect.position) / _terrain_rect.size * tex_size,
			_view.size / _terrain_rect.size * tex_size)
		draw_texture_rect_region(_terrain_tex, panel, src, terrain_tint)

	if _map != null:
		for landmark: Dictionary in _landmarks:
			var node: Node2D = landmark["node"]
			if is_instance_valid(node):
				_draw_blip(node.global_position, landmark["color"], landmark_blip_size)

		_draw_container(_map.get_node_or_null("plantStorage"), plant_color)
		_draw_container(_map.get_node_or_null("defenseStorage"), defense_color)
		_draw_loose_defenses()
		# Enemies last so they are never hidden under a plant blip, and pinned
		# to the edge when off-view so an incoming wave still reads.
		_draw_container(_map.get_node_or_null("enemyStorage"), enemy_color, true)

	if show_view_rect:
		_draw_view_rect()

	if _player != null and is_instance_valid(_player):
		_draw_blip(_player.global_position, player_color, player_blip_size)

	if border_width > 0.0:
		draw_rect(panel, border_color, false, border_width)


func _draw_container(container: Node, color: Color, pin_off_view: bool = false) -> void:
	if container == null:
		return
	for child in container.get_children():
		if child is Node2D:
			_draw_blip((child as Node2D).global_position, color, blip_size, pin_off_view)


func _draw_loose_defenses() -> void:
	# The starting Farmbell is a sibling of Map rather than a defenseStorage
	# child, so pick up any defence placed directly in the scene root too.
	if _scene_root == null:
		return
	for child in _scene_root.get_children():
		if child is Farmbell or child is MoonlightReflector:
			_draw_blip((child as Node2D).global_position, defense_color, blip_size)


## Draw one blip. Anything outside the view is dropped, unless pin_off_view is
## set, in which case it is pinned to the edge at reduced size as a direction
## hint rather than pretending to be an accurate position.
func _draw_blip(world_pos: Vector2, color: Color, blip: float,
		pin_off_view: bool = false) -> void:
	var p := _project(world_pos)
	var half := blip * 0.5
	var lo := border_width + half
	var hi := size - Vector2(border_width + half, border_width + half)
	var outside: bool = p.x < lo or p.y < lo or p.x > hi.x or p.y > hi.y

	if outside:
		if not pin_off_view:
			return
		blip = maxf(blip * 0.7, 2.0)
		half = blip * 0.5
		lo = border_width + half
		hi = size - Vector2(border_width + half, border_width + half)

	p.x = clampf(p.x, lo, hi.x)
	p.y = clampf(p.y, lo, hi.y)
	# Snapped to whole pixels and drawn as squares to match the pixel-art look.
	draw_rect(Rect2((p - Vector2(half, half)).round(), Vector2(blip, blip)), color)


func _draw_view_rect() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var view_size: Vector2 = get_viewport_rect().size / cam.zoom
	var top_left := cam.get_screen_center_position() - view_size * 0.5
	var r := Rect2(_project(top_left), view_size / _view.size * size)
	draw_rect(r, view_rect_color, false, 1.0)
