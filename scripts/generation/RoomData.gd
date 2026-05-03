class_name RoomData
extends RefCounted

enum Type { SPAWN, COMBAT, BOSS, BONUS }

var cell:       Vector2i
var type:       Type
var open_sides: Array[Vector2i] = []   # cardinal direction offsets

func _init(p_cell: Vector2i, p_type: Type) -> void:
	cell = p_cell
	type = p_type

func add_door(direction: Vector2i) -> void:
	if not direction in open_sides:
		open_sides.append(direction)
