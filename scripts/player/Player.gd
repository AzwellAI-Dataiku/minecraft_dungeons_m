extends CharacterBody3D

const MOVE_SPEED   := 6.0
const ACCELERATION := 14.0
const FRICTION     := 22.0
const GRAVITY      := 24.0
const TURN_SPEED   := 16.0

@export var max_health: float = 100.0

@onready var pivot: Node3D = $Pivot

var health : float
var _camera: Camera3D
var _combat: Node   # PlayerCombat — optional, resolved after ready

func _ready() -> void:
	add_to_group(&"player")
	health = max_health
	await get_tree().process_frame
	_camera = get_viewport().get_camera_3d()
	_combat = get_node_or_null("PlayerCombat")
	$Hurtbox.took_damage.connect(_on_damage)
	EventBus.player_spawned.emit(self)
	EventBus.player_health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var rolling := _combat != null and _combat.is_rolling
	if not rolling:
		_apply_movement(delta)
	move_and_slide()

func _apply_movement(delta: float) -> void:
	var dir := get_world_dir_from_input(InputManager.get_move_vector())
	var speed := MOVE_SPEED * EnchantmentDB.get_move_speed_multiplier()
	if dir.length_squared() > 0.001:
		velocity.x = move_toward(velocity.x, dir.x * speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, ACCELERATION * delta)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(dir.x, dir.z), TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

func _on_damage(packet: DamagePacket) -> void:
	EnchantmentDB.apply_incoming_damage(packet)
	health = maxf(health - packet.amount, 0.0)
	EventBus.player_health_changed.emit(health, max_health)
	InputManager.haptic_feedback(0.7, 40)
	if health <= 0.0:
		EventBus.player_died.emit(self)

func heal(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0: return
	health = minf(health + amount, max_health)
	EventBus.player_health_changed.emit(health, max_health)

# ── Public helpers ────────────────────────────────────────────────────────────

func get_facing_direction() -> Vector3:
	return -pivot.global_transform.basis.z.normalized()

func get_world_dir_from_input(input: Vector2) -> Vector3:
	if input.length_squared() < 0.01 or _camera == null:
		return Vector3.ZERO
	var b       := _camera.global_transform.basis
	var forward := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var right   := Vector3( b.x.x, 0.0,  b.x.z).normalized()
	var world   := forward * (-input.y) + right * input.x
	return world.normalized() if world.length_squared() > 0.001 else Vector3.ZERO
