extends Control

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")

@onready var status_label:    Label  = $CenterContainer/VBoxContainer/StatusLabel
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var new_button:      Button = $CenterContainer/VBoxContainer/NewButton
@onready var test_button:     Button = $CenterContainer/VBoxContainer/TestButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button:     Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	status_label.text = "Voxel Dungeon Crawler — Boot OK\nGodot %s | Platform: %s" % [
		Engine.get_version_info().get("string", "?"),
		OS.get_name(),
	]
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_on_continue)
	new_button.pressed.connect(_on_new)
	test_button.pressed.connect(_on_test_arena)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	EventBus.ui_toast.emit("Bootstrap scene loaded.", 2.0)

func _on_continue() -> void:
	if not SaveManager.load_active_character():
		_on_new()
		return
	GameManager.return_to_hub()

func _on_new() -> void:
	SaveManager.start_fresh_character("Hero")
	GameManager.return_to_hub()

func _on_test_arena() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeons/test_level.tscn")

func _on_settings() -> void:
	var screen := SETTINGS_SCENE.instantiate() as Control
	screen.closed.connect(screen.queue_free)
	add_child(screen)

func _on_quit() -> void:
	SaveManager.save()
	get_tree().quit()
