class_name EnchantmentData
extends Resource

## Template for an enchantment effect. Lives as a shared .tres file —
## per-item state lives in EnchantmentSlot instead.

@export var id:                StringName   = &""
@export var display_name:      String       = "Enchantment"
@export var description:       String       = ""

## Maps to a handler in EnchantmentDB (e.g. &"sharpness", &"critical").
@export var effect_id:         StringName   = &""

## Effect strength at level 1, 2, 3 (index = level - 1).
@export var values_per_level:  Array[float] = [0.10, 0.18, 0.30]

## Which ItemData.Type values this enchantment may roll on.
## 0=MELEE 1=RANGED 2=ARMOR 3=ARTIFACT
@export var applicable_types:  Array[int]   = []

@export var color:             Color        = Color(0.55, 0.85, 1.0, 1)

func max_level() -> int:
	return values_per_level.size()

func value_at(level: int) -> float:
	if level <= 0 or level > values_per_level.size():
		return 0.0
	return values_per_level[level - 1]
