extends Node3D

## Procedural dungeon scene controller.
## Builds geometry → bakes navigation → places player & enemies → spawns
## an exit portal once the boss dies.

const ZOMBIE_SCENE     := preload("res://scenes/enemies/zombie.tscn")
const SKELETON_SCENE   := preload("res://scenes/enemies/skeleton.tscn")
const VINDICATOR_SCENE := preload("res://scenes/enemies/vindicator.tscn")

const ZOMBIE_DATA      := preload("res://data/enemies/zombie_data.tres")
const SKELETON_DATA    := preload("res://data/enemies/skeleton_data.tres")
const VINDICATOR_DATA  := preload("res://data/enemies/vindicator_data.tres")

const EXIT_PORTAL      := preload("res://scenes/dungeons/exit_portal.tscn")

@onready var nav_region:     NavigationRegion3D = $NavigationRegion3D
@onready var geometry_root:  Node3D             = $Geometry
@onready var entities_root:  Node3D             = $Entities
@onready var player:         Node3D             = $Player

var _builder:      DungeonBuilder
var _room_builder: RoomBuilder
var _seed:         int
var _boss_node:    Node = null

func _ready() -> void:
	_seed = GameManager.run_seed if GameManager.run_seed != 0 else int(Time.get_unix_time_from_system())
	GameManager.run_seed = _seed
	var theme: int = _seed % 2
	EventBus.dungeon_generation_started.emit(_seed, &"crypt" if theme == 0 else &"desert")

	_builder = DungeonBuilder.new()
	_builder.generate(_seed, 8)

	_room_builder = RoomBuilder.new()
	_room_builder.build(_builder.rooms, _builder.corridors, geometry_root, theme)

	_setup_navigation()
	# Give the bake a couple of frames to complete before placing agents
	await get_tree().create_timer(0.5).timeout

	_place_player_at_spawn()
	_spawn_entities()
	EventBus.player_spawned.emit(player)
	EventBus.dungeon_generation_finished.emit(_builder.rooms.size())

	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)

# ── Navigation ────────────────────────────────────────────────────────────────

func _setup_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	mesh.agent_height    = 1.8
	mesh.agent_radius    = 0.45
	mesh.agent_max_climb = 0.5
	mesh.cell_size       = 0.35
	mesh.cell_height     = 0.2
	nav_region.navigation_mesh = mesh
	nav_region.bake_navigation_mesh()

# ── Placement ─────────────────────────────────────────────────────────────────

func _place_player_at_spawn() -> void:
	for room in _builder.rooms:
		if room.type == RoomData.Type.SPAWN:
			var p := RoomBuilder.room_world_center(room.cell)
			p.y = 0.9
			player.global_position = p
			return

func _spawn_entities() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed ^ 0xC0FFEE
	for room in _builder.rooms:
		var center := RoomBuilder.room_world_center(room.cell)
		match room.type:
			RoomData.Type.COMBAT:
				_spawn_combat_pack(center, rng)
			RoomData.Type.BOSS:
				_spawn_boss(center)
			RoomData.Type.BONUS:
				_spawn_bonus_marker(center)
			_:
				pass

func _spawn_combat_pack(center: Vector3, rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(2, 4)
	for i in count:
		var offset := Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0))
		var pick   := rng.randi() % 3
		match pick:
			0: _spawn_enemy(ZOMBIE_SCENE,     ZOMBIE_DATA,     center + offset)
			1: _spawn_enemy(SKELETON_SCENE,   SKELETON_DATA,   center + offset)
			2: _spawn_enemy(VINDICATOR_SCENE, VINDICATOR_DATA, center + offset)

func _spawn_boss(center: Vector3) -> void:
	# Stand-in boss: beefier vindicator. Replace with proper boss in M3+.
	_boss_node = _spawn_enemy(VINDICATOR_SCENE, VINDICATOR_DATA, center)

func _spawn_enemy(scene: PackedScene, data: Resource, pos: Vector3) -> Node3D:
	var e := scene.instantiate()
	e.data = data
	entities_root.add_child(e)
	(e as Node3D).global_position = Vector3(pos.x, 0.9, pos.z)
	return e

func _spawn_bonus_marker(center: Vector3) -> void:
	# Treasure visual placeholder until M5 loot drops.
	var marker := CSGBox3D.new()
	marker.size = Vector3(1.0, 1.0, 1.0)
	marker.use_collision = true
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.0, 1)
	mat.emission_energy_multiplier = 1.5
	marker.material_override = mat
	entities_root.add_child(marker)
	marker.global_position = Vector3(center.x, 0.5, center.z)

# ── Boss death → portal ───────────────────────────────────────────────────────

func _on_enemy_died(enemy: Node, _killer: Node) -> void:
	if enemy != _boss_node:
		return
	_boss_node = null
	# Place portal at the boss's room centre
	for room in _builder.rooms:
		if room.type == RoomData.Type.BOSS:
			var p := EXIT_PORTAL.instantiate()
			entities_root.add_child(p)
			(p as Node3D).global_position = RoomBuilder.room_world_center(room.cell)
			EventBus.ui_toast.emit("The exit portal opens…", 2.5)
			return

func _on_player_died(_p: Node) -> void:
	EventBus.ui_toast.emit("You died — restarting…", 2.0)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
