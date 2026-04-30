extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var data: Dictionary = _default_data()

func _ready() -> void:
	EventBus.save_requested.connect(save)
	load_from_disk()

func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"characters": [],
		"active_character_index": 0,
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"graphics_quality": "med",
			"target_fps": 60,
			"haptics": true,
		},
	}

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		EventBus.save_failed.emit("cannot_open_for_write")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	EventBus.save_completed.emit()

func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _default_data()
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		data = _default_data()
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file corrupted, resetting.")
		data = _default_data()
		return false
	data = _migrate(parsed)
	return true

func _migrate(loaded: Dictionary) -> Dictionary:
	var v: int = int(loaded.get("version", 0))
	if v == SAVE_VERSION:
		return loaded
	# Future migrations between save versions go here.
	loaded["version"] = SAVE_VERSION
	return loaded

func get_setting(key: String, default_value: Variant = null) -> Variant:
	return data.get("settings", {}).get(key, default_value)

func set_setting(key: String, value: Variant) -> void:
	if not data.has("settings"):
		data["settings"] = {}
	data["settings"][key] = value
