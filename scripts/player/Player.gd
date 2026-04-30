extends CharacterBody3D

const MOVE_SPEED   := 6.0
const ACCELERATION := 14.0
const FRICTION     := 22.0
const GRAVITY      := 24.0
const TURN_SPEED   := 16.0

@onready var pivot: Node3D = $Pivot

var _camera: Camera3D

func _ready() -> void:
	add_to_group(&"player")
	# wait one frame so the viewport camera is registered
	await get_tree().process_frame
	_camera = get_viewport().get_camera_3d()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input := InputManager.get_move_vector()
	var dir   := _world_dir_from_input(input)

	if dir.length_squared() > 0.001:
		velocity.x = move_toward(velocity.x, dir.x * MOVE_SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, dir.z * MOVE_SPEED, ACCELERATION * delta)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(dir.x, dir.z), TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

	move_and_slide()

# Project camera's flat forward/right axes onto the XZ plane, then combine with input.
func _world_dir_from_input(input: Vector2) -> Vector3:
	if input.length_squared() < 0.01 or _camera == null:
		return Vector3.ZERO
	var b       := _camera.global_transform.basis
	var forward := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var right   := Vector3( b.x.x, 0.0,  b.x.z).normalized()
	var world   := forward * (-input.y) + right * input.x
	return world.normalized() if world.length_squared() > 0.001 else Vector3.ZERO
