extends Node

@export var grass_layer_path: NodePath = ^"../GrassTiles"
@export var soil_layer_path: NodePath = ^"../SoilTiles"
@export var extra_blocker_names: PackedStringArray = ["ShopKeep", "Farmbell"]
@export var padding: float = 26.0
@export var cell_size: float = 8.0
@export var max_texture_size: int = 4096
@export var grass_terrain_id: int = 1
@export_group("Dead infection")
@export_range(0.0, 1.0, 0.01) var dead_patch_chance: float = 0.06
@export var dead_patch_min_radius: float = 16.0
@export var dead_patch_max_radius: float = 28.0
@export var dead_patch_seed: int = 1337

signal dead_patches_changed

var mask_texture: ImageTexture
var infection_texture: ImageTexture
var dead_patches: Dictionary = {}
var _infected_cells: Dictionary = {}
var _has_baseline := false
var _rebuild_queued := false
var _grass_layer: TileMapLayer
var _blocker_rects: Array[Rect2] = []

func _ready() -> void:
	var grass := get_node_or_null(grass_layer_path)
	if grass != null and grass.has_signal("changed"):
		grass.connect("changed", queue_rebuild)
	var map := get_parent()
	var scene_root := map.get_parent() if map != null else null
	for source in [scene_root, map]:
		if source == null:
			continue
		for signal_name in ["nightWon", "nightLost"]:
			if source.has_signal(signal_name) and not source.is_connected(signal_name, queue_rebuild):
				source.connect(signal_name, queue_rebuild)
	queue_rebuild()

func dead_patch_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if _grass_layer == null or not is_instance_valid(_grass_layer) or _grass_layer.tile_set == null:
		return list
	var tile := Vector2(_grass_layer.tile_set.tile_size) * _grass_layer.global_scale.abs()
	for cell: Vector2i in dead_patches:
		var patch: Dictionary = dead_patches[cell]
		var corner := _grass_layer.to_global(_grass_layer.map_to_local(cell)) - tile * 0.5
		list.append({"position": corner + patch["offset"] * tile, "radius": patch["radius"]})
	return list

func queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	_run_queued_rebuild.call_deferred()

func _run_queued_rebuild() -> void:
	_rebuild_queued = false
	rebuild()

func rebuild() -> void:
	var grass := get_node_or_null(grass_layer_path)
	if grass == null:
		return
	var material := _grass_material(grass)
	if material == null:
		return

	var rects: Array[Rect2] = []
	_collect_soil(rects)
	var map := get_parent()
	if map != null:
		_collect_visuals(map, rects)
		var scene_root := map.get_parent()
		if scene_root != null:
			for blocker_name in extra_blocker_names:
				var extra := scene_root.get_node_or_null(NodePath(blocker_name))
				if extra != null:
					_collect_visuals(extra, rects)
	_blocker_rects = rects

	if grass is TileMapLayer:
		_build_infection_mask(grass as TileMapLayer, material)

	if rects.is_empty():
		material.set_shader_parameter("use_mask", false)
		return

	var bounds := rects[0].grow(padding)
	for r in rects:
		bounds = bounds.merge(r.grow(padding))

	var cell := cell_size
	while bounds.size.x / cell > max_texture_size or bounds.size.y / cell > max_texture_size:
		cell *= 2.0
	var width := int(ceil(bounds.size.x / cell))
	var height := int(ceil(bounds.size.y / cell))
	var image := Image.create(width, height, false, Image.FORMAT_L8)
	image.fill(Color.BLACK)
	for r in rects:
		var grown := r.grow(padding)
		var from := ((grown.position - bounds.position) / cell).floor()
		var to := ((grown.end - bounds.position) / cell).ceil()
		var area := Rect2i(Vector2i(from), Vector2i(to - from)).intersection(Rect2i(0, 0, width, height))
		if area.size.x > 0 and area.size.y > 0:
			image.fill_rect(area, Color.WHITE)

	mask_texture = ImageTexture.create_from_image(image)
	material.set_shader_parameter("blocker_mask", mask_texture)
	material.set_shader_parameter("mask_rect", Vector4(bounds.position.x, bounds.position.y, width * cell, height * cell))
	material.set_shader_parameter("use_mask", true)

func _build_infection_mask(grass: TileMapLayer, material: ShaderMaterial) -> void:
	if grass.tile_set == null:
		return
	var used := grass.get_used_rect()
	if used.size.x == 0 or used.size.y == 0:
		return
	_grass_layer = grass
	var tile := Vector2(grass.tile_set.tile_size) * grass.global_scale.abs()
	var infected_now: Dictionary = {}
	for y in range(used.size.y):
		for x in range(used.size.x):
			var coords := used.position + Vector2i(x, y)
			var data := grass.get_cell_tile_data(coords)
			if data != null and data.terrain != grass_terrain_id:
				infected_now[coords] = true
	var patches_changed := _update_dead_patches(grass, infected_now, tile)
	_infected_cells = infected_now
	_has_baseline = true

	var start := used.position - Vector2i.ONE
	var width := used.size.x + 2
	var height := used.size.y + 2
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for coords: Vector2i in infected_now:
		image.set_pixelv(coords - start, Color(1, 0, 0, 0))
	for coords: Vector2i in dead_patches:
		var pixel := coords - start
		if pixel.x < 0 or pixel.y < 0 or pixel.x >= width or pixel.y >= height:
			continue
		var patch: Dictionary = dead_patches[coords]
		var offset: Vector2 = patch["offset"]
		image.set_pixelv(pixel, Color(0, clampf(patch["radius"] / 32.0, 0.0, 1.0), offset.x, offset.y))
	infection_texture = ImageTexture.create_from_image(image)
	var origin := grass.to_global(grass.map_to_local(start)) - tile * 0.5
	if patches_changed:
		dead_patches_changed.emit()
	material.set_shader_parameter("infection_mask", infection_texture)
	material.set_shader_parameter("infection_rect", Vector4(origin.x, origin.y, width * tile.x, height * tile.y))
	material.set_shader_parameter("use_infection_mask", true)

func _update_dead_patches(grass: TileMapLayer, infected_now: Dictionary, tile: Vector2) -> bool:
	var changed := false
	for coords: Vector2i in dead_patches.keys():
		if infected_now.has(coords):
			dead_patches.erase(coords)
			changed = true
	if not _has_baseline:
		return changed
	var rng := RandomNumberGenerator.new()
	for coords: Vector2i in _infected_cells:
		if infected_now.has(coords) or dead_patches.has(coords):
			continue
		rng.seed = hash(Vector3i(coords.x, coords.y, dead_patch_seed))
		if rng.randf() >= dead_patch_chance:
			continue
		var radius := rng.randf_range(dead_patch_min_radius, dead_patch_max_radius)
		var margin := clampf(6.0 / tile.x, 0.0, 0.5)
		var offset := Vector2(rng.randf_range(margin, 1.0 - margin), rng.randf_range(margin, 1.0 - margin))
		var corner := grass.to_global(grass.map_to_local(coords)) - tile * 0.5
		var footprint := Rect2(corner + offset * tile - Vector2(radius, radius) * 1.7, Vector2(radius, radius) * 3.4)
		if _overlaps_blocker(footprint):
			continue
		dead_patches[coords] = {"offset": offset, "radius": radius}
		changed = true
	return changed

func _overlaps_blocker(area: Rect2) -> bool:
	for r in _blocker_rects:
		if r.grow(padding).intersects(area):
			return true
	return false

func _grass_material(grass: Node) -> ShaderMaterial:
	var candidate = grass.get("display_material")
	if candidate is ShaderMaterial:
		return candidate
	if grass is CanvasItem and (grass as CanvasItem).material is ShaderMaterial:
		return (grass as CanvasItem).material
	return null

func _collect_soil(rects: Array[Rect2]) -> void:
	var soil := get_node_or_null(soil_layer_path) as TileMapLayer
	if soil == null or soil.tile_set == null:
		return
	var tile := Vector2(soil.tile_set.tile_size) * soil.global_scale.abs()
	for coords in soil.get_used_cells():
		var centre := soil.to_global(soil.map_to_local(coords))
		rects.append(Rect2(centre - tile * 0.5, tile))

func _collect_visuals(node: Node, rects: Array[Rect2]) -> void:
	if node is CanvasLayer or node is TileMapLayer:
		return
	if node is Sprite2D and (node as Sprite2D).texture != null:
		var sprite := node as Sprite2D
		rects.append(sprite.global_transform * sprite.get_rect())
	elif node is TextureRect and (node as TextureRect).texture != null:
		rects.append((node as TextureRect).get_global_rect())
	for child in node.get_children():
		_collect_visuals(child, rects)
