extends Node3D

## The camp hub. Hosts the player + 3 NPC zones (blacksmith / adventurer /
## wizard) and toggles a HUD prompt + interact button when the player is in
## range of one. Tapping interact opens the matching screen.

const MISSION_SELECT_SCENE := preload("res://scenes/ui/mission_select.tscn")

@onready var _hud:            CanvasLayer = $HUD
@onready var _hub_interact:   CanvasLayer = $HubInteract
# Correct paths: InteractPanel lives under HubInteract, not HUD.
# Inside InteractPanel the children are grouped in an HBox.
@onready var _interact_panel: Control     = $HubInteract/InteractPanel
@onready var _prompt_label:   Label       = $HubInteract/InteractPanel/HBox/PromptLabel
@onready var _interact_btn:   Button      = $HubInteract/InteractPanel/HBox/InteractButton

var _active_npc:      HubNpc = null
var _mission_select:  Node   = null

func _ready() -> void:
	_interact_panel.visible = false

	_interact_btn.pressed.connect(_on_interact_pressed)

	# Touch-based interaction: tapping the on-screen attack_melee button
	# also triggers NPC interaction when in range.
	InputManager.virtual_action_pressed.connect(_on_virtual_action)

	for npc in get_tree().get_nodes_in_group(&"hub_npc"):
		var n := npc as HubNpc
		n.player_entered.connect(_on_player_entered)
		n.player_exited.connect(_on_player_exited)
		n.interacted.connect(_on_npc_interacted)

	# Deferred: force inventory/pause closed in case any startup signal,
	# ghost-tap or save-load side-effect opened them before _ready() ran.
	call_deferred("_force_hud_idle")

func _on_virtual_action(action: StringName) -> void:
	if action == &"attack_melee" and _active_npc != null:
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
			var inv := _hud.get_node_or_null("InventoryScreen")
			if inv: inv.show_screen()
			EventBus.ui_toast.emit("Tap an item to equip / salvage.", 2.5)
		&"wizard":
			var inv := _hud.get_node_or_null("InventoryScreen")
			if inv: inv.show_screen()
			EventBus.ui_toast.emit("Tap an equipped slot to spend enchant points.", 2.5)
		&"adventurer":
			_open_mission_select()

func _open_mission_select() -> void:
	if _mission_select != null and is_instance_valid(_mission_select):
		(_mission_select as Control).visible = true
		return
	_mission_select = MISSION_SELECT_SCENE.instantiate()
	_hud.add_child(_mission_select)

# ── Startup safeguard ─────────────────────────────────────────────────────────

func _force_hud_idle() -> void:
	# Run one frame after all _ready() calls so we override any modal state
	# that a ghost-tap or save-load side-effect may have triggered.
	var inv: Node = _hud.get_node_or_null("InventoryScreen")
	if inv is Control:
		(inv as Control).visible = false
	var pause: Node = _hud.get_node_or_null("PauseMenu")
	if pause is Control:
		(pause as Control).visible = false
	_interact_panel.visible = false
