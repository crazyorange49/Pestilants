extends Control

@export var text := "Pestilants"
@export var font: Font
@export var font_size := 100
@export var letter_spacing := 2.0
@export var pest_letters := 4
@export var pest_colors: Array[Color] = [Color(0.66, 0.4, 0.95), Color(0.5, 0.3, 0.86)]
@export var plant_colors: Array[Color] = [Color(0.55, 0.88, 0.25), Color(0.36, 0.74, 0.2)]
@export var outline_color := Color(0.12, 0.07, 0.16)
@export var outline_size := 24
@export var shadow_color := Color(0.05, 0.02, 0.08, 0.55)
@export var shadow_offset := Vector2(4, 8)
@export var eye_color := Color(0.95, 0.12, 0.14)
@export var leaf_color := Color(0.4, 0.8, 0.22)

var _time := 0.0
var _jump: PackedFloat32Array
var _jump_velocity: PackedFloat32Array
var _hovered := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font == null:
		font = get_theme_default_font()
	_jump.resize(text.length())
	_jump_velocity.resize(text.length())
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_time = 0.0

func _process(delta: float) -> void:
	_time += delta
	for i in text.length():
		_jump_velocity[i] += (-420.0 * _jump[i] - 13.0 * _jump_velocity[i]) * delta
		_jump[i] += _jump_velocity[i] * delta
	var hovered := _letter_at(get_local_mouse_position())
	if hovered != _hovered and hovered != -1:
		_jump_velocity[hovered] -= 700.0
	_hovered = hovered
	queue_redraw()

func _letter_widths() -> PackedFloat32Array:
	var widths := PackedFloat32Array()
	for ch in text:
		widths.append(font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widths

func _letter_centers(widths: PackedFloat32Array) -> PackedVector2Array:
	var total := 0.0
	for w in widths:
		total += w
	total += letter_spacing * (widths.size() - 1)
	var x := (size.x - total) * 0.5
	var centers := PackedVector2Array()
	for w in widths:
		centers.append(Vector2(x + w * 0.5, size.y * 0.5))
		x += w + letter_spacing
	return centers

func _letter_at(point: Vector2) -> int:
	if font == null:
		return -1
	var widths := _letter_widths()
	var centers := _letter_centers(widths)
	var half_height := font.get_height(font_size) * 0.4
	for i in centers.size():
		if absf(point.x - centers[i].x) <= widths[i] * 0.5 + letter_spacing * 0.5 \
				and absf(point.y - centers[i].y) <= half_height:
			return i
	return -1

func _bounce_out(t: float) -> float:
	if t < 1.0 / 2.75:
		return 7.5625 * t * t
	elif t < 2.0 / 2.75:
		t -= 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elif t < 2.5 / 2.75:
		t -= 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	t -= 2.625 / 2.75
	return 7.5625 * t * t + 0.984375

func _letter_color(index: int) -> Color:
	var palette := pest_colors if index < pest_letters else plant_colors
	return palette[index % palette.size()]

func _draw() -> void:
	if font == null or text.is_empty():
		return
	var widths := _letter_widths()
	var centers := _letter_centers(widths)
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var cap_height := ascent * 0.72

	for pass_index in 2:
		for i in text.length():
			var delay := i * 0.07
			var p := clampf((_time - delay) / 0.75, 0.0, 1.0)
			if p <= 0.0:
				continue
			var drop := (1.0 - _bounce_out(p)) * -260.0
			var bob := sin(_time * 2.4 + i * 0.6) * 5.0 * p
			var tilt := (0.07 if i % 2 == 0 else -0.07) + sin(_time * 1.8 + i * 0.9) * 0.05
			tilt += _jump[i] * 0.004 * (1.0 if i % 2 == 0 else -1.0)
			var stretch := 1.0 + clampf(-_jump[i] * 0.004, -0.15, 0.2)
			var scale_v := Vector2(1.0 / sqrt(stretch), stretch)
			var pos := centers[i] + Vector2(0, drop + bob + _jump[i])
			var ch := text[i]
			var w := widths[i]
			var origin := Vector2(-w * 0.5, (ascent - descent) * 0.5 - ascent * 0.08)

			if pass_index == 0:
				draw_set_transform(pos + shadow_offset, tilt, scale_v)
				draw_string_outline(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, shadow_color)
				draw_string(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
				continue

			var color := _letter_color(i)
			draw_set_transform(pos, tilt, scale_v)
			if i == 0:
				_draw_antennae(origin, w, cap_height, color)
			if ch == "l":
				_draw_leaf(origin, w, ascent)
			draw_string_outline(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
			draw_string_outline(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, color.darkened(0.35))
			draw_string(font, origin + Vector2(0, -4), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color.lightened(0.45))
			draw_string(font, origin, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_set_transform(Vector2.ZERO)

func _draw_antennae(origin: Vector2, w: float, cap_height: float, color: Color) -> void:
	var base := Vector2(origin.x + w * 0.32, origin.y - cap_height + 4)
	var sway := sin(_time * 3.2) * 4.0
	for side in [-1.0, 1.0]:
		var points := PackedVector2Array()
		for step in 9:
			var t := step / 8.0
			var x: float = base.x + side * (7.0 + 22.0 * t) + sway * t
			var y: float = base.y - 46.0 * t + 14.0 * t * t
			points.append(Vector2(x, y))
		draw_polyline(points, outline_color, 11.0, true)
		draw_polyline(points, color.darkened(0.2), 5.0, true)
		var tip := points[points.size() - 1]
		draw_circle(tip, 11.0, outline_color)
		draw_circle(tip, 7.5, eye_color)
		draw_circle(tip + Vector2(-2.5, -2.5), 2.5, Color(1, 0.85, 0.85))

func _draw_leaf(origin: Vector2, w: float, ascent: float) -> void:
	var stem := Vector2(origin.x + w * 0.5, origin.y - ascent * 0.8)
	var sway := sin(_time * 2.6 + 1.0) * 0.18
	var leaf := PackedVector2Array()
	var length := 40.0
	for step in 13:
		var t := step / 12.0
		leaf.append(Vector2(t * length, -sin(t * PI) * 11.0))
	for step in range(11, 0, -1):
		var t := step / 12.0
		leaf.append(Vector2(t * length, sin(t * PI) * 6.0))
	var rotated := PackedVector2Array()
	var angle := -0.75 + sway
	for point in leaf:
		rotated.append(stem + point.rotated(angle))
	var outline := rotated.duplicate()
	outline.append(rotated[0])
	draw_colored_polygon(rotated, leaf_color)
	draw_polyline(outline, outline_color, 5.0, true)
	draw_line(stem, stem + Vector2(length * 0.8, 0).rotated(angle), leaf_color.darkened(0.3), 2.0, true)
