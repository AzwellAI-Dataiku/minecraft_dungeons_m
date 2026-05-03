extends Node3D

## Bootstrap script for the M1-M3 test arena.
## Builds and bakes a NavigationMesh at runtime so CSG collision shapes
## are included, then enemies can use NavigationAgent3D immediately.

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

func _ready() -> void:
	_setup_navigation()
	EventBus.player_died.connect(_on_player_died)

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

func _on_player_died(_player: Node) -> void:
	EventBus.ui_toast.emit("Game Over — restarting…", 2.0)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
