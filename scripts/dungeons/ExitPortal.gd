extends Area3D

## Touched by player → regenerate dungeon with a fresh seed.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	EventBus.dungeon_cleared.emit(GameManager.active_mission_id, {
		"seed": GameManager.run_seed,
	})
	EventBus.ui_toast.emit("Dungeon cleared — generating a new one…", 1.5)
	GameManager.run_seed = int(Time.get_unix_time_from_system())
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
