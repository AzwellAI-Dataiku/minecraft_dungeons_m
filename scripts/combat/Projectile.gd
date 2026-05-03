class_name Projectile
extends Node3D

@export var speed: float   = 20.0
@export var lifetime: float = 3.0

var damage:    float   = 15.0
var direction: Vector3 = Vector3.FORWARD
var source:    Node    = null
var is_crit:   bool    = false

var _elapsed: float = 0.0
var _hitbox: Hitbox = null

func _ready() -> void:
	_hitbox = get_node_or_null("Hitbox") as Hitbox
	if _hitbox == null:
		return
	var packet := DamagePacket.make(damage, source)
	packet.knockback_dir   = direction
	packet.knockback_force = 5.0
	packet.is_crit         = is_crit
	_hitbox.activate(packet)
	_hitbox.hit_registered.connect(_on_hit)

func _on_hit(_h: Hurtbox, packet: DamagePacket) -> void:
	if source != null and source.is_in_group(&"player"):
		EnchantmentDB.on_damage_dealt(source, packet)
	queue_free()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	global_position += direction * speed * delta
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)
