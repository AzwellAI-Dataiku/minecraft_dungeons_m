extends Node3D

## Fixed-angle isometric camera rig.
## Sits at the player's XZ position; Camera3D child provides the actual view.

const FOLLOW_SPEED  := 8.0
const SNAP_DISTANCE := 25.0   # teleport if too far (scene load, respawn)

var _target: Node3D

func _ready() -> void:
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	_target = players[0]
	# snap immediately on first frame so there's no fly-in
	global_position = Vector3(_target.global_position.x, 0.0, _target.global_position.z)

func _process(delta: float) -> void:
	if _target == null:
		return
	var tp := Vector3(_target.global_position.x, 0.0, _target.global_position.z)
	if global_position.distance_to(tp) > SNAP_DISTANCE:
		global_position = tp
	else:
		global_position = global_position.lerp(tp, FOLLOW_SPEED * delta)
