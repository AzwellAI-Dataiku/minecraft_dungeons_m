class_name Hitbox
extends Area3D

signal hit_registered(hurtbox: Hurtbox)

var _packet: DamagePacket = null
var _hit_set: Array[Node] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_deferred("monitoring", false)

func activate(packet: DamagePacket) -> void:
	_packet = packet
	_hit_set.clear()
	set_deferred("monitoring", true)

func deactivate() -> void:
	set_deferred("monitoring", false)
	_hit_set.clear()

func _on_area_entered(area: Area3D) -> void:
	if _packet == null or not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	if hurtbox in _hit_set:
		return
	_hit_set.append(hurtbox)
	hurtbox.receive_damage(_packet)
	hit_registered.emit(hurtbox)
