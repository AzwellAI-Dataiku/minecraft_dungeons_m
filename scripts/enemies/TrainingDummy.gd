extends StaticBody3D

@export var max_health: float         = 80.0
@export var damage_number_scene: PackedScene

@onready var _hurtbox:  Hurtbox       = $Hurtbox
@onready var _label:    Label3D       = $HealthLabel
@onready var _mesh:     MeshInstance3D = $DummyMesh

var hp: float

func _ready() -> void:
	hp = max_health
	_hurtbox.took_damage.connect(_on_damage)
	_refresh_label()

func _on_damage(packet: DamagePacket) -> void:
	hp = maxf(hp - packet.amount, 0.0)
	_refresh_label()
	_spawn_number(packet)
	if hp <= 0.0:
		_die()

func _spawn_number(packet: DamagePacket) -> void:
	if damage_number_scene == null:
		return
	var dn := damage_number_scene.instantiate() as DamageNumber
	get_parent().add_child(dn)
	dn.global_position = global_position + Vector3(
		randf_range(-0.4, 0.4), 2.0, randf_range(-0.2, 0.2)
	)
	dn.show_damage(packet.amount, packet.is_crit)

func _refresh_label() -> void:
	_label.text = "%d / %d" % [int(hp), int(max_health)]

func _die() -> void:
	_hurtbox.invincible = true
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
