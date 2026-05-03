extends Node

func test_multiplier_equal_pl_is_one() -> void:
	TestAssert.near(DamageMath.multiplier(10, 10), 1.0, 0.001, "equal PL → 1.0")

func test_attacker_higher_increases_damage() -> void:
	var d := DamageMath.scale(100.0, 20, 10)
	TestAssert.gt(d, 100.0, "+10 PL should increase damage")
	TestAssert.near(d, 100.0 * pow(1.165, 10), 0.5, "matches formula")

func test_attacker_lower_decreases_damage() -> void:
	var d := DamageMath.scale(100.0, 5, 15)
	TestAssert.lt(d, 100.0, "-10 PL should reduce damage")

func test_extreme_high_capped_at_10x() -> void:
	var d := DamageMath.scale(100.0, 999, 0)
	TestAssert.near(d, 1000.0, 0.001, "capped at 10x")

func test_extreme_low_floored_at_one_tenth() -> void:
	var d := DamageMath.scale(100.0, 0, 999)
	TestAssert.near(d, 10.0, 0.001, "floored at 0.1x")

func test_difficulty_bonuses() -> void:
	TestAssert.equal(DamageMath.difficulty_pl_bonus(1), 0,  "I = +0")
	TestAssert.equal(DamageMath.difficulty_pl_bonus(2), 6,  "II = +6")
	TestAssert.equal(DamageMath.difficulty_pl_bonus(3), 12, "III = +12")
	TestAssert.equal(DamageMath.difficulty_pl_bonus(99), 0, "unknown → 0")
