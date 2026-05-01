class_name ItemData
extends Resource

enum Type   { MELEE, RANGED, ARMOR, ARTIFACT }
enum Rarity { COMMON, RARE, UNIQUE }

@export var id:           StringName = &""
@export var display_name: String     = "Item"
@export var description:  String     = ""
@export var type:         Type       = Type.MELEE
@export var rarity:       Rarity     = Rarity.COMMON
@export var power_level:  int        = 1
@export var base_damage:  float      = 10.0  # weapon DPS reference
@export var base_defense: float      = 0.0   # armor damage-reduction fraction 0–1
@export var cooldown:     float      = 0.0   # artifact cooldown seconds
@export var mesh_color:   Color      = Color(0.8, 0.8, 0.8, 1)

func get_enchant_slots() -> int:
	match rarity:
		Rarity.COMMON: return 1
		Rarity.RARE:   return 2
		Rarity.UNIQUE: return 3
	return 1

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color.WHITE
		Rarity.RARE:   return Color(0.4, 0.7, 1.0)
		Rarity.UNIQUE: return Color(1.0, 0.6, 0.1)
	return Color.WHITE

func get_rarity_label() -> String:
	match rarity:
		Rarity.COMMON: return "Common"
		Rarity.RARE:   return "Rare"
		Rarity.UNIQUE: return "Unique"
	return "?"
