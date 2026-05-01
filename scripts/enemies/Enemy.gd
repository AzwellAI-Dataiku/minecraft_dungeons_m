class_name Enemy
extends CharacterBody3D

@export var data: EnemyData

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVERING, HURT, DEAD }

@onready var _nav     : NavigationAgent3D = $NavigationAgent3D
@onready var _hurtbox : Hurtbox           = $Hurtbox
@onready var _pivot   : Node3D            = $Pivot

const GRAVITY       := 24.0
const HURT_DURATION := 0.28
const PATH_INTERVAL := 0.15

var hp           : float
var _state       := State.IDLE
var _state_timer := 0.0
var _player      : Node3D
var _path_timer  := 0.0
var _hitbox      : Hitbox   # melee/charge only — may be null

func _ready() -> void:
	hp = data.max_health if data else 20.0
	add_to_group(&"enemies")
	_hurtbox.took_damage.connect(_on_damage)
	_hitbox = get_node_or_null("Pivot/EnemyHitbox") as Hitbox
	await get_tree().process_frame
	var pl := get_tree().get_nodes_in_group(&"player")
	if not pl.is_empty():
		_player = pl[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_move(delta)
	move_and_slide()

func _process(delta: float) -> void:
	_state_timer = maxf(_state_timer - delta, 0.0)
	_path_timer  = maxf(_path_timer  - delta, 0.0)
	_fsm()
	_face(delta)

# ── Facing ────────────────────────────────────────────────────────────────────

func _face(delta: float) -> void:
	if _player == null or _state == State.DEAD:
		return
	var d := _player.global_position - global_position
	d.y = 0.0
	if d.length_squared() > 0.1:
		_pivot.rotation.y = lerp_angle(_pivot.rotation.y, atan2(d.x, d.z), 10.0 * delta)

# ── FSM ───────────────────────────────────────────────────────────────────────

func _fsm() -> void:
	if _player == null:
		return
	var dist   := global_position.distance_to(_player.global_position)
	var det    := data.detection_range      if data else 10.0
	var lose   := data.lose_interest_range  if data else 20.0
	var arange := data.attack_range         if data else 1.8

	match _state:
		State.IDLE:
			if dist < det:            _to(State.CHASE)
		State.CHASE:
			if   dist > lose:         _to(State.IDLE)
			elif dist <= arange:      _to(State.WINDUP)
		State.WINDUP:
			if _state_timer <= 0.0:   _to(State.ATTACK)
		State.ATTACK:
			if _state_timer <= 0.0:   _to(State.RECOVERING)
		State.RECOVERING:
			if _state_timer <= 0.0:
				_to(State.CHASE if dist <= lose else State.IDLE)
		State.HURT:
			if _state_timer <= 0.0:   _to(State.CHASE)

func _to(s: State) -> void:
	# ── exit ──
	if _state == State.HURT:     _hurtbox.invincible = false
	if _state == State.ATTACK and _hitbox: _hitbox.deactivate()
	# ── enter ──
	_state = s
	match s:
		State.WINDUP:
			_state_timer = data.windup_duration  if data else 0.38
		State.ATTACK:
			_state_timer = data.attack_duration  if data else 0.22
			_do_attack()
		State.RECOVERING:
			_state_timer = data.attack_cooldown  if data else 1.2
		State.HURT:
			_state_timer = HURT_DURATION
			_hurtbox.invincible = true
		State.DEAD:
			_hurtbox.invincible = true
			if _hitbox: _hitbox.deactivate()
			_die()

# ── Movement ──────────────────────────────────────────────────────────────────

func _move(delta: float) -> void:
	match _state:
		State.CHASE:
			_navigate(delta)
		State.ATTACK:
			if data and data.attack_type == EnemyData.AttackType.CHARGE:
				_charge(delta)
			else:
				_brake(delta)
		_:
			_brake(delta)

func _navigate(delta: float) -> void:
	if _player == null: return
	if _path_timer <= 0.0:
		var target := _player.global_position
		if data and data.attack_type == EnemyData.AttackType.RANGED:
			var to_pl := (_player.global_position - global_position).normalized()
			target = _player.global_position - to_pl * data.preferred_range
		_nav.target_position = target
		_path_timer = PATH_INTERVAL
	if _nav.is_navigation_finished():
		_brake(delta)
		return
	var dir := _nav.get_next_path_position() - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		var n   := dir.normalized()
		var spd := data.move_speed if data else 3.5
		velocity.x = move_toward(velocity.x, n.x * spd, 12.0 * delta)
		velocity.z = move_toward(velocity.z, n.z * spd, 12.0 * delta)
	else:
		_brake(delta)

func _charge(delta: float) -> void:
	if _player == null: return
	var dir := (_player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	var cs := data.charge_speed if data else 13.0
	velocity.x = lerp(velocity.x, dir.x * cs, 14.0 * delta)
	velocity.z = lerp(velocity.z, dir.z * cs, 14.0 * delta)
	if is_on_wall():
		_to(State.RECOVERING)

func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)

# ── Attack ────────────────────────────────────────────────────────────────────

func _do_attack() -> void:
	if data == null: return
	if data.attack_type == EnemyData.AttackType.RANGED:
		_shoot()
	elif _hitbox:
		var pkt := DamagePacket.make(data.attack_damage, self)
		pkt.knockback_dir   = _dir_to_player()
		pkt.knockback_force = data.knockback_force
		_hitbox.activate(pkt)

func _shoot() -> void:
	if _player == null or data == null or data.projectile_scene == null: return
	var proj := data.projectile_scene.instantiate() as Projectile
	if proj == null: return
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0.0, 1.0, 0.0)
	proj.direction       = _dir_to_player()
	proj.source          = self
	proj.damage          = data.attack_damage

func _dir_to_player() -> Vector3:
	if _player == null: return Vector3.FORWARD
	var d := _player.global_position - global_position
	d.y = 0.0
	return d.normalized()

# ── Damage / Death ────────────────────────────────────────────────────────────

func _on_damage(packet: DamagePacket) -> void:
	if _state == State.DEAD: return
	hp = maxf(hp - packet.amount, 0.0)
	EventBus.enemy_damaged.emit(self, packet.amount, packet.source)
	if hp <= 0.0:
		_to(State.DEAD)
		return
	velocity = packet.knockback_dir * packet.knockback_force * 4.0
	velocity.y = 1.5
	_to(State.HURT)

func _die() -> void:
	EventBus.enemy_died.emit(self, null)
	var tw := create_tween()
	tw.tween_property(_pivot, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
