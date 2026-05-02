extends Control

## Full-screen settings overlay.  Built programmatically so it can be
## instantiated from any scene (main menu or pause menu).
## Call: var s = preload("res://scenes/ui/settings_screen.tscn").instantiate()
##       add_child(s)   # or parent.add_child(s)

signal closed

# Kept as member vars so _load_settings() can reach them after _build_ui().
var _sliders:      Dictionary = {}   # key(String) -> HSlider
var _vol_labels:   Dictionary = {}   # key(String) -> Label
var _quality_btns: Dictionary = {}   # quality(String) -> Button
var _fps_btns:     Dictionary = {}   # fps(int) -> Button
var _haptics_chk:  CheckButton = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_build_ui()
	_load_settings()

# ── Build ─────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color        = Color(0, 0, 0, 0.72)
	bg.mouse_filter = MOUSE_FILTER_STOP
	add_child(bg)

	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)

	var panel := PanelContainer.new()
	cc.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(520, 0)
	vbox.add_theme_constant_override(&"separation", 10)
	panel.add_child(vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override(&"font_size", 22)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "  X  "
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# ── Audio ─────────────────────────────────────────────────────────────────
	_section(vbox, "AUDIO")
	_slider_row(vbox, "master_volume", "Master", 1.0)
	_slider_row(vbox, "music_volume",  "Music",  0.8)
	_slider_row(vbox, "sfx_volume",    "SFX",    1.0)

	vbox.add_child(HSeparator.new())

	# ── Graphics ──────────────────────────────────────────────────────────────
	_section(vbox, "GRAPHICS")

	var q_row := HBoxContainer.new()
	q_row.add_theme_constant_override(&"separation", 6)
	vbox.add_child(q_row)
	var q_lbl := Label.new()
	q_lbl.text = "Quality"
	q_lbl.custom_minimum_size = Vector2(140, 0)
	q_row.add_child(q_lbl)
	for q: String in ["low", "med", "high"]:
		var btn := Button.new()
		btn.text = q.to_upper()
		btn.custom_minimum_size = Vector2(80, 36)
		btn.toggle_mode         = true
		btn.pressed.connect(_on_quality.bind(q))
		q_row.add_child(btn)
		_quality_btns[q] = btn

	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override(&"separation", 6)
	vbox.add_child(fps_row)
	var fps_lbl := Label.new()
	fps_lbl.text = "Target FPS"
	fps_lbl.custom_minimum_size = Vector2(140, 0)
	fps_row.add_child(fps_lbl)
	for fps: int in [30, 60]:
		var btn := Button.new()
		btn.text = "%d fps" % fps
		btn.custom_minimum_size = Vector2(80, 36)
		btn.toggle_mode         = true
		btn.pressed.connect(_on_fps.bind(fps))
		fps_row.add_child(btn)
		_fps_btns[fps] = btn

	vbox.add_child(HSeparator.new())

	# ── Haptics (Android only) ────────────────────────────────────────────────
	var hap_row := HBoxContainer.new()
	vbox.add_child(hap_row)
	var hap_lbl := Label.new()
	hap_lbl.text                  = "Haptic Feedback"
	hap_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	hap_row.add_child(hap_lbl)
	_haptics_chk = CheckButton.new()
	hap_row.add_child(_haptics_chk)
	_haptics_chk.toggled.connect(_on_haptics)
	if OS.get_name() != "Android":
		hap_row.visible = false

# ── Helpers ───────────────────────────────────────────────────────────────────

func _section(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.modulate = Color(0.7, 0.85, 1.0, 1)
	lbl.add_theme_font_size_override(&"font_size", 15)
	parent.add_child(lbl)

func _slider_row(parent: Control, key: String, label_text: String, default_val: float) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 8)
	parent.add_child(hb)

	var lbl := Label.new()
	lbl.text                  = label_text
	lbl.custom_minimum_size   = Vector2(140, 0)
	hb.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value              = 0.0
	slider.max_value              = 1.0
	slider.step                   = 0.05
	slider.value                  = default_val
	slider.size_flags_horizontal  = SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_volume.bind(key))
	hb.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text                = "%d%%" % int(default_val * 100)
	val_lbl.custom_minimum_size = Vector2(48, 0)
	hb.add_child(val_lbl)

	_sliders[key]    = slider
	_vol_labels[key] = val_lbl

# ── Load from SaveManager ─────────────────────────────────────────────────────

func _load_settings() -> void:
	for key: String in _sliders:
		var v := float(SaveManager.get_setting(key, 1.0))
		_sliders[key].value     = v
		_vol_labels[key].text   = "%d%%" % int(v * 100)
	_highlight_quality(str(SaveManager.get_setting("graphics_quality", "med")))
	_highlight_fps(int(SaveManager.get_setting("target_fps", 60)))
	if _haptics_chk != null:
		_haptics_chk.button_pressed = bool(SaveManager.get_setting("haptics", true))

func _highlight_quality(active: String) -> void:
	for q: String in _quality_btns:
		(_quality_btns[q] as Button).button_pressed = (q == active)

func _highlight_fps(active_fps: int) -> void:
	for fps: int in _fps_btns:
		(_fps_btns[fps] as Button).button_pressed = (fps == active_fps)

# ── Handlers ──────────────────────────────────────────────────────────────────

func _on_volume(value: float, key: String) -> void:
	if _vol_labels.has(key):
		_vol_labels[key].text = "%d%%" % int(value * 100)
	SaveManager.set_setting(key, value)
	match key:
		"master_volume": AudioManager._set_bus_volume(AudioManager.BUS_MASTER, value)
		"music_volume":  AudioManager._set_bus_volume(AudioManager.BUS_MUSIC,  value)
		"sfx_volume":    AudioManager._set_bus_volume(AudioManager.BUS_SFX,    value)

func _on_quality(quality: String) -> void:
	_highlight_quality(quality)
	GraphicsManager.apply_quality(quality)

func _on_fps(fps: int) -> void:
	_highlight_fps(fps)
	GraphicsManager.set_target_fps(fps)

func _on_haptics(on: bool) -> void:
	SaveManager.set_setting("haptics", on)

func _on_close() -> void:
	SaveManager.save()
	closed.emit()
	queue_free()
