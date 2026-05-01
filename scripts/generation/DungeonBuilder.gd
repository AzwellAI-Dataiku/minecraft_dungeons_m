class_name DungeonBuilder
extends RefCounted

## Seeded room+corridor graph generator.
## Produces a deterministic layout: spawn → chain of combat rooms → boss,
## with optional bonus branch.

const CARDINAL := [
	Vector2i( 1,  0),
	Vector2i(-1,  0),
	Vector2i( 0,  1),
	Vector2i( 0, -1),
]

var rooms:     Array[RoomData]     = []
var corridors: Array[CorridorData] = []

var _grid: Dictionary = {}   # Vector2i → RoomData
var _rng:  RandomNumberGenerator

func generate(p_seed: int, room_count: int = 8) -> void:
	rooms.clear()
	corridors.clear()
	_grid.clear()
	_rng = RandomNumberGenerator.new()
	_rng.seed = p_seed

	# Spawn anchor at origin
	_add_room(Vector2i.ZERO, RoomData.Type.SPAWN)

	# Random walk to grow combat rooms
	var attempts := 0
	while rooms.size() < room_count - 1 and attempts < 200:
		if _try_add_combat_room():
			attempts = 0
		else:
			attempts += 1

	# Boss: place adjacent to the room farthest from spawn
	var farthest := rooms[0]
	var best := -1
	for r in rooms:
		if r.type == RoomData.Type.SPAWN:
			continue
		var d := abs(r.cell.x) + abs(r.cell.y)
		if d > best:
			best = d
			farthest = r
	_attach_terminal_room(farthest, RoomData.Type.BOSS)

	# Bonus: 70 % chance, attached to a random combat room
	if _rng.randf() < 0.7:
		var combat: Array = rooms.filter(func(r): return r.type == RoomData.Type.COMBAT)
		if not combat.is_empty():
			combat.shuffle()
			for src in combat:
				if _attach_terminal_room(src, RoomData.Type.BONUS):
					break

# ── Helpers ───────────────────────────────────────────────────────────────────

func _add_room(cell: Vector2i, type: RoomData.Type) -> RoomData:
	var room := RoomData.new(cell, type)
	rooms.append(room)
	_grid[cell] = room
	return room

func _try_add_combat_room() -> bool:
	var src: RoomData = rooms[_rng.randi() % rooms.size()]
	var dirs := CARDINAL.duplicate()
	dirs.shuffle()
	for d in dirs:
		var new_cell: Vector2i = src.cell + d
		if not _grid.has(new_cell):
			_add_room(new_cell, RoomData.Type.COMBAT)
			_connect(src.cell, new_cell)
			return true
	return false

func _attach_terminal_room(src: RoomData, type: RoomData.Type) -> bool:
	var dirs := CARDINAL.duplicate()
	dirs.shuffle()
	for d in dirs:
		var new_cell: Vector2i = src.cell + d
		if not _grid.has(new_cell):
			_add_room(new_cell, type)
			_connect(src.cell, new_cell)
			return true
	# Fallback: convert source itself
	src.type = type
	return false

func _connect(a: Vector2i, b: Vector2i) -> void:
	var ra: RoomData = _grid[a]
	var rb: RoomData = _grid[b]
	ra.add_door(b - a)
	rb.add_door(a - b)
	corridors.append(CorridorData.new(a, b))
