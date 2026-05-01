extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health)

func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value     = current
