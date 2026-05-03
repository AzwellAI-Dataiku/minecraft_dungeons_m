extends Button

## Touch-friendly action button with direct multi-touch support.
## Uses _input + InputEventScreenTouch so a second finger (e.g. right hand
## while joystick is held by left) still registers correctly.

@export var action_name: StringName = &""

var _touch_index := -1

func _ready() -> void:
	focus_mode = FOCUS_NONE

func _input(event: InputEvent) -> void:
	if not action_name:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			modulate.a = 0.55
			InputManager.press_virtual_action(action_name)
			InputManager.haptic_feedback(0.4, 20)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			modulate.a = 1.0
			InputManager.release_virtual_action(action_name)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_index != -1:
			return
		if event.pressed and get_global_rect().has_point(event.position):
			modulate.a = 0.55
			InputManager.press_virtual_action(action_name)
		elif not event.pressed:
			modulate.a = 1.0
			InputManager.release_virtual_action(action_name)
