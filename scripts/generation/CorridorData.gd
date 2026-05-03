class_name CorridorData
extends RefCounted

var from_cell: Vector2i
var to_cell:   Vector2i

func _init(a: Vector2i, b: Vector2i) -> void:
	from_cell = a
	to_cell   = b

func is_horizontal() -> bool:
	return from_cell.y == to_cell.y
