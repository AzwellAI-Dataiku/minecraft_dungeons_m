extends Control

@onready var status_label:  Label  = $CenterContainer/VBoxContainer/StatusLabel
@onready var play_button:   Button = $CenterContainer/VBoxContainer/PlayButton
@onready var dungeon_button:Button = $CenterContainer/VBoxContainer/DungeonButton
@onready var quit_button:   Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	status_label.text = "Voxel Dungeon Crawler — Boot OK\nGodot %s | Platform: %s" % [
		Engine.get_version_info().get("string", "?"),
		OS.get_name(),
	]
	play_button.pressed.connect(_on_arena_pressed)
	dungeon_button.pressed.connect(_on_dungeon_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	EventBus.ui_toast.emit("Bootstrap scene loaded.", 2.0)

func _on_arena_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeons/test_level.tscn")

func _on_dungeon_pressed() -> void:
	GameManager.run_seed = int(Time.get_unix_time_from_system())
	get_tree().change_scene_to_file("res://scenes/dungeons/dungeon.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
