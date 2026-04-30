class_name DamagePacket
extends Resource

enum Type { PHYSICAL, MAGIC, FIRE, LIGHTNING, POISON }

@export var amount: float = 10.0
@export var type: Type = Type.PHYSICAL
@export var is_crit: bool = false
@export var knockback_force: float = 4.0

# Set at runtime — not serialised
var knockback_dir: Vector3 = Vector3.ZERO
var source: Node = null

static func make(dmg: float, src: Node = null, t: Type = Type.PHYSICAL) -> DamagePacket:
	var p := DamagePacket.new()
	p.amount = dmg
	p.source = src
	p.type = t
	return p

static func make_crit(dmg: float, src: Node = null) -> DamagePacket:
	var p := make(dmg * 1.5, src)
	p.is_crit = true
	return p
