extends Control

## Modal panel for inspecting and upgrading an item's enchantments.
## Shown when the player taps an item in InventoryScreen.

@onready var _close_btn:    Button       = $PanelOverlay/Panel/VBox/Header/CloseBtn
@onready var _title_label:  Label        = $PanelOverlay/Panel/VBox/Header/TitleLabel
@onready var _stats_label:  Label        = $PanelOverlay/Panel/VBox/StatsLabel
@onready var _points_label: Label        = $PanelOverlay/Panel/VBox/PointsLabel
@onready var _slots_box:    VBoxContainer = $PanelOverlay/Panel/VBox/SlotsBox

var _item: ItemData = null

func _ready() -> void:
	_close_btn.pressed.connect(func(): visible = false)
	EventBus.enchantment_chosen.connect(_on_enchantment_changed)
	visible = false

func show_for(item: ItemData) -> void:
	_item = item
	visible = true
	_refresh()

func _refresh() -> void:
	if _item == null:
		visible = false
		return
	_title_label.text  = "%s  (%s, PL %d)" % [_item.display_name, _item.get_rarity_label(), _item.power_level]
	_title_label.modulate = _item.get_rarity_color()
	var stat := ""
	if _item.base_damage  > 0.0: stat += "DMG %s   "  % str(_item.base_damage)
	if _item.base_defense > 0.0: stat += "DEF %d%%   " % int(_item.base_defense * 100.0)
	if _item.cooldown     > 0.0: stat += "CD %ss   "  % str(_item.cooldown)
	_stats_label.text  = stat.strip_edges()
	_points_label.text = "Enchant points: %d" % PlayerProgression.enchant_points

	for child in _slots_box.get_children():
		child.queue_free()

	if _item.slots.is_empty():
		var none := Label.new()
		none.text = "(no enchantment slots)"
		_slots_box.add_child(none)
		return

	for i in _item.slots.size():
		_slots_box.add_child(_build_slot_row(i))

func _build_slot_row(slot_idx: int) -> Control:
	var slot := _item.slots[slot_idx] as EnchantmentSlot
	var row := PanelContainer.new()
	var hb  := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 8)
	row.add_child(hb)
	# header label
	var label := Label.new()
	label.text = "Slot %d" % (slot_idx + 1)
	label.custom_minimum_size = Vector2(60, 0)
	hb.add_child(label)

	if slot.is_active():
		var ench := slot.get_chosen()
		var info := Label.new()
		info.text = "%s  L%d (%.2f)" % [ench.display_name, slot.level, slot.get_value()]
		info.modulate = ench.color
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info)
		var max_lvl := ench.max_level()
		if slot.level < max_lvl:
			var cost := slot.cost_to_next_level()
			var btn := Button.new()
			btn.text = "L%d  (%d pt)" % [slot.level + 1, cost]
			btn.disabled = PlayerProgression.enchant_points < cost
			btn.pressed.connect(func(): EnchantmentDB.upgrade_slot(_item, slot_idx))
			hb.add_child(btn)
		else:
			var maxed := Label.new()
			maxed.text = "MAX"
			hb.add_child(maxed)
	else:
		# Show 3 candidate buttons
		for ci in slot.candidates.size():
			var ench := slot.candidates[ci]
			var btn := Button.new()
			btn.text = ench.display_name + "\n+%.2f" % ench.value_at(1)
			btn.modulate = ench.color
			btn.tooltip_text = ench.description
			btn.disabled = PlayerProgression.enchant_points < 1
			btn.custom_minimum_size = Vector2(150, 56)
			var idx := ci
			btn.pressed.connect(func(): EnchantmentDB.choose_candidate(_item, slot_idx, idx))
			hb.add_child(btn)
	return row

func _on_enchantment_changed(_a = null, _b = null) -> void:
	if visible:
		_refresh()
