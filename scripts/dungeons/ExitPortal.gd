extends Area3D

## Touched by player → emits dungeon_cleared. Dungeon.gd listens and shows the
## mission summary, which routes the player back to the hub.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	EventBus.dungeon_cleared.emit(GameManager.active_mission_id, {
		"seed": GameManager.run_seed,
	})
