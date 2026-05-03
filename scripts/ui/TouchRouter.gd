extends Control

## Centralised on-screen touch handling.
##
## Why a router instead of per-button _input(): in Godot 4.3 the input
## delivery to per-Control _input() callbacks under a CanvasLayer has been
## flaky on Android with multi-touch (the second finger never reaches a
## sibling Button's _input). A single full-screen Control with a single
## _input() override receives EVERY InputEventScreenTouch / Drag /
## InputEventMouseButton reliably, then dispatches by hit-rect.
##
## The router:
##   • Hit-tests touches against named action zones
##   • Drives the on-screen joystick (left half) via InputManager.set_virtual_move
##   • Pushes/releases virtual actions on InputManager (right-side buttons)
##   • Updates the joystick base/knob visuals each touch
##   • Modulates the action button visuals on press for tactile feedback
##
## All zone rectangles are read once at _ready() from the corresponding
## Button nodes' rects, so the layout stays in one place (the .tscn) and
## the router just re-reads on viewport resize.

const DEAD_ZONE := 0.18
const KNOB_RADIUS := 110.0
const PRESSED_ALPHA := 0.55
const NORMAL_ALPHA  := 1.0
const DEBUG_PRINT   := false  # flip to true for adb-logcat trace

# Buttons that act as action sources. Resolved at runtime.
var _zones: Dictionary = {}                 # action_name (StringName) -> Control
# Per-finger state: index -> { mode: "joystick"|"action", action: StringName }
var _fingers: Dictionary = {}
# Joystick visual nodes (resolved on _ready).
var _joy_root:   Control = null
var _joy_base:   Control = null
var _joy_knob:   Control = null
var _joy_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	# We use _input(); make sure mouse_filter doesn't accidentally swallow
	# events for siblings (top-bar buttons must keep working).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Belt + braces: ensure both input phases are on. Godot auto-enables
	# them when the script overrides _input/_unhandled_input but if the
	# script is hot-reloaded or the node was instantiated by code that
	# disabled them, this is the explicit fix.
	set_process_input(true)
	set_process_unhandled_input(true)
	# Resolve once after the HUD subtree is ready.
	call_deferred("_resolve_nodes")

func _unhandled_input(event: InputEvent) -> void:
	# Mirror of _input — second-finger touch events on Android sometimes
	# arrive only via the unhandled phase if any GUI control consumed the
	# first phase. Calling _input here is idempotent because the router is
	# the single source of truth for finger-state.
	_input(event)

func _resolve_nodes() -> void:
	var hud := get_parent()
	if hud == null:
		return
	_zones.clear()
	for action in [&"attack_melee", &"attack_ranged", &"roll",
	               &"artifact_1", &"artifact_2", &"artifact_3"]:
		var n := hud.find_child(_button_name_for(action), true, false) as Control
		if n != null:
			_zones[action] = n
	_joy_root = hud.find_child("VirtualJoystick", true, false) as Control
	if _joy_root != null:
		_joy_base = _joy_root.find_child("Base", true, false) as Control
		if _joy_base != null:
			_joy_knob = _joy_base.find_child("Knob", true, false) as Control
			_joy_center = _joy_base.global_position + _joy_base.size * 0.5
		else:
			_joy_center = Vector2.ZERO
		_reset_knob()
	if DEBUG_PRINT:
		print("[TouchRouter] resolved zones=", _zones.keys(), " joy=", _joy_root)

static func _button_name_for(action: StringName) -> String:
	match action:
		&"attack_melee":  return "BtnMelee"
		&"attack_ranged": return "BtnRanged"
		&"roll":          return "BtnRoll"
		&"artifact_1":    return "BtnArtifact1"
		&"artifact_2":    return "BtnArtifact2"
		&"artifact_3":    return "BtnArtifact3"
	return ""

# ── Input dispatch ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _modal_visible():
		# An overlay (inventory, pause, summary) is open — release any
		# in-flight virtual actions so the player doesn't keep walking
		# while the modal is up, and stop processing.
		_release_all()
		return
	if event is InputEventScreenTouch:
		_on_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_on_drag(event.index, event.position)
	elif event is InputEventMouseButton:
		# Mouse path covers desktop debugging AND first-finger touch
		# (because emulate_mouse_from_touch is on). We only act if the
		# touch path didn't already claim this finger 0 — checking via
		# index 0 in _fingers is enough.
		if event.button_index == MOUSE_BUTTON_LEFT and not _fingers.has(0):
			_on_touch(0, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _fingers.has(0):
			_on_drag(0, event.position)

func _on_touch(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _fingers.has(index):
			return
		var action := _zone_at(pos)
		if action != &"":
			_fingers[index] = {"mode": "action", "action": action}
			InputManager.press_virtual_action(action)
			InputManager.haptic_feedback(0.4, 18)
			_set_btn_alpha(action, PRESSED_ALPHA)
			if DEBUG_PRINT: print("[TouchRouter] press idx=", index, " action=", action, " pos=", pos)
		elif _is_left_zone(pos):
			_fingers[index] = {"mode": "joystick"}
			_reposition_base(pos)
			_move_knob(pos)
			if DEBUG_PRINT: print("[TouchRouter] joystick begin idx=", index, " pos=", pos)
	else:
		if not _fingers.has(index):
			return
		var f: Dictionary = _fingers[index]
		match str(f.get("mode", "")):
			"action":
				var a: StringName = f.get("action", &"")
				if a != &"":
					InputManager.release_virtual_action(a)
					_set_btn_alpha(a, NORMAL_ALPHA)
				if DEBUG_PRINT: print("[TouchRouter] release idx=", index, " action=", a)
			"joystick":
				InputManager.set_virtual_move(Vector2.ZERO)
				_reset_knob()
				if DEBUG_PRINT: print("[TouchRouter] joystick end idx=", index)
		_fingers.erase(index)

func _on_drag(index: int, pos: Vector2) -> void:
	if not _fingers.has(index):
		return
	var f: Dictionary = _fingers[index]
	if str(f.get("mode", "")) == "joystick":
		_move_knob(pos)

# ── Hit-testing ───────────────────────────────────────────────────────────────

func _zone_at(pos: Vector2) -> StringName:
	# Iterate in fixed priority order so the largest button (melee) doesn't
	# obscure smaller artifact buttons that sit visually beside it.
	for action in [&"artifact_1", &"artifact_2", &"artifact_3", &"roll",
	               &"attack_ranged", &"attack_melee"]:
		var ctl: Control = _zones.get(action)
		if ctl != null and ctl.visible and ctl.get_global_rect().has_point(pos):
			return action
	return &""

func _is_left_zone(pos: Vector2) -> bool:
	# Left half of the screen is reserved for the joystick — but exclude
	# the top bar so taps on the BAG/PAUSE buttons aren't swallowed.
	var vp := get_viewport_rect().size
	return pos.x < vp.x * 0.5 and pos.y > 90.0

# ── Joystick visuals + virtual move ──────────────────────────────────────────

func _reposition_base(pos: Vector2) -> void:
	if _joy_base == null: return
	_joy_base.global_position = pos - _joy_base.size * 0.5
	_joy_center = pos

func _move_knob(touch_pos: Vector2) -> void:
	if _joy_knob == null or _joy_base == null: return
	var offset  := touch_pos - _joy_center
	var clamped := offset.limit_length(KNOB_RADIUS)
	_joy_knob.global_position = _joy_center + clamped - _joy_knob.size * 0.5
	var vec := clamped / KNOB_RADIUS
	InputManager.set_virtual_move(vec if vec.length() > DEAD_ZONE else Vector2.ZERO)

func _reset_knob() -> void:
	if _joy_knob == null or _joy_base == null: return
	_joy_knob.position = (_joy_base.size - _joy_knob.size) * 0.5

# ── Visual feedback on action buttons ────────────────────────────────────────

func _set_btn_alpha(action: StringName, a: float) -> void:
	var ctl: Control = _zones.get(action)
	if ctl == null: return
	var c := ctl.modulate
	c.a = a
	ctl.modulate = c

# ── Modal gating ──────────────────────────────────────────────────────────────

func _modal_visible() -> bool:
	var hud := get_parent()
	if hud == null: return false
	var inv: Node = hud.get_node_or_null("InventoryScreen")
	if inv != null and inv is Control and (inv as Control).visible:
		return true
	var pause: Node = hud.get_node_or_null("PauseMenu")
	if pause != null and pause is Control and (pause as Control).visible:
		return true
	return false

func _release_all() -> void:
	if _fingers.is_empty(): return
	for index in _fingers.keys():
		var f: Dictionary = _fingers[index]
		match str(f.get("mode", "")):
			"action":
				var a: StringName = f.get("action", &"")
				if a != &"":
					InputManager.release_virtual_action(a)
					_set_btn_alpha(a, NORMAL_ALPHA)
			"joystick":
				InputManager.set_virtual_move(Vector2.ZERO)
				_reset_knob()
	_fingers.clear()
