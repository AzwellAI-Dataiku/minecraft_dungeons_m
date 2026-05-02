extends Node

const SLOTS   := ["melee", "ranged", "armor", "artifact_1", "artifact_2", "artifact_3"]
const BAG_MAX := 20

var equipped:       Dictionary          = {}
var bag:            Array[ItemData]     = []
var emeralds:       int                 = 0

func _ready() -> void:
	for s in SLOTS:
		equipped[s] = null

# ── Public API ────────────────────────────────────────────────────────────────

func add_item(item: ItemData) -> void:
	var slot := get_slot_for_item(item)
	if equipped.get(slot) == null:
		_equip(item, slot)
		return
	if bag.size() < BAG_MAX:
		bag.append(item)
		return
	# Bag full — auto-salvage oldest
	var refund := _salvage_value(item)
	emeralds += refund
	EventBus.item_salvaged.emit(item, refund)
	EventBus.ui_toast.emit("Bag full — salvaged %s for %d ✦" % [item.display_name, refund], 2.0)

func equip_from_bag(bag_index: int, slot: String) -> void:
	if bag_index < 0 or bag_index >= bag.size(): return
	var item := bag[bag_index] as ItemData
	var old  := equipped.get(slot) as ItemData
	_equip(item, slot)
	bag.remove_at(bag_index)
	if old != null:
		bag.append(old)

func salvage_bag_item(bag_index: int) -> void:
	if bag_index < 0 or bag_index >= bag.size(): return
	var item   := bag[bag_index] as ItemData
	var refund := _salvage_value(item)
	emeralds += refund
	bag.remove_at(bag_index)
	EventBus.item_salvaged.emit(item, refund)
	EventBus.ui_toast.emit("Salvaged %s → %d ✦" % [item.display_name, refund], 1.5)

func get_equipped(slot: String) -> ItemData:
	return equipped.get(slot) as ItemData

func get_power_level() -> int:
	var total := 0
	var count := 0
	for v in equipped.values():
		if v != null:
			total += (v as ItemData).power_level
			count += 1
	return total / max(count, 1)

func get_slot_for_item(item: ItemData) -> String:
	match item.type:
		ItemData.Type.MELEE:    return "melee"
		ItemData.Type.RANGED:   return "ranged"
		ItemData.Type.ARMOR:    return "armor"
		ItemData.Type.ARTIFACT:
			for s in ["artifact_1", "artifact_2", "artifact_3"]:
				if equipped.get(s) == null: return s
			return "artifact_1"
	return "melee"

func serialize() -> Dictionary:
	var out := { "emeralds": emeralds, "equipped": {}, "bag": [] }
	for slot in SLOTS:
		var it := equipped.get(slot) as ItemData
		out["equipped"][slot] = str(it.id) if it != null else ""
	for it in bag:
		out["bag"].append(str((it as ItemData).id))
	return out

func deserialize(dict: Dictionary) -> void:
	clear()
	emeralds = int(dict.get("emeralds", 0))
	var equipped_data: Dictionary = dict.get("equipped", {})
	for slot in SLOTS:
		var id_str := str(equipped_data.get(slot, ""))
		if id_str.is_empty(): continue
		var template := ItemDB.get_template(StringName(id_str))
		if template == null: continue
		equipped[slot] = EnchantmentDB.roll_item_instance(template)
	for id_str in dict.get("bag", []):
		var template := ItemDB.get_template(StringName(str(id_str)))
		if template != null:
			bag.append(EnchantmentDB.roll_item_instance(template))

func clear() -> void:
	for s in SLOTS:
		equipped[s] = null
	bag.clear()
	emeralds = 0

# ── Private ───────────────────────────────────────────────────────────────────

func _equip(item: ItemData, slot: String) -> void:
	equipped[slot] = item
	EventBus.item_equipped.emit(item, slot)

func _salvage_value(item: ItemData) -> int:
	match item.rarity:
		ItemData.Rarity.COMMON: return 2
		ItemData.Rarity.RARE:   return 6
		ItemData.Rarity.UNIQUE: return 18
	return 2
