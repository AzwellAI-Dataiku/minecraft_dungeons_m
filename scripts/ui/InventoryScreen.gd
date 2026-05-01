extends Control

@onready var _close_btn:     Button        = $PanelOverlay/Panel/VBox/Header/CloseBtn
@onready var _power_label:   Label         = $PanelOverlay/Panel/VBox/Header/PowerLabel
@onready var _emerald_label: Label         = $PanelOverlay/Panel/VBox/EmeraldLabel
@onready var _bag_label:     Label         = $PanelOverlay/Panel/VBox/BagLabel
@onready var _slots_row:     HBoxContainer = $PanelOverlay/Panel/VBox/SlotsRow
@onready var _bag_grid:      GridContainer = $PanelOverlay/Panel/VBox/BagGrid

var _slot_buttons: Dictionary = {}

func _ready() -> void:
	_close_btn.pressed.connect(func(): visible = false)
	_build_slot_buttons()
	_refresh()
	EventBus.item_picked_up.connect(_on_inventory_changed)
	EventBus.item_equipped.connect(_on_inventory_changed)
	EventBus.item_salvaged.connect(_on_inventory_changed)
	visible = false

func show_screen() -> void:
	_refresh()
	visible = true

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"toggle_inventory"):
		visible = false
		accept_event()

func _build_slot_buttons() -> void:
	var labels := {
		"melee": "MELEE", "ranged": "RANGED", "armor": "ARMOR",
		"artifact_1": "ART 1", "artifact_2": "ART 2", "artifact_3": "ART 3"
	}
	for slot in ["melee", "ranged", "armor", "artifact_1", "artifact_2", "artifact_3"]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(88, 72)
		btn.text = labels[slot] + "\n—"
		var s := slot
		btn.pressed.connect(func(): _on_slot_pressed(s))
		_slots_row.add_child(btn)
		_slot_buttons[slot] = btn

func _refresh() -> void:
	for slot in _slot_buttons.keys():
		var btn := _slot_buttons[slot] as Button
		var it  := Inventory.get_equipped(slot)
		if it != null:
			btn.text     = it.display_name + "\nPL%d" % it.power_level
			btn.modulate = it.get_rarity_color()
		else:
			btn.text     = slot.replace("_", " ").to_upper() + "\n—"
			btn.modulate = Color(0.55, 0.55, 0.55)

	for child in _bag_grid.get_children():
		child.queue_free()
	for i in Inventory.bag.size():
		var it  := Inventory.bag[i] as ItemData
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(88, 72)
		btn.text     = it.display_name + "\nPL%d" % it.power_level
		btn.modulate = it.get_rarity_color()
		var idx := i
		btn.pressed.connect(func(): _on_bag_pressed(idx))
		_bag_grid.add_child(btn)

	_emerald_label.text = "✦  %d Emeralds" % Inventory.emeralds
	_power_label.text   = "PL %d" % Inventory.get_power_level()
	_bag_label.text     = "BAG  (%d / %d)" % [Inventory.bag.size(), Inventory.BAG_MAX]

func _on_slot_pressed(_slot: String) -> void:
	pass  # M6: show enchantments / unequip flow

func _on_bag_pressed(idx: int) -> void:
	if idx >= Inventory.bag.size(): return
	var it := Inventory.bag[idx] as ItemData
	Inventory.equip_from_bag(idx, Inventory.get_slot_for_item(it))

func _on_inventory_changed(_a = null, _b = null) -> void:
	if visible:
		_refresh()
