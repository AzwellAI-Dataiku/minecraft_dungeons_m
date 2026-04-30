class_name Hurtbox
extends Area3D

signal took_damage(packet: DamagePacket)

var invincible: bool = false

func _ready() -> void:
	set_deferred("monitoring", false)

func receive_damage(packet: DamagePacket) -> void:
	if invincible or packet == null:
		return
	took_damage.emit(packet)
