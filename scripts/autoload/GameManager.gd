extends Node

enum State { BOOT, MAIN_MENU, HUB, DUNGEON, PAUSED, GAME_OVER }

const SCENE_MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const SCENE_HUB := "res://scenes/hub/hub.tscn"
const SCENE_DUNGEON := "res://scenes/dungeons/dungeon.tscn"

var current_state: State = State.BOOT
var active_mission_id: StringName = &""
var run_seed: int = 0

func _ready() -> void:
	EventBus.scene_change_requested.connect(_on_scene_change_requested)
	_change_state(State.MAIN_MENU)

func start_mission(mission_id: StringName, seed: int = 0) -> void:
	active_mission_id = mission_id
	run_seed = seed if seed != 0 else int(Time.get_unix_time_from_system())
	EventBus.mission_started.emit(mission_id)
	_change_scene(SCENE_DUNGEON, { "mission_id": mission_id, "seed": run_seed })
	_change_state(State.DUNGEON)

func return_to_hub() -> void:
	active_mission_id = &""
	_change_scene(SCENE_HUB, {})
	_change_state(State.HUB)

func go_to_main_menu() -> void:
	_change_scene(SCENE_MAIN_MENU, {})
	_change_state(State.MAIN_MENU)

func pause(paused: bool) -> void:
	get_tree().paused = paused
	_change_state(State.PAUSED if paused else State.DUNGEON)

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
