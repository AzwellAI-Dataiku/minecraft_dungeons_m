class_name RoomBuilder
extends RefCounted

## Materialises the abstract DungeonBuilder graph into 3D CSG geometry.
## Picks a theme for floor/wall colours; rooms tinted by type (spawn/boss/bonus).

enum Theme { CRYPT, DESERT }

const CELL_SIZE       := 16.0
const ROOM_SIZE       := 10.0
const CORRIDOR_WIDTH  := 4.0
const CORRIDOR_LENGTH := CELL_SIZE - ROOM_SIZE   # 6.0
const DOOR_WIDTH      := 3.0
const WALL_HEIGHT     := 4.0
const WALL_THICK      := 1.0
const FLOOR_THICK     := 1.0

func build(rooms: Array, corridors: Array, parent: Node3D, theme: int = 0) -> void:
	var floor_color := _theme_floor(theme)
	var wall_color  := _theme_wall(theme)
	for room in rooms:
		_build_room(room, parent, floor_color, wall_color)
	for corr in corridors:
		_build_corridor(corr, parent, floor_color, wall_color)

# ── Rooms ─────────────────────────────────────────────────────────────────────

func _build_room(room: RoomData, parent: Node3D, base_floor: Color, wall_color: Color) -> void:
	var center := room_world_center(room.cell)

	# Floor tinted by room type
	var floor_color := _tint_for_type(room.type, base_floor)
	_box(parent, center + Vector3(0.0, -FLOOR_THICK * 0.5, 0.0),
		Vector3(ROOM_SIZE, FLOOR_THICK, ROOM_SIZE), floor_color)

	# Four walls — punch a doorway gap on each open side
	# (dir, position offset, full size, axis "x" or "z")
	var sides := [
		[Vector2i(0, -1), Vector3(0, WALL_HEIGHT * 0.5, -ROOM_SIZE * 0.5),
			Vector3(ROOM_SIZE, WALL_HEIGHT, WALL_THICK), "x"],
		[Vector2i(0,  1), Vector3(0, WALL_HEIGHT * 0.5,  ROOM_SIZE * 0.5),
			Vector3(ROOM_SIZE, WALL_HEIGHT, WALL_THICK), "x"],
		[Vector2i( 1, 0), Vector3( ROOM_SIZE * 0.5, WALL_HEIGHT * 0.5, 0),
			Vector3(WALL_THICK, WALL_HEIGHT, ROOM_SIZE), "z"],
		[Vector2i(-1, 0), Vector3(-ROOM_SIZE * 0.5, WALL_HEIGHT * 0.5, 0),
			Vector3(WALL_THICK, WALL_HEIGHT, ROOM_SIZE), "z"],
	]
	for side in sides:
		var dir: Vector2i  = side[0]
		var off: Vector3   = side[1]
		var sz:  Vector3   = side[2]
		var axis: String   = side[3]
		if dir in room.open_sides:
			_split_wall_with_door(parent, center + off, sz, axis, wall_color)
		else:
			_box(parent, center + off, sz, wall_color)

func _split_wall_with_door(parent: Node3D, mid: Vector3, full: Vector3, axis: String, color: Color) -> void:
	var seg_len := (ROOM_SIZE - DOOR_WIDTH) * 0.5
	var pad     := (ROOM_SIZE - seg_len) * 0.5
	if axis == "x":
		_box(parent, mid - Vector3(pad, 0, 0), Vector3(seg_len, full.y, full.z), color)
		_box(parent, mid + Vector3(pad, 0, 0), Vector3(seg_len, full.y, full.z), color)
	else:
		_box(parent, mid - Vector3(0, 0, pad), Vector3(full.x, full.y, seg_len), color)
		_box(parent, mid + Vector3(0, 0, pad), Vector3(full.x, full.y, seg_len), color)

# ── Corridors ────────────────────────────────────────────────────────────────

func _build_corridor(corr: CorridorData, parent: Node3D, floor_color: Color, wall_color: Color) -> void:
	var a := room_world_center(corr.from_cell)
	var b := room_world_center(corr.to_cell)
	var center := (a + b) * 0.5
	var horiz  := corr.is_horizontal()

	var floor_size := Vector3(CORRIDOR_LENGTH, FLOOR_THICK, CORRIDOR_WIDTH) if horiz \
	                else Vector3(CORRIDOR_WIDTH, FLOOR_THICK, CORRIDOR_LENGTH)
	_box(parent, center + Vector3(0, -FLOOR_THICK * 0.5, 0), floor_size, floor_color)

	# Side walls hugging the corridor
	if horiz:
		for z in [-CORRIDOR_WIDTH * 0.5 - WALL_THICK * 0.5,
		           CORRIDOR_WIDTH * 0.5 + WALL_THICK * 0.5]:
			_box(parent, center + Vector3(0, WALL_HEIGHT * 0.5, z),
				Vector3(CORRIDOR_LENGTH, WALL_HEIGHT, WALL_THICK), wall_color)
	else:
		for x in [-CORRIDOR_WIDTH * 0.5 - WALL_THICK * 0.5,
		           CORRIDOR_WIDTH * 0.5 + WALL_THICK * 0.5]:
			_box(parent, center + Vector3(x, WALL_HEIGHT * 0.5, 0),
				Vector3(WALL_THICK, WALL_HEIGHT, CORRIDOR_LENGTH), wall_color)

# ── Geometry primitive ────────────────────────────────────────────────────────

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var b := CSGBox3D.new()
	b.position = pos
	b.size = size
	b.use_collision = true
	b.material_override = _material(color)
	parent.add_child(b)

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = 0.85
	return m

# ── Coordinate / theme helpers ────────────────────────────────────────────────

static func room_world_center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)

func _theme_floor(theme: int) -> Color:
	match theme:
		Theme.CRYPT:  return Color(0.32, 0.30, 0.36, 1)
		Theme.DESERT: return Color(0.55, 0.45, 0.30, 1)
	return Color(0.4, 0.4, 0.4, 1)

func _theme_wall(theme: int) -> Color:
	match theme:
		Theme.CRYPT:  return Color(0.22, 0.20, 0.26, 1)
		Theme.DESERT: return Color(0.62, 0.50, 0.32, 1)
	return Color(0.3, 0.3, 0.3, 1)

func _tint_for_type(type: int, base: Color) -> Color:
	match type:
		RoomData.Type.SPAWN: return base.lerp(Color(0.30, 0.65, 0.35), 0.45)
		RoomData.Type.BOSS:  return base.lerp(Color(0.65, 0.20, 0.20), 0.45)
		RoomData.Type.BONUS: return base.lerp(Color(0.75, 0.62, 0.20), 0.50)
	return base
