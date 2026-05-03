extends Node

## Tracks player level, XP, and unspent enchantment points across runs.
## XP is gained by killing enemies (subscribed via EventBus.enemy_died).

const XP_PER_LEVEL_BASE := 50  # lvl 1→2 = 50, 2→3 = 100, 3→4 = 150 …

var level:           int = 1
var xp:              int = 0
var enchant_points:  int = 0

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	_emit_changed()

# ── Public API ────────────────────────────────────────────────────────────────

func add_xp(amount: int) -> void:
	if amount <= 0: return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		_level_up()
	_emit_changed()
	EventBus.player_xp_gained.emit(amount, xp, xp_to_next())

func xp_to_next() -> int:
	return XP_PER_LEVEL_BASE * level

func spend_enchant_points(amount: int) -> bool:
	if amount > enchant_points: return false
	enchant_points -= amount
	_emit_changed()
	return true

func clear() -> void:
	level          = 1
	xp             = 0
	enchant_points = 0
	_emit_changed()

func serialize() -> Dictionary:
	return { "level": level, "xp": xp, "enchant_points": enchant_points }

func deserialize(dict: Dictionary) -> void:
	level          = int(dict.get("level", 1))
	xp             = int(dict.get("xp", 0))
	enchant_points = int(dict.get("enchant_points", 0))
	_emit_changed()

# ── Internal ──────────────────────────────────────────────────────────────────

func _level_up() -> void:
	level          += 1
	enchant_points += 1
	EventBus.ui_toast.emit("Level up! → %d  (+1 enchant pt)" % level, 2.5)

func _on_enemy_died(enemy: Node, _killer: Node) -> void:
	if enemy == null: return
	var data = enemy.get("data")
	if data == null: return
	add_xp(int(data.xp_reward))

func _emit_changed() -> void:
	EventBus.player_level_changed.emit(level, xp, xp_to_next())
