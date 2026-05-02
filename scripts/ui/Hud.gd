extends CanvasLayer

@onready var health_bar:    ProgressBar = $HealthBar
@onready var xp_bar:        ProgressBar = $XpBar
@onready var emerald_label: Label       = $TopBar/EmeraldLabel
@onready var power_label:   Label       = $TopBar/PowerLabel
@onready var level_label:   Label       = $TopBar/LevelLabel
@onready var inv_screen:    Control     = $InventoryScreen
@onready var inv_button:    Button      = $TopBar/InvButton
@onready var pause_button:  Button      = $TopBar/PauseButton
@onready var pause_menu:    Control     = $PauseMenu

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health)
	EventBus.player_level_changed.connect(_on_level)
	EventBus.item_picked_up.connect(_on_item_changed)
	EventBus.item_salvaged.connect(_on_item_changed)
	EventBus.item_equipped.connect(_on_item_changed)
	inv_button.pressed.connect(_on_inv_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	_refresh_emeralds()
	_refresh_level()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_inventory"):
		_on_inv_pressed()
	elif event.is_action_pressed(&"pause"):
		_on_pause_pressed()

func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value     = current

func _on_level(_level: int, _xp: int, _xp_to_next: int) -> void:
	_refresh_level()

func _on_inv_pressed() -> void:
	if inv_screen.visible:
		inv_screen.visible = false
	else:
		inv_screen.show_screen()

func _on_pause_pressed() -> void:
	if pause_menu.visible:
		pause_menu.close()
	else:
		pause_menu.open()

func _on_item_changed(_a = null, _b = null) -> void:
	_refresh_emeralds()
	power_label.text = "PL %d" % Inventory.get_power_level()

func _refresh_emeralds() -> void:
	emerald_label.text = "✦ %d" % Inventory.emeralds

func _refresh_level() -> void:
	level_label.text = "Lv %d  ✚%d" % [PlayerProgression.level, PlayerProgression.enchant_points]
	xp_bar.max_value = PlayerProgression.xp_to_next()
	xp_bar.value     = PlayerProgression.xp
	power_label.text = "PL %d" % Inventory.get_power_level()
