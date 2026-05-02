class_name HubNpc
extends Area3D

## A camp NPC interaction zone. When the player overlaps, the hub shows an
## "INTERACT" prompt and routes the action to the matching screen.

signal interacted(npc_id: StringName)
signal player_entered(npc_id: StringName, prompt: String)
signal player_exited(npc_id: StringName)

@export var npc_id:       StringName = &""
@export var display_name: String     = "NPC"
@export var prompt:       String     = "Talk"

var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func is_player_inside() -> bool:
	return _player_inside

func interact() -> void:
	if _player_inside:
		interacted.emit(npc_id)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"): return
	_player_inside = true
	player_entered.emit(npc_id, "%s — %s" % [display_name, prompt])

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(&"player"): return
	_player_inside = false
	player_exited.emit(npc_id)
