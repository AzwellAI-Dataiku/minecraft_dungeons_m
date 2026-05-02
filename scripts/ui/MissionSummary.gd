extends Control

## Post-run summary screen. Shown when a mission ends (clear or fail).
## Read from GameManager.run_stats and provides a "Return to Camp" button.

@onready var _title:       Label  = $PanelOverlay/Panel/VBox/TitleLabel
@onready var _stats_label: Label  = $PanelOverlay/Panel/VBox/StatsLabel
@onready var _return_btn:  Button = $PanelOverlay/Panel/VBox/ReturnBtn

func _ready() -> void:
	_return_btn.pressed.connect(_on_return)
	_refresh()

func show_for(cleared: bool, stats: Dictionary) -> void:
	GameManager.run_stats = stats
	_title.text = "MISSION CLEAR" if cleared else "DEFEATED"
	_title.modulate = Color(0.4, 1.0, 0.5) if cleared else Color(1.0, 0.4, 0.4)
	_stats_label.text = _format_stats(stats)
	visible = true

func _refresh() -> void:
	if not visible: return
	_stats_label.text = _format_stats(GameManager.run_stats)

func _format_stats(stats: Dictionary) -> String:
	return "Enemies defeated: %d\nItems found: %d\nXP gained: %d\nEmeralds earned: ✦ %d" % [
		int(stats.get("enemies_killed", 0)),
		int(stats.get("items_found", 0)),
		int(stats.get("xp_gained", 0)),
		int(stats.get("emeralds_gained", 0)),
	]

func _on_return() -> void:
	get_tree().paused = false
	GameManager.return_to_hub()
