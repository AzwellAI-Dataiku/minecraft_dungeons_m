extends Node

## Per-slot cooldown bookkeeping + InputManager → ArtifactEffects dispatch.
## Lives as a child of Player.

var _tracker: ArtifactCooldownTracker = ArtifactCooldownTracker.new()
var _player: Node3D
var _emit_timer: float = 0.0
const EMIT_INTERVAL := 0.05  # 20 Hz cooldown UI updates

func _ready() -> void:
	_player = get_parent() as Node3D
	InputManager.virtual_action_pressed.connect(_on_action)

func _process(delta: float) -> void:
	_tracker.tick(delta)
	_emit_timer -= delta
	if _emit_timer <= 0.0:
		_emit_timer = EMIT_INTERVAL
		for s in ArtifactCooldownTracker.SLOTS:
			EventBus.artifact_cooldown_changed.emit(s, _tracker.remaining(s), _tracker.ratio(s))

func _on_action(action: StringName) -> void:
	var slot := str(action)
	if not (slot in ArtifactCooldownTracker.SLOTS): return
	if _player == null: return
	if not _tracker.is_ready(slot):
		EventBus.ui_toast.emit("On cooldown: %.1fs" % _tracker.remaining(slot), 0.6)
		return
	var item := Inventory.get_equipped(slot) as ItemData
	if item == null or item.type != ItemData.Type.ARTIFACT:
		EventBus.ui_toast.emit("No artifact in slot", 0.6)
		return
	if item.artifact_id == &"" or not ArtifactEffects.has(item.artifact_id):
		EventBus.ui_toast.emit("Artifact not implemented", 0.8)
		return
	var cd := ArtifactEffects.activate(item.artifact_id, _player, item)
	_tracker.start(slot, cd)
	InputManager.haptic_feedback(0.5, 25)
	EventBus.artifact_activated.emit(slot, item)
	EventBus.artifact_cooldown_changed.emit(slot, cd, 1.0)

func get_ratio(slot: String) -> float:
	return _tracker.ratio(slot)

func get_remaining(slot: String) -> float:
	return _tracker.remaining(slot)
