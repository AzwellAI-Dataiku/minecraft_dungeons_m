extends Node

## Abstracts touch / gamepad / keyboard into game actions.
## Other systems should query InputManager.move_vector / is_action_pressed
## instead of reading Input directly so that virtual on-screen controls and
## physical inputs can coexist.

signal virtual_action_pressed(action: StringName)
signal virtual_action_released(action: StringName)

var _virtual_move := Vector2.ZERO
var _virtual_actions: Dictionary = {}

func get_move_vector() -> Vector2:
	var keyboard := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if keyboard.length_squared() > 0.01:
		return keyboard
	return _virtual_move

func is_action_pressed(action: StringName) -> bool:
	if Input.is_action_pressed(action):
		return true
	return bool(_virtual_actions.get(action, false))

func is_action_just_pressed(action: StringName) -> bool:
	if Input.is_action_just_pressed(action):
		return true
	return false  # Virtual just-pressed dispatched via signal instead

# --- Hooks called by on-screen controls (virtual joystick, buttons) ---

func set_virtual_move(vec: Vector2) -> void:
	_virtual_move = vec.limit_length(1.0)

func press_virtual_action(action: StringName) -> void:
	_virtual_actions[action] = true
	virtual_action_pressed.emit(action)

func release_virtual_action(action: StringName) -> void:
	_virtual_actions[action] = false
	virtual_action_released.emit(action)

func haptic_feedback(intensity: float = 0.5, duration_ms: int = 30) -> void:
	if not SaveManager.get_setting("haptics", true):
		return
	if OS.get_name() == "Android":
		Input.vibrate_handheld(duration_ms, clampf(intensity, 0.0, 1.0))
