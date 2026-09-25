class_name StarterKitCard
extends Button

signal chosen(kit: StarterKit)

const SEED_ICON = preload("res://Assets/Sprites/UI/seed_icon.tres")

@export var rowSlotStyle: StyleBox
@export var rowTextColor: Color = Color(0.22745098, 0.14901961, 0.08627451, 1)
@export var chooseNormalStyle: StyleBox
@export var chooseHoverStyle: StyleBox

var kit: StarterKit

@onready var chooseTag: PanelContainer = %ChooseTag

func _ready() -> void:
	pressed.connect(func(): chosen.emit(kit))
	for changed in [mouse_entered, mouse_exited, focus_entered, focus_exited]:
		changed.connect(_refreshHighlight, CONNECT_DEFERRED)

func setup(_kit: StarterKit) -> void:
	kit = _kit
	%Icon.texture = kit.icon
	%KitName.text = kit.kitName
	%Description.text = kit.description
	%PerkLabel.text = kit.perk
	%PerkTag.visible = kit.perk != ""
	if kit.item != null and kit.itemCount > 0:
		_addRow(kit.item.icon, "x%d  %s" % [kit.itemCount, kit.itemLabel])
	elif kit.includesFarmBell:
		_addRow(kit.icon, kit.itemLabel)
	if kit.bonusSeeds > 0:
		_addRow(SEED_ICON, "+%d Renewal Seeds" % kit.bonusSeeds)

func _addRow(texture: Texture2D, text: String) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(40, 40)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("panel", rowSlotStyle)
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(image)
	row.add_child(slot)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", rowTextColor)
	label.add_theme_font_size_override("font_size", 19)
	row.add_child(label)
	%Contents.add_child(row)

func _refreshHighlight() -> void:
	chooseTag.add_theme_stylebox_override("panel", chooseHoverStyle if is_hovered() or has_focus() else chooseNormalStyle)
