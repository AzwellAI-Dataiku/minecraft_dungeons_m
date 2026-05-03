extends Node

# ── Timings (seconds) ─────────────────────────────────────────────────────────
const MELEE_DAMAGE      := [12.0, 14.0, 22.0]
const MELEE_HIT_TIME    := [0.18, 0.18, 0.30]  # hitbox active window
const MELEE_RECOVER     := [0.22, 0.22, 0.42]  # lockout after swing
const MELEE_CHAIN_WIN   := 0.55                 # window to input next hit

const RANGED_DAMAGE     := 18.0
const RANGED_COOLDOWN   := 0.55

const ROLL_SPEED        := 12.0
const ROLL_DURATION     := 0.32
const ROLL_COOLDOWN     := 0.85
const IFRAMES_DURATION  := 0.28

@export var projectile_scene: PackedScene

# ── Runtime refs (resolved in _ready via get_parent) ─────────────────────────
var _player: CharacterBody3D
var _melee_hitbox: Hitbox
var _hurtbox: Hurtbox

# ── State ─────────────────────────────────────────────────────────────────────
enum State { IDLE, SWINGING, RECOVERING, CHAIN_WINDOW }
var _state         := State.IDLE
var _state_timer   := 0.0
var _combo_idx     := 0

var is_rolling         := false   # read by Player.gd
var _roll_dir          := Vector3.ZERO
var _roll_timer        := 0.0
var _roll_cooldown     := 0.0
var _ranged_cooldown   := 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_player      = get_parent() as CharacterBody3D
	_melee_hitbox = _player.get_node("Pivot/MeleeHitbox") as Hitbox
	_hurtbox      = _player.get_node("Hurtbox") as Hurtbox
	_melee_hitbox.hit_registered.connect(_on_melee_hit)
	InputManager.virtual_action_pressed.connect(_handle_action)

func _process(delta: float) -> void:
	_tick_timers(delta)
	_tick_combo_state(delta)

func _physics_process(delta: float) -> void:
	if is_rolling:
		_roll_timer -= delta
		_player.velocity.x = _roll_dir.x * ROLL_SPEED
		_player.velocity.z = _roll_dir.z * ROLL_SPEED
		if _roll_timer <= 0.0:
			_end_roll()

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"attack_melee"):  _handle_action(&"attack_melee")
	elif event.is_action_pressed(&"attack_ranged"): _handle_action(&"attack_ranged")
	elif event.is_action_pressed(&"roll"):        _handle_action(&"roll")

func _handle_action(action: StringName) -> void:
	match action:
		&"attack_melee":  _try_melee()
		&"attack_ranged": _try_ranged()
		&"roll":          _try_roll()

# ── Melee ─────────────────────────────────────────────────────────────────────
func _try_melee() -> void:
	if is_rolling:
		return
	if _state == State.IDLE or _state == State.CHAIN_WINDOW:
		_start_swing()

func _start_swing() -> void:
	if _state == State.CHAIN_WINDOW:
		_combo_idx = mini(_combo_idx + 1, 2)
	else:
		_combo_idx = 0
	InputManager.haptic_feedback(0.4, 18)
	var packet := DamagePacket.make(MELEE_DAMAGE[_combo_idx], _player)
	packet.knockback_dir   = _player.get_facing_direction()
	packet.knockback_force = 3.0
	packet.attacker_pl     = Inventory.get_power_level()
	EnchantmentDB.apply_outgoing_damage(packet)
	_melee_hitbox.activate(packet)
	_state       = State.SWINGING
	_state_timer = MELEE_HIT_TIME[_combo_idx]
	if EnchantmentDB.roll_extra_attack():
		_queue_echo_swing(MELEE_HIT_TIME[_combo_idx] + 0.05)

func _queue_echo_swing(delay: float) -> void:
	var t := get_tree().create_timer(delay)
	t.timeout.connect(func() -> void:
		if is_rolling: return
		if _state == State.IDLE or _state == State.CHAIN_WINDOW:
			_start_swing())

func _on_melee_hit(_h: Hurtbox, packet: DamagePacket) -> void:
	EnchantmentDB.on_damage_dealt(_player, packet)

func _tick_combo_state(_delta: float) -> void:
	if _state_timer <= 0.0:
		return
	match _state:
		State.SWINGING:
			if _state_timer <= 0.0:
				_melee_hitbox.deactivate()
				_state       = State.RECOVERING
				_state_timer = MELEE_RECOVER[_combo_idx]
		State.RECOVERING:
			if _state_timer <= 0.0:
				_state       = State.CHAIN_WINDOW
				_state_timer = MELEE_CHAIN_WIN
		State.CHAIN_WINDOW:
			if _state_timer <= 0.0:
				_reset_combo()

func _reset_combo() -> void:
	_combo_idx   = 0
	_state       = State.IDLE
	_state_timer = 0.0
	_melee_hitbox.deactivate()

# ── Ranged ─────────────────────────────────────────────────────────────────────
func _try_ranged() -> void:
	if is_rolling or _ranged_cooldown > 0.0 or projectile_scene == null:
		return
	_ranged_cooldown = RANGED_COOLDOWN
	_shoot()
	if EnchantmentDB.roll_extra_attack():
		var t := get_tree().create_timer(0.10)
		t.timeout.connect(_shoot)

func _shoot() -> void:
	var pkt := DamagePacket.make(RANGED_DAMAGE, _player)
	pkt.attacker_pl = Inventory.get_power_level()
	EnchantmentDB.apply_outgoing_damage(pkt)
	var proj := projectile_scene.instantiate() as Projectile
	_player.get_parent().add_child(proj)
	proj.global_position = _player.global_position + Vector3(0.0, 1.0, 0.0)
	proj.direction       = _player.get_facing_direction()
	proj.source          = _player
	proj.damage          = pkt.amount
	proj.is_crit         = pkt.is_crit

# ── Roll ──────────────────────────────────────────────────────────────────────
func _try_roll() -> void:
	if is_rolling or _roll_cooldown > 0.0:
		return
	var move := InputManager.get_move_vector()
	_roll_dir = _player.get_world_dir_from_input(move) if move.length_squared() > 0.01 \
	            else _player.get_facing_direction()
	is_rolling   = true
	_roll_timer  = ROLL_DURATION
	_roll_cooldown = ROLL_COOLDOWN
	_hurtbox.invincible = true
	InputManager.haptic_feedback(0.3, 15)
	# Cancel any active swing
	if _state == State.SWINGING:
		_melee_hitbox.deactivate()
		_reset_combo()

func _end_roll() -> void:
	is_rolling          = false
	_hurtbox.invincible = false

# ── Helpers ───────────────────────────────────────────────────────────────────
func _tick_timers(delta: float) -> void:
	_state_timer     = maxf(_state_timer - delta, 0.0)
	_roll_cooldown   = maxf(_roll_cooldown - delta, 0.0)
	_ranged_cooldown = maxf(_ranged_cooldown - delta, 0.0)
