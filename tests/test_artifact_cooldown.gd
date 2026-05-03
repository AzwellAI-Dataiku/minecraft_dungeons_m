extends Node

func test_initial_state_all_ready() -> void:
	var t := ArtifactCooldownTracker.new()
	for s in ArtifactCooldownTracker.SLOTS:
		TestAssert.ok(t.is_ready(s), "%s should start ready" % s)
		TestAssert.near(t.ratio(s), 0.0, 0.001, "%s ratio starts 0" % s)

func test_start_then_tick_to_zero() -> void:
	var t := ArtifactCooldownTracker.new()
	t.start("artifact_1", 5.0)
	TestAssert.ok(not t.is_ready("artifact_1"), "should be on cd after start")
	TestAssert.near(t.remaining("artifact_1"), 5.0, 0.001, "remaining = full")
	TestAssert.near(t.ratio("artifact_1"), 1.0, 0.001, "ratio = 1.0")
	t.tick(2.5)
	TestAssert.near(t.remaining("artifact_1"), 2.5, 0.001, "after half: 2.5s")
	TestAssert.near(t.ratio("artifact_1"), 0.5, 0.001, "ratio = 0.5")
	t.tick(10.0)
	TestAssert.ok(t.is_ready("artifact_1"), "ready after over-tick")
	TestAssert.near(t.remaining("artifact_1"), 0.0, 0.001, "remaining clamped to 0")

func test_slots_independent() -> void:
	var t := ArtifactCooldownTracker.new()
	t.start("artifact_1", 5.0)
	t.start("artifact_3", 3.0)
	TestAssert.ok(not t.is_ready("artifact_1"), "slot1 on cd")
	TestAssert.ok(t.is_ready("artifact_2"), "slot2 still ready")
	TestAssert.ok(not t.is_ready("artifact_3"), "slot3 on cd")
	t.tick(3.0)
	TestAssert.ok(t.is_ready("artifact_3"), "slot3 ready after 3s")
	TestAssert.ok(not t.is_ready("artifact_1"), "slot1 still on cd (2s left)")

func test_unknown_slot_ignored() -> void:
	var t := ArtifactCooldownTracker.new()
	t.start("does_not_exist", 5.0)  # should not crash
	TestAssert.ok(t.is_ready("does_not_exist"), "unknown slot reports ready")
	TestAssert.near(t.ratio("does_not_exist"), 0.0, 0.001, "unknown ratio is 0")
