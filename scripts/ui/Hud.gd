extends CanvasLayer

@onready var health_bar:     ProgressBar    = $HealthBar
@onready var emerald_label:  Label          = $TopBar/EmeraldLabel
@onready var inv_screen:     Control        = $InventoryScreen
@onready var inv_button:     Button         = $TopBar/InvButton

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health)
	EventBus.item_picked_up.connect(_on_item_changed)
	EventBus.item_salvaged.connect(_on_item_changed)
	inv_button.pressed.connect(_on_inv_pressed)
	_refresh_emeralds()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_inventory"):
		_on_inv_pressed()

func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value     = current

func _on_inv_pressed() -> void:
	if inv_screen.visible:
		inv_screen.visible = false
	else:
		inv_screen.show_screen()

func _on_item_changed(_a = null, _b = null) -> void:
	_refresh_emeralds()

func _refresh_emeralds() -> void:
	emerald_label.text = "✦ %d" % Inventory.emeralds
