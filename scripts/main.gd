extends Control

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	status_label.text = "Voxel Dungeon Crawler — Boot OK\nGodot %s | Platform: %s" % [
		Engine.get_version_info().get("string", "?"),
		OS.get_name(),
	]
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	EventBus.ui_toast.emit("Bootstrap scene loaded.", 2.0)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeons/test_level.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
