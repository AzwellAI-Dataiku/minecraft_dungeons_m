extends Node

## Regression tests for the ActionButton multi-touch fix.
## These exercise the InputEventScreenTouch path that mouse-from-touch
## emulation cannot reach when a second finger is involved.

const ACTION_BUTTON := preload("res://scripts/ui/ActionButton.gd")

func _make_button(rect_pos: Vector2, rect_size: Vector2, action: StringName) -> Button:
	var btn: Button = ACTION_BUTTON.new()
	btn.action_name = action
	Engine.get_main_loop().root.add_child(btn)
	btn.position = rect_pos
	btn.size     = rect_size
	return btn

func _touch(pos: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed  = pressed
	e.index    = index
	return e

func test_touch_inside_triggers_press() -> void:
	var btn := _make_button(Vector2(100, 100), Vector2(80, 80), &"test_btn_1")
	btn._input(_touch(Vector2(140, 140), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_1"), "touch inside rect triggers press")
	btn._input(_touch(Vector2(140, 140), false, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"test_btn_1"), "lift releases")
	btn.queue_free()

func test_touch_outside_does_not_trigger() -> void:
	var btn := _make_button(Vector2(100, 100), Vector2(80, 80), &"test_btn_2")
	btn._input(_touch(Vector2(50, 50), true, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"test_btn_2"), "touch outside rect ignored")
	btn.queue_free()

func test_release_outside_still_releases() -> void:
	# Press inside, drag outside (we simulate by lifting at a point outside).
	# The button tracks its own touch index, so the release index match is
	# what matters — not the position.
	var btn := _make_button(Vector2(100, 100), Vector2(80, 80), &"test_btn_3")
	btn._input(_touch(Vector2(140, 140), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_3"), "pressed in-rect")
	btn._input(_touch(Vector2(500, 500), false, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"test_btn_3"), "release while outside still releases")
	btn.queue_free()

func test_two_buttons_independent_multitouch() -> void:
	# Simulates left thumb on button A (finger 0) AND right thumb on
	# button B (finger 1). Both must register simultaneously — this is the
	# exact bug the touch fix addresses.
	var btn_a := _make_button(Vector2(50,  50),  Vector2(80, 80), &"test_btn_a")
	var btn_b := _make_button(Vector2(500, 500), Vector2(80, 80), &"test_btn_b")
	btn_a._input(_touch(Vector2(80, 80), true, 0))
	btn_b._input(_touch(Vector2(540, 540), true, 1))
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_a"), "finger 0 → A pressed")
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_b"), "finger 1 → B pressed (multi-touch)")
	btn_a._input(_touch(Vector2(80, 80), false, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"test_btn_a"), "A released")
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_b"), "B still pressed")
	btn_b._input(_touch(Vector2(540, 540), false, 1))
	btn_a.queue_free()
	btn_b.queue_free()

func test_wrong_index_release_does_nothing() -> void:
	var btn := _make_button(Vector2(100, 100), Vector2(80, 80), &"test_btn_4")
	btn._input(_touch(Vector2(140, 140), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_4"), "pressed by finger 0")
	# Different finger lifting → should not release
	btn._input(_touch(Vector2(140, 140), false, 7))
	TestAssert.ok(InputManager.is_action_pressed(&"test_btn_4"), "release with wrong index does not release")
	btn._input(_touch(Vector2(140, 140), false, 0))
	btn.queue_free()
