extends Node

## Read-only registry mapping item id → ItemData template. Used by SaveManager
## to round-trip inventory contents (templates only — per-instance enchantments
## are re-rolled on load).

const _ITEMS := [
	preload("res://data/items/iron_sword.tres"),
	preload("res://data/items/oak_bow.tres"),
	preload("res://data/items/guard_armor.tres"),
	preload("res://data/items/fireball_rune.tres"),
	preload("res://data/items/artifact_tnt.tres"),
	preload("res://data/items/artifact_harvester.tres"),
	preload("res://data/items/artifact_shockwave.tres"),
]

var _by_id: Dictionary = {}

func _ready() -> void:
	for item in _ITEMS:
		_by_id[item.id] = item

func get_template(id: StringName) -> ItemData:
	return _by_id.get(id)

func has_id(id: StringName) -> bool:
	return _by_id.has(id)
