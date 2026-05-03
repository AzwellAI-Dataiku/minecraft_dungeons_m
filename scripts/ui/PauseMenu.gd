extends Control

## In-game pause overlay.  Added as a child of the HUD CanvasLayer so it
## renders above all 3D content.  process_mode = ALWAYS so buttons work
## even while the scene tree is paused.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	_build_ui()

# ── Build ─────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color        = Color(0, 0, 0, 0.6)
	bg.mouse_filter = MOUSE_FILTER_STOP
	add_child(bg)

	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)

	var panel := PanelContainer.new()
	cc.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.add_theme_constant_override(&"separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text                    = "PAUSED"
	title.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 28)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_btn(vbox, "RESUME",          _on_resume)
	_btn(vbox, "SETTINGS",        _on_settings)
	_btn(vbox, "RETURN TO HUB",   _on_return_hub)
	_btn(vbox, "QUIT TO MENU",    _on_quit_menu)

func _btn(parent: Control, label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text                = label
	b.custom_minimum_size = Vector2(280, 56)
	b.pressed.connect(cb)
	parent.add_child(b)

# ── Public ────────────────────────────────────────────────────────────────────

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

# ── Handlers ──────────────────────────────────────────────────────────────────

func _on_resume() -> void:
	close()

func _on_settings() -> void:
	var screen := SETTINGS_SCENE.instantiate() as Control
	screen.closed.connect(screen.queue_free)
	add_child(screen)

func _on_return_hub() -> void:
	close()
	GameManager.return_to_hub()

func _on_quit_menu() -> void:
	close()
	GameManager.go_to_main_menu()
