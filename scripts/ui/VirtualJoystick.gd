extends Control

@export var radius: float    = 80.0
@export var dead_zone: float = 0.15

@onready var _base: Control = $Base
@onready var _knob: Control = $Base/Knob

var _touch_index := -1
var _base_center := Vector2.ZERO

func _ready() -> void:
	_reset_knob()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _in_left_zone(event.position):
			_touch_index = event.index
			_reposition_base(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_move_knob(event.position)

func _in_left_zone(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x * 0.5

func _reposition_base(pos: Vector2) -> void:
	_base.global_position = pos - _base.size * 0.5
	_base_center = pos
	_reset_knob()

func _move_knob(touch_pos: Vector2) -> void:
	var offset  := touch_pos - _base_center
	var clamped := offset.limit_length(radius)
	_knob.global_position = _base_center + clamped - _knob.size * 0.5
	var vec := clamped / radius
	InputManager.set_virtual_move(vec if vec.length() > dead_zone else Vector2.ZERO)

func _release() -> void:
	_touch_index = -1
	_reset_knob()
	InputManager.set_virtual_move(Vector2.ZERO)

func _reset_knob() -> void:
	_knob.position = (_base.size - _knob.size) * 0.5
