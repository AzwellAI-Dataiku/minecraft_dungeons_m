extends Node

## Central registry + runtime dispatcher for enchantments.
## Holds the catalog, rolls per-item slot candidates, applies effects on
## damage in/out, kills, and passive stats (move speed, etc).

const SHARPNESS    := preload("res://data/enchantments/sharpness.tres")
const CRITICAL     := preload("res://data/enchantments/critical.tres")
const POWER_SHOT   := preload("res://data/enchantments/power_shot.tres")
const SOUL_SIPHON  := preload("res://data/enchantments/soul_siphon.tres")
const ECHO         := preload("res://data/enchantments/echo.tres")
const PROTECTION   := preload("res://data/enchantments/protection.tres")
const SWIFTNESS    := preload("res://data/enchantments/swiftness.tres")
const RECOVERY     := preload("res://data/enchantments/recovery.tres")

var catalog: Array[EnchantmentData] = []

func _ready() -> void:
	catalog = [
		SHARPNESS, CRITICAL, POWER_SHOT, SOUL_SIPHON, ECHO,
		PROTECTION, SWIFTNESS, RECOVERY,
	]

# ── Item-instance rolling ─────────────────────────────────────────────────────

func roll_item_instance(template: ItemData) -> ItemData:
	var instance: ItemData = template.duplicate(true) as ItemData
	var slot_count := template.get_enchant_slots()
	var slots: Array[EnchantmentSlot] = []
	for _i in slot_count:
		var slot := EnchantmentSlot.new()
		slot.candidates = _pick_candidates(template.type, 3)
		slots.append(slot)
	instance.slots = slots
	return instance

func _pick_candidates(type: int, count: int) -> Array[EnchantmentData]:
	var matching: Array[EnchantmentData] = []
	for e in catalog:
		if type in e.applicable_types:
			matching.append(e)
	matching.shuffle()
	var picked: Array[EnchantmentData] = []
	var n := mini(count, matching.size())
	for i in n:
		picked.append(matching[i])
	return picked

# ── Effect dispatch ───────────────────────────────────────────────────────────

func _active_for_types(types: Array) -> Array:
	var out: Array = []
	for slot_key in Inventory.SLOTS:
		var item := Inventory.get_equipped(slot_key)
		if item == null: continue
		if not (item.type in types): continue
		for slot in item.slots:
			if not slot.is_active(): continue
			out.append({ "id": slot.get_chosen().effect_id, "value": slot.get_value() })
	return out

func apply_outgoing_damage(packet: DamagePacket) -> void:
	for e in _active_for_types([ItemData.Type.MELEE, ItemData.Type.RANGED]):
		match e.id:
			&"sharpness", &"power_shot":
				packet.amount *= (1.0 + e.value)
			&"critical":
				if not packet.is_crit and randf() < e.value:
					packet.is_crit  = true
					packet.amount  *= 1.5

func apply_incoming_damage(packet: DamagePacket) -> void:
	var armor: ItemData = Inventory.get_equipped("armor")
	if armor == null: return
	var reduction := armor.base_defense
	for slot in armor.slots:
		if not slot.is_active(): continue
		if slot.get_chosen().effect_id == &"protection":
			reduction += slot.get_value()
	reduction = clampf(reduction, 0.0, 0.85)
	packet.amount = maxf(packet.amount * (1.0 - reduction), 0.0)

func on_damage_dealt(player: Node, packet: DamagePacket) -> void:
	for e in _active_for_types([ItemData.Type.MELEE, ItemData.Type.RANGED]):
		if e.id == &"soul_siphon" and player.has_method("heal"):
			player.heal(packet.amount * e.value)

func roll_extra_attack() -> bool:
	for e in _active_for_types([ItemData.Type.MELEE, ItemData.Type.RANGED]):
		if e.id == &"echo" and randf() < e.value:
			return true
	return false

func get_move_speed_multiplier() -> float:
	var armor: ItemData = Inventory.get_equipped("armor")
	if armor == null: return 1.0
	for slot in armor.slots:
		if not slot.is_active(): continue
		if slot.get_chosen().effect_id == &"swiftness":
			return 1.0 + slot.get_value()
	return 1.0

func get_dungeon_entry_heal() -> float:
	var armor: ItemData = Inventory.get_equipped("armor")
	if armor == null: return 0.0
	for slot in armor.slots:
		if not slot.is_active(): continue
		if slot.get_chosen().effect_id == &"recovery":
			return slot.get_value()
	return 0.0

# ── Player upgrade actions ────────────────────────────────────────────────────

func choose_candidate(item: ItemData, slot_idx: int, candidate_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= item.slots.size(): return false
	if PlayerProgression.enchant_points < 1: return false
	var slot := item.slots[slot_idx]
	if slot.chosen_index != -1: return false
	if candidate_idx < 0 or candidate_idx >= slot.candidates.size(): return false
	slot.chosen_index = candidate_idx
	slot.level        = 1
	PlayerProgression.spend_enchant_points(1)
	EventBus.enchantment_chosen.emit(item, slot_idx)
	return true

func upgrade_slot(item: ItemData, slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= item.slots.size(): return false
	var slot := item.slots[slot_idx]
	if not slot.is_active(): return false
	if slot.level >= slot.get_chosen().max_level(): return false
	var cost := slot.cost_to_next_level()
	if PlayerProgression.enchant_points < cost: return false
	slot.level += 1
	PlayerProgression.spend_enchant_points(cost)
	EventBus.enchantment_chosen.emit(item, slot_idx)
	return true
