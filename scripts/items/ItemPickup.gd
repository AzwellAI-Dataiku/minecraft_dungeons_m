class_name ItemPickup
extends Area3D

var item_data: ItemData = null

@onready var _mesh:  MeshInstance3D = $Mesh
@onready var _label: Label3D        = $Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_bob()
	if item_data != null:
		_apply_data()

func setup(data: ItemData) -> void:
	item_data = data
	if is_node_ready():
		_apply_data()

func _apply_data() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color               = item_data.mesh_color
	mat.emission_enabled           = true
	mat.emission                   = item_data.mesh_color * 0.6
	mat.emission_energy_multiplier = 1.5
	_mesh.set_surface_override_material(0, mat)
	_label.text = item_data.display_name

func _start_bob() -> void:
	var base_y := position.y
	var tw := create_tween().set_loops()
	tw.tween_property(self, "position:y", base_y + 0.35, 0.9) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", base_y, 0.9) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"): return
	if item_data == null: return
	Inventory.add_item(item_data)
	EventBus.item_picked_up.emit(item_data)
	EventBus.ui_toast.emit("Picked up: %s" % item_data.display_name, 1.5)
	queue_free()
