class_name DamageMath
extends RefCounted

## Power-Level damage scaling, modeled after MD's PL gap formula.
## damage_out = base * SCALE_BASE^(attacker_pl - target_pl)
## Result clamped to [MIN_MULT, MAX_MULT] so PL deltas at the edges of the
## game never produce 0 or runaway numbers.

const SCALE_BASE := 1.165
const MIN_MULT   := 0.10
const MAX_MULT   := 10.0

## Returns the multiplier alone (without applying it to a base value).
static func multiplier(attacker_pl: int, target_pl: int) -> float:
	var delta := attacker_pl - target_pl
	var m := pow(SCALE_BASE, float(delta))
	return clampf(m, MIN_MULT, MAX_MULT)

## Returns base damage scaled by PL delta.
static func scale(base: float, attacker_pl: int, target_pl: int) -> float:
	return base * multiplier(attacker_pl, target_pl)

## Difficulty I/II/III adds a flat PL bonus to all enemies in the dungeon,
## modeling MCD's Default/Adventure/Apocalypse bumps.
static func difficulty_pl_bonus(difficulty: int) -> int:
	match difficulty:
		1: return 0
		2: return 6
		3: return 12
	return 0
