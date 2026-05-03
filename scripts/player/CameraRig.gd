extends Node3D

## Fixed-angle isometric camera rig.
## Sits at the player's XZ position; Camera3D child provides the actual view.

const FOLLOW_SPEED  := 8.0
const SNAP_DISTANCE := 25.0   # teleport if too far (scene load, respawn)
const SHAKE_DECAY   := 9.0
const _CAM_BASE_POS := Vector3(0.0, 18.0, 14.0)

var _target: Node3D
var _camera: Camera3D
var _shake: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	_camera = get_node_or_null("Camera3D") as Camera3D
	var players := get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	_target = players[0]
	global_position = Vector3(_target.global_position.x, 0.0, _target.global_position.z)
	EventBus.camera_shake.connect(_on_shake)

func _process(delta: float) -> void:
	if _target != null:
		var tp := Vector3(_target.global_position.x, 0.0, _target.global_position.z)
		if global_position.distance_to(tp) > SNAP_DISTANCE:
			global_position = tp
		else:
			global_position = global_position.lerp(tp, FOLLOW_SPEED * delta)

	if _camera == null:
		return
	if _shake > 0.01:
		_camera.position = _CAM_BASE_POS + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.4, 0.4),
			randf_range(-0.4, 0.4)
		) * _shake * 0.1
		_shake = move_toward(_shake, 0.0, SHAKE_DECAY * delta)
	else:
		_shake = 0.0
		_camera.position = _CAM_BASE_POS

func _on_shake(intensity: float) -> void:
	_shake = maxf(_shake, intensity)
