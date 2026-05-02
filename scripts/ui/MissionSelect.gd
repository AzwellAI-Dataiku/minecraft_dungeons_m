extends Control

## Mission board panel. Lists every MissionData .tres in data/missions/
## and lets the player launch one. Closing the panel returns to the hub.

const MISSION_PATHS := [
	"res://data/missions/crypt_run.tres",
	"res://data/missions/desert_temple.tres",
	"res://data/missions/boss_castle.tres",
]

@onready var _close_btn:    Button        = $PanelOverlay/Panel/VBox/Header/CloseBtn
@onready var _list:         VBoxContainer = $PanelOverlay/Panel/VBox/MissionList
@onready var _player_pl:    Label         = $PanelOverlay/Panel/VBox/Header/PlayerPL

func _ready() -> void:
	_close_btn.pressed.connect(func(): visible = false)
	_player_pl.text = "Your PL: %d" % Inventory.get_power_level()
	_build_list()

func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	for path in MISSION_PATHS:
		var mission: MissionData = load(path) as MissionData
		if mission == null: continue
		_list.add_child(_build_row(mission))

func _build_row(mission: MissionData) -> Control:
	var panel := PanelContainer.new()
	var hb    := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 10)
	panel.add_child(hb)

	var diff := Label.new()
	diff.text = mission.get_difficulty_label()
	diff.modulate = mission.get_difficulty_color()
	diff.custom_minimum_size = Vector2(40, 0)
	diff.add_theme_font_size_override(&"font_size", 26)
	hb.add_child(diff)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info_box)

	var name_lbl := Label.new()
	name_lbl.text = mission.display_name
	name_lbl.add_theme_font_size_override(&"font_size", 18)
	info_box.add_child(name_lbl)

	var desc := Label.new()
	desc.text = mission.description
	desc.modulate = Color(0.85, 0.85, 0.85, 1)
	desc.add_theme_font_size_override(&"font_size", 12)
	info_box.add_child(desc)

	var pl := Label.new()
	pl.text = "Recommended PL %d" % mission.recommended_pl
	pl.modulate = Color(1.0, 0.85, 0.4, 1)
	pl.add_theme_font_size_override(&"font_size", 12)
	info_box.add_child(pl)

	var go := Button.new()
	go.text = "ENTER"
	go.custom_minimum_size = Vector2(90, 64)
	go.pressed.connect(func(): _start(mission))
	hb.add_child(go)

	return panel

func _start(mission: MissionData) -> void:
	visible = false
	GameManager.start_mission_data(mission)
