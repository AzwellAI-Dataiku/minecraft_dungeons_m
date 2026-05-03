extends Node

## Autoload registry + dispatcher for artifact (active-skill) effects.
## Each effect is a private method named `_artifact_<id>` returning the
## cooldown to apply (seconds). Lookups are explicit so unknown ids fail loudly.

const _IDS := [
	&"tnt_charge",
	&"harvester_pulse",
	&"shockwave",
]

func has(id: StringName) -> bool:
	return id in _IDS

func ids() -> Array:
	return _IDS.duplicate()

func activate(id: StringName, user: Node, item: ItemData) -> float:
	match id:
		&"tnt_charge":      return _tnt_charge(user, item)
		&"harvester_pulse": return _harvester_pulse(user, item)
		&"shockwave":       return _shockwave(user, item)
	push_warning("ArtifactEffects: unknown id %s" % id)
	return 0.0

# ── Effects ───────────────────────────────────────────────────────────────────

const _TNT_FUSE          := 1.2
const _TNT_RADIUS        := 5.0
const _TNT_DMG_PER_PL    := 4.0

const _HARVEST_RADIUS    := 6.0
const _HARVEST_DMG_PER_PL := 3.0
const _HARVEST_HEAL_FRAC := 0.25

const _SHOCK_RADIUS      := 4.0
const _SHOCK_FORCE       := 12.0
const _SHOCK_BASE_DMG    := 8.0

func _tnt_charge(user: Node, item: ItemData) -> float:
	var origin: Vector3 = (user as Node3D).global_position + Vector3(0.0, 0.5, 0.0)
	var facing: Vector3 = user.get_facing_direction() if user.has_method("get_facing_direction") else Vector3.FORWARD
	var pos: Vector3 = origin + facing * 2.0

	var visual := CSGSphere3D.new()
	visual.radius = 0.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.2)
	visual.material = mat
	user.get_parent().add_child(visual)
	visual.global_position = pos
	var tw := visual.create_tween()
	tw.tween_property(visual, "scale", Vector3.ONE * 1.6, _TNT_FUSE)

	var pl := Inventory.get_power_level()
	var damage := _TNT_DMG_PER_PL * float(pl)
	var timer := user.get_tree().create_timer(_TNT_FUSE)
	timer.timeout.connect(func() -> void:
		_aoe_damage(pos, _TNT_RADIUS, damage, pl, 6.0, user)
		EventBus.camera_shake.emit(0.5)
		if is_instance_valid(visual):
			visual.queue_free()
	)
	return _cooldown(item, 8.0)

func _harvester_pulse(user: Node, item: ItemData) -> float:
	var origin: Vector3 = (user as Node3D).global_position
	var pl := Inventory.get_power_level()
	var damage := _HARVEST_DMG_PER_PL * float(pl)
	_aoe_damage(origin, _HARVEST_RADIUS, damage, pl, 4.0, user)

	if user.has_method("heal"):
		var max_hp: float = 100.0
		if "max_health" in user:
			max_hp = float(user.get("max_health"))
		user.call("heal", max_hp * _HARVEST_HEAL_FRAC)
	EventBus.camera_shake.emit(0.3)
	return _cooldown(item, 35.0)

func _shockwave(user: Node, item: ItemData) -> float:
	var origin: Vector3 = (user as Node3D).global_position
	var enemies := user.get_tree().get_nodes_in_group(&"enemies")
	for e in enemies:
		if not (e is Node3D): continue
		var d: Vector3 = (e.global_position - origin)
		d.y = 0.0
		if d.length() <= _SHOCK_RADIUS:
			var hb := e.get_node_or_null("Hurtbox") as Hurtbox
			if hb == null: continue
			var pkt := DamagePacket.make(_SHOCK_BASE_DMG, user)
			pkt.knockback_dir   = d.normalized() if d.length_squared() > 0.0 else Vector3.FORWARD
			pkt.knockback_force = _SHOCK_FORCE
			pkt.attacker_pl     = Inventory.get_power_level()
			hb.receive_damage(pkt)
	EventBus.camera_shake.emit(0.35)
	return _cooldown(item, 5.0)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _aoe_damage(pos: Vector3, radius: float, damage: float, attacker_pl: int, knockback: float, source: Node) -> void:
	var enemies := source.get_tree().get_nodes_in_group(&"enemies")
	for e in enemies:
		if not (e is Node3D): continue
		var d: Vector3 = (e.global_position - pos)
		d.y = 0.0
		if d.length() <= radius:
			var hb := e.get_node_or_null("Hurtbox") as Hurtbox
			if hb == null: continue
			var pkt := DamagePacket.make(damage, source)
			pkt.knockback_dir   = d.normalized() if d.length_squared() > 0.0 else Vector3.FORWARD
			pkt.knockback_force = knockback
			pkt.attacker_pl     = attacker_pl
			hb.receive_damage(pkt)

func _cooldown(item: ItemData, default_cd: float) -> float:
	if item != null and item.cooldown > 0.0:
		return item.cooldown
	return default_cd
