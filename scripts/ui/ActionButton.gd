extends Button

## Touch-friendly action button that maps press/release to InputManager virtual actions.

@export var action_name: StringName = &""

func _ready() -> void:
	focus_mode = FOCUS_NONE
	button_down.connect(func() -> void:
		if action_name:
			InputManager.press_virtual_action(action_name)
			InputManager.haptic_feedback(0.4, 20)
	)
	button_up.connect(func() -> void:
		if action_name:
			InputManager.release_virtual_action(action_name)
	)
