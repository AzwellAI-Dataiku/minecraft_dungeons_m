extends Node

## Regression tests for the TouchRouter dispatcher. We build a fake HUD
## subtree (matching the structure TouchRouter expects) and feed it raw
## InputEventScreenTouch events, then assert that InputManager observed
## the right virtual actions and the right virtual_move vectors.

const TOUCH_ROUTER := preload("res://scripts/ui/TouchRouter.gd")

func _make_hud() -> Dictionary:
	# Root HUD node with the children TouchRouter resolves by name.
	var hud := Control.new()
	hud.name = "HUD"
	hud.size = Vector2(1280, 720)
	Engine.get_main_loop().root.add_child(hud)

	# Fake action buttons with the names TouchRouter looks for.
	var btn_specs := {
		"BtnMelee":     {"action": &"attack_melee",  "rect": Rect2(1020, 432, 252, 280)},
		"BtnRanged":    {"action": &"attack_ranged", "rect": Rect2(868,  432, 142, 148)},
		"BtnRoll":      {"action": &"roll",          "rect": Rect2(1180, 326,  92,  94)},
		"BtnArtifact1": {"action": &"artifact_1",    "rect": Rect2(868,  326,  94,  94)},
		"BtnArtifact2": {"action": &"artifact_2",    "rect": Rect2(972,  326,  94,  94)},
		"BtnArtifact3": {"action": &"artifact_3",    "rect": Rect2(1076, 326,  94,  94)},
	}
	for name in btn_specs.keys():
		var spec: Dictionary = btn_specs[name]
		var b := Button.new()
		b.name = name
		var r: Rect2 = spec.rect
		b.position = r.position
		b.size     = r.size
		hud.add_child(b)

	# Joystick visual subtree.
	var joy := Control.new()
	joy.name = "VirtualJoystick"
	hud.add_child(joy)
	var base := ColorRect.new()
	base.name = "Base"
	base.position = Vector2(60, 455)
	base.size = Vector2(240, 240)
	joy.add_child(base)
	var knob := ColorRect.new()
	knob.name = "Knob"
	knob.position = Vector2(84, 84)
	knob.size = Vector2(72, 72)
	base.add_child(knob)

	# Hidden modal stubs so _modal_visible() returns false.
	var inv := Control.new()
	inv.name = "InventoryScreen"
	inv.visible = false
	hud.add_child(inv)
	var pause := Control.new()
	pause.name = "PauseMenu"
	pause.visible = false
	hud.add_child(pause)

	# The router itself.
	var router: Node = TOUCH_ROUTER.new()
	router.name = "TouchRouter"
	hud.add_child(router)
	# Force the deferred resolve to run synchronously for tests.
	router.call("_resolve_nodes")
	return {"hud": hud, "router": router, "inv": inv, "pause": pause, "knob": knob}

func _touch(pos: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed  = pressed
	e.index    = index
	return e

func _drag(pos: Vector2, index: int = 0) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.position = pos
	e.index    = index
	return e

func _cleanup(d: Dictionary) -> void:
	(d.hud as Node).queue_free()

# ── Tests ────────────────────────────────────────────────────────────────────

func test_melee_button_dispatches_action() -> void:
	var d := _make_hud()
	d.router._input(_touch(Vector2(1100, 600), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"attack_melee"), "melee press dispatched")
	d.router._input(_touch(Vector2(1100, 600), false, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"attack_melee"), "melee release dispatched")
	_cleanup(d)

func test_two_fingers_independent_actions() -> void:
	# THE bug we keep fighting: melee in right hand AND joystick in left hand.
	var d := _make_hud()
	# Finger 0 starts on the joystick (left half).
	d.router._input(_touch(Vector2(180, 590), true, 0))
	# Finger 1 on melee (right side).
	d.router._input(_touch(Vector2(1150, 600), true, 1))
	TestAssert.ok(InputManager.is_action_pressed(&"attack_melee"), "second-finger melee press recognised")
	# Move joystick to register a virtual move while melee held.
	d.router._input(_drag(Vector2(220, 590), 0))
	var v := InputManager.get_move_vector()
	TestAssert.ok(v.length() > 0.0, "joystick still drives move while melee held")
	# Lift melee while joystick is still held.
	d.router._input(_touch(Vector2(1150, 600), false, 1))
	TestAssert.ok(not InputManager.is_action_pressed(&"attack_melee"), "melee released")
	# Lift joystick.
	d.router._input(_touch(Vector2(220, 590), false, 0))
	InputManager.set_virtual_move(Vector2.ZERO)
	_cleanup(d)

func test_artifact_buttons_dispatch() -> void:
	var d := _make_hud()
	d.router._input(_touch(Vector2(910, 370), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"artifact_1"), "artifact_1 dispatched")
	d.router._input(_touch(Vector2(910, 370), false, 0))
	d.router._input(_touch(Vector2(1020, 370), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"artifact_2"), "artifact_2 dispatched")
	d.router._input(_touch(Vector2(1020, 370), false, 0))
	_cleanup(d)

func test_modal_blocks_dispatch() -> void:
	var d := _make_hud()
	(d.inv as Control).visible = true
	d.router._input(_touch(Vector2(1100, 600), true, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"attack_melee"), "modal blocks press")
	(d.inv as Control).visible = false
	_cleanup(d)

func test_drag_only_affects_joystick_finger() -> void:
	var d := _make_hud()
	d.router._input(_touch(Vector2(180, 590), true, 0))   # finger 0 = joystick
	d.router._input(_touch(Vector2(1100, 600), true, 1))  # finger 1 = melee
	# A drag on finger 1 must NOT clobber the joystick virtual_move.
	d.router._input(_drag(Vector2(1110, 605), 1))
	# A drag on finger 0 must move the knob.
	d.router._input(_drag(Vector2(220, 590), 0))
	var v := InputManager.get_move_vector()
	TestAssert.ok(v.length() > 0.0, "joystick drag accepted on finger 0")
	d.router._input(_touch(Vector2(1100, 600), false, 1))
	d.router._input(_touch(Vector2(220, 590), false, 0))
	InputManager.set_virtual_move(Vector2.ZERO)
	_cleanup(d)

func test_release_outside_button_still_releases() -> void:
	var d := _make_hud()
	d.router._input(_touch(Vector2(1100, 600), true, 0))
	TestAssert.ok(InputManager.is_action_pressed(&"attack_melee"), "melee pressed")
	# Lift far away from the original button.
	d.router._input(_touch(Vector2(50, 50), false, 0))
	TestAssert.ok(not InputManager.is_action_pressed(&"attack_melee"), "release outside still releases by index")
	_cleanup(d)

func test_left_zone_starts_joystick() -> void:
	var d := _make_hud()
	d.router._input(_touch(Vector2(120, 500), true, 0))
	d.router._input(_drag(Vector2(220, 500), 0))
	var v := InputManager.get_move_vector()
	TestAssert.ok(v.length() > 0.0, "joystick produces non-zero move")
	d.router._input(_touch(Vector2(220, 500), false, 0))
	InputManager.set_virtual_move(Vector2.ZERO)
	_cleanup(d)
