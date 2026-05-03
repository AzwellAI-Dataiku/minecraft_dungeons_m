extends Node

enum State { BOOT, MAIN_MENU, HUB, DUNGEON, PAUSED, GAME_OVER }

const SCENE_MAIN_MENU := "res://scenes/main.tscn"
const SCENE_HUB       := "res://scenes/hub/hub.tscn"
const SCENE_DUNGEON   := "res://scenes/dungeons/dungeon.tscn"

var current_state:     State        = State.BOOT
var active_mission:    MissionData  = null
var active_mission_id: StringName   = &""
var active_difficulty: int          = 1
var run_seed:          int          = 0
var run_stats:         Dictionary   = _empty_stats()

func get_difficulty_pl_bonus() -> int:
	return DamageMath.difficulty_pl_bonus(active_difficulty)

func _ready() -> void:
	EventBus.scene_change_requested.connect(_on_scene_change_requested)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.player_xp_gained.connect(_on_xp_gained)
	EventBus.item_salvaged.connect(_on_item_salvaged)
	_change_state(State.MAIN_MENU)

# ── Mission control ───────────────────────────────────────────────────────────

func start_mission(mission_id: StringName, seed: int = 0) -> void:
	active_mission     = null
	active_mission_id  = mission_id
	run_seed           = seed if seed != 0 else int(Time.get_unix_time_from_system())
	run_stats          = _empty_stats()
	EventBus.mission_started.emit(mission_id)
	_change_scene(SCENE_DUNGEON, {})
	_change_state(State.DUNGEON)

func start_mission_data(mission: MissionData) -> void:
	if mission == null:
		return
	active_mission     = mission
	active_mission_id  = mission.id
	active_difficulty  = mission.difficulty
	run_seed           = int(Time.get_unix_time_from_system()) ^ mission.seed_offset
	run_stats          = _empty_stats()
	EventBus.mission_started.emit(mission.id)
	_change_scene(SCENE_DUNGEON, {})
	_change_state(State.DUNGEON)

func grant_mission_clear_rewards() -> void:
	if active_mission == null:
		return
	Inventory.emeralds += active_mission.emerald_reward
	PlayerProgression.add_xp(active_mission.xp_reward)
	run_stats["emeralds_gained"] = int(run_stats.get("emeralds_gained", 0)) + active_mission.emerald_reward
	run_stats["xp_gained"]       = int(run_stats.get("xp_gained", 0))       + active_mission.xp_reward

func return_to_hub() -> void:
	active_mission     = null
	active_mission_id  = &""
	get_tree().paused  = false
	SaveManager.save()
	_change_scene(SCENE_HUB, {})
	_change_state(State.HUB)

func go_to_main_menu() -> void:
	_change_scene(SCENE_MAIN_MENU, {})
	_change_state(State.MAIN_MENU)

func pause(paused: bool) -> void:
	get_tree().paused = paused
	_change_state(State.PAUSED if paused else State.DUNGEON)

# ── Run-stats listeners ───────────────────────────────────────────────────────

func _on_enemy_died(_enemy: Node, _killer: Node) -> void:
	if current_state == State.DUNGEON:
		run_stats["enemies_killed"] = int(run_stats.get("enemies_killed", 0)) + 1

func _on_item_picked_up(_item: Resource) -> void:
	if current_state == State.DUNGEON:
		run_stats["items_found"] = int(run_stats.get("items_found", 0)) + 1

func _on_xp_gained(amount: int, _xp: int, _xp_to_next: int) -> void:
	if current_state == State.DUNGEON:
		run_stats["xp_gained"] = int(run_stats.get("xp_gained", 0)) + amount

func _on_item_salvaged(_item: Resource, refund: int) -> void:
	if current_state == State.DUNGEON:
		run_stats["emeralds_gained"] = int(run_stats.get("emeralds_gained", 0)) + refund

# ── Internal ──────────────────────────────────────────────────────────────────

func _empty_stats() -> Dictionary:
	return {
		"enemies_killed":  0,
		"items_found":     0,
		"xp_gained":       0,
		"emeralds_gained": 0,
	}

func _change_state(new_state: State) -> void:
	current_state = new_state

func _change_scene(path: String, _payload: Dictionary) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Scene not found yet (stub): %s" % path)
		return
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to %s: %d" % [path, err])

func _on_scene_change_requested(scene_path: String, payload: Dictionary) -> void:
	_change_scene(scene_path, payload)
