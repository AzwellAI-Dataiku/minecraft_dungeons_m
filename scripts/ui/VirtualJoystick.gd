extends Control

## Visual stub for the virtual joystick. All input is handled by TouchRouter,
## which finds this node by name and drives Base/Knob global_position.
##
## Leaving this as a thin Control (instead of removing it) keeps the existing
## hud.tscn structure intact and provides a stable spawn point for the visuals.

@export var radius: float    = 110.0
@export var dead_zone: float = 0.18

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
