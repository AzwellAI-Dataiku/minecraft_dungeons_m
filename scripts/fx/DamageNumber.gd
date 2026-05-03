class_name DamageNumber
extends Label3D

func show_damage(amount: float, is_crit: bool = false) -> void:
	text        = str(int(amount))
	font_size   = 64 if is_crit else 48
	modulate    = Color(1.0, 0.9, 0.1) if is_crit else Color.WHITE
	billboard   = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 2.2, 0.75).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.75).set_delay(0.25)
	tw.chain().tween_callback(queue_free)
