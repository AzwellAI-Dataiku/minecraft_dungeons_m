extends Button

## Visual-only on-screen action button.
##
## All touch handling is done by TouchRouter (a sibling under the HUD), which
## hit-tests against this button's get_global_rect() and dispatches to
## InputManager.press_virtual_action / release_virtual_action.
##
## We intentionally don't override _input() here: in Godot 4.3 the per-button
## _input callback inside a CanvasLayer was unreliable for second-finger touch
## events on Android, leading to total input dropouts. Centralising in the
## router fixes that.
##
## We also disable mouse-event consumption (mouse_filter = IGNORE) so the
## router sees the touch in _input() before any GUI auto-consumption.

@export var action_name: StringName = &""

func _ready() -> void:
	focus_mode = FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Don't toggle pressed-state on mouse, the router handles that visually.
	toggle_mode = false
	disabled = false
