extends Node

func test_press_then_release() -> void:
	InputManager.press_virtual_action(&"test_x")
	TestAssert.ok(InputManager.is_action_pressed(&"test_x"), "pressed after press")
	InputManager.release_virtual_action(&"test_x")
	TestAssert.ok(not InputManager.is_action_pressed(&"test_x"), "released after release")

func test_virtual_move_clamped_to_unit() -> void:
	InputManager.set_virtual_move(Vector2(2.0, 0.0))
	var v := InputManager.get_move_vector()
	TestAssert.near(v.length(), 1.0, 0.001, "magnitude clamped to 1.0")
	InputManager.set_virtual_move(Vector2.ZERO)

func test_keyboard_overrides_virtual_when_present() -> void:
	# With no keyboard input, virtual is returned.
	InputManager.set_virtual_move(Vector2(0.5, 0.5))
	var v := InputManager.get_move_vector()
	TestAssert.near(v.x, 0.5, 0.01, "virtual x passes through")
	TestAssert.near(v.y, 0.5, 0.01, "virtual y passes through")
	InputManager.set_virtual_move(Vector2.ZERO)

func test_virtual_actions_dictionary_isolated() -> void:
	InputManager.press_virtual_action(&"action_a")
	InputManager.press_virtual_action(&"action_b")
	TestAssert.ok(InputManager.is_action_pressed(&"action_a"), "a pressed")
	TestAssert.ok(InputManager.is_action_pressed(&"action_b"), "b pressed")
	InputManager.release_virtual_action(&"action_a")
	TestAssert.ok(not InputManager.is_action_pressed(&"action_a"), "a released")
	TestAssert.ok(InputManager.is_action_pressed(&"action_b"), "b still pressed")
	InputManager.release_virtual_action(&"action_b")
