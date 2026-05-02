extends Node3D

## The camp hub. Hosts the player + 3 NPC zones (blacksmith / adventurer /
## wizard) and toggles a HUD prompt + interact button when the player is in
## range of one. Tapping interact opens the matching screen.

const MISSION_SELECT_SCENE := preload("res://scenes/ui/mission_select.tscn")

@onready var _hud:           CanvasLayer = $HUD
@onready var _prompt_label:  Label       = $HUD/InteractPanel/PromptLabel
@onready var _interact_btn:  Button      = $HUD/InteractPanel/InteractButton
@onready var _interact_panel:Control     = $HUD/InteractPanel

var _active_npc: HubNpc = null
var _mission_select: Node = null

func _ready() -> void:
	_interact_panel.visible = false
	_interact_btn.pressed.connect(_on_interact_pressed)
	for npc in get_tree().get_nodes_in_group(&"hub_npc"):
		var n := npc as HubNpc
		n.player_entered.connect(_on_player_entered)
		n.player_exited.connect(_on_player_exited)
		n.interacted.connect(_on_npc_interacted)

func _input(event: InputEvent) -> void:
	if _active_npc != null and event.is_action_pressed(&"attack_melee"):
		_on_interact_pressed()

func _on_player_entered(_id: StringName, prompt: String) -> void:
	for npc in get_tree().get_nodes_in_group(&"hub_npc"):
		if (npc as HubNpc).is_player_inside():
			_active_npc = npc
			break
	_prompt_label.text = prompt
	_interact_panel.visible = true

func _on_player_exited(_id: StringName) -> void:
	_active_npc = null
	for npc in get_tree().get_nodes_in_group(&"hub_npc"):
		if (npc as HubNpc).is_player_inside():
			_active_npc = npc
			break
	_interact_panel.visible = _active_npc != null
	if _active_npc != null:
		_prompt_label.text = "%s — %s" % [_active_npc.display_name, _active_npc.prompt]

func _on_interact_pressed() -> void:
	if _active_npc != null:
		_active_npc.interact()

func _on_npc_interacted(npc_id: StringName) -> void:
	match npc_id:
		&"blacksmith":
			# Reuse inventory bag UI for salvaging items.
			var hud_inv := _hud.get_node_or_null("InventoryScreen")
			if hud_inv: hud_inv.show_screen()
			EventBus.ui_toast.emit("Bag full of junk? Tap an item to equip / auto-salvage.", 2.5)
		&"wizard":
			var hud_inv := _hud.get_node_or_null("InventoryScreen")
			if hud_inv: hud_inv.show_screen()
			EventBus.ui_toast.emit("Tap an equipped slot to spend enchant points.", 2.5)
		&"adventurer":
			_open_mission_select()

func _open_mission_select() -> void:
	if _mission_select != null and is_instance_valid(_mission_select):
		(_mission_select as Control).visible = true
		return
	_mission_select = MISSION_SELECT_SCENE.instantiate()
	_hud.add_child(_mission_select)
