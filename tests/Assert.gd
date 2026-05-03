class_name TestAssert
extends RefCounted

## Minimal assertion helpers for the headless test runner.
## State is global because tests are run by a single SceneTree and we want
## to count failures without forcing every test to pass an aggregator.

static var failures:     Array[String] = []
static var passes:       int           = 0
static var current_test: String        = ""

static func reset() -> void:
	failures.clear()
	passes = 0
	current_test = ""

static func _record_pass() -> void:
	passes += 1

static func _fail(message: String) -> void:
	failures.append("[%s] %s" % [current_test, message])

static func ok(condition: bool, message: String = "") -> void:
	if condition:
		_record_pass()
	else:
		_fail("ok failed: %s" % message)

static func equal(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(expected) and actual == expected:
		_record_pass()
	else:
		_fail("equal failed: %s — got %s, expected %s" % [message, str(actual), str(expected)])

static func near(actual: float, expected: float, eps: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) <= eps:
		_record_pass()
	else:
		_fail("near failed: %s — got %f, expected %f (eps %f)" % [message, actual, expected, eps])

static func gt(actual: float, threshold: float, message: String = "") -> void:
	if actual > threshold:
		_record_pass()
	else:
		_fail("gt failed: %s — %f not > %f" % [message, actual, threshold])

static func lt(actual: float, threshold: float, message: String = "") -> void:
	if actual < threshold:
		_record_pass()
	else:
		_fail("lt failed: %s — %f not < %f" % [message, actual, threshold])
