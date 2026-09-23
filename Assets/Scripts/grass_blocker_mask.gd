extends Node

@export var grass_layer_path: NodePath = ^"../GrassTiles"
@export var soil_layer_path: NodePath = ^"../SoilTiles"
@export var extra_blocker_names: PackedStringArray = ["ShopKeep", "Farmbell"]
@export var padding: float = 26.0
@export var cell_size: float = 8.0
@export var max_texture_size: int = 4096
@export var grass_terrain_id: int = 1

var mask_texture: ImageTexture
var infection_texture: ImageTexture
var _rebuild_queued := false

func _ready() -> void:
	var grass := get_node_or_null(grass_layer_path)
	if grass != null and grass.has_signal("changed"):
		grass.connect("changed", queue_rebuild)
	queue_rebuild()

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
	if grass is TileMapLayer:
		_build_infection_mask(grass as TileMapLayer, material)

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
	var start := used.position - Vector2i.ONE
	var width := used.size.x + 2
	var height := used.size.y + 2
	var image := Image.create(width, height, false, Image.FORMAT_L8)
	image.fill(Color.BLACK)
	for y in range(used.size.y):
		for x in range(used.size.x):
			var data := grass.get_cell_tile_data(used.position + Vector2i(x, y))
			if data != null and data.terrain != grass_terrain_id:
				image.set_pixel(x + 1, y + 1, Color.WHITE)
	infection_texture = ImageTexture.create_from_image(image)
	var tile := Vector2(grass.tile_set.tile_size) * grass.global_scale.abs()
	var origin := grass.to_global(grass.map_to_local(start)) - tile * 0.5
	material.set_shader_parameter("infection_mask", infection_texture)
	material.set_shader_parameter("infection_rect", Vector4(origin.x, origin.y, width * tile.x, height * tile.y))
	material.set_shader_parameter("use_infection_mask", true)

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
