class_name EnchantmentSlot
extends Resource

## Per-item-instance enchantment slot. Holds 3 candidates rolled at drop time,
## one of which the player may eventually choose & level up.

@export var candidates:    Array[EnchantmentData] = []
@export var chosen_index:  int = -1   # -1 = not yet chosen
@export var level:         int = 0    # 0 = locked, 1-3 = active

func get_chosen() -> EnchantmentData:
	if chosen_index < 0 or chosen_index >= candidates.size():
		return null
	return candidates[chosen_index]

func get_value() -> float:
	var ench := get_chosen()
	if ench == null: return 0.0
	return ench.value_at(level)

func is_active() -> bool:
	return chosen_index >= 0 and level > 0

func cost_to_next_level() -> int:
	# Mirrors Minecraft Dungeons: 1 / 2 / 3 points to reach lvl 1 / 2 / 3
	return level + 1
