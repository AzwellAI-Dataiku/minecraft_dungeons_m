class_name ArtifactCooldownTracker
extends RefCounted

## Pure-data cooldown bookkeeping for the 3 artifact slots.
## Decoupled from the scene tree so it's unit-testable in headless runs.

const SLOTS := ["artifact_1", "artifact_2", "artifact_3"]

var _remaining: Dictionary = {}
var _maximum:   Dictionary = {}

func _init() -> void:
	for s in SLOTS:
		_remaining[s] = 0.0
		_maximum[s]   = 0.0

func start(slot: String, seconds: float) -> void:
	if not (slot in _remaining): return
	_remaining[slot] = maxf(seconds, 0.0)
	_maximum[slot]   = maxf(seconds, 0.0)

func tick(delta: float) -> void:
	for s in _remaining:
		if _remaining[s] > 0.0:
			_remaining[s] = maxf(_remaining[s] - delta, 0.0)

func is_ready(slot: String) -> bool:
	return _remaining.get(slot, 0.0) <= 0.0

func remaining(slot: String) -> float:
	return _remaining.get(slot, 0.0)

func ratio(slot: String) -> float:
	var m: float = _maximum.get(slot, 0.0)
	if m <= 0.0: return 0.0
	return _remaining.get(slot, 0.0) / m
