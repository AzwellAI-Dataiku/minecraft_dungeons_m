extends Node

signal player_spawned(player: Node)
signal player_died(player: Node)
signal player_health_changed(current: float, maximum: float)
signal player_level_changed(level: int, xp: int, xp_to_next: int)
signal player_power_level_changed(power_level: int)

signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node, killer: Node)
signal enemy_damaged(enemy: Node, amount: float, source: Node)

signal item_dropped(item_data: Resource, world_position: Vector3)
signal item_picked_up(item_data: Resource)
signal item_equipped(item_data: Resource, slot: String)
signal item_salvaged(item_data: Resource, refund: int)

signal dungeon_generation_started(seed: int, theme: StringName)
signal dungeon_generation_finished(room_count: int)
signal dungeon_cleared(mission_id: StringName, stats: Dictionary)
signal boss_phase_changed(boss: Node, phase: int)

signal mission_started(mission_id: StringName)
signal mission_failed(mission_id: StringName, reason: String)

signal scene_change_requested(scene_path: String, payload: Dictionary)
signal save_requested
signal save_completed
signal save_failed(reason: String)

signal ui_toast(message: String, duration: float)
