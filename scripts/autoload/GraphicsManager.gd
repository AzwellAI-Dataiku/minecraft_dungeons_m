extends Node

signal quality_changed(quality: String)

const PRESETS: Dictionary = {
	"low": {
		"msaa":    Viewport.MSAA_DISABLED,
		"scale":   0.55,
		"shadows": false,
	},
	"med": {
		"msaa":    Viewport.MSAA_2X,
		"scale":   0.75,
		"shadows": true,
	},
	"high": {
		"msaa":    Viewport.MSAA_4X,
		"scale":   1.0,
		"shadows": true,
	},
}

var current_quality: String = "med"
var current_fps:     int    = 60
var shadows_enabled: bool   = true

func _ready() -> void:
	var q   := str(SaveManager.get_setting("graphics_quality", "med"))
	var fps := int(SaveManager.get_setting("target_fps", 60))
	apply_quality(q,   false)
	set_target_fps(fps, false)

# ── Quality preset ────────────────────────────────────────────────────────────

func apply_quality(quality: String, save: bool = true) -> void:
	if not PRESETS.has(quality):
		quality = "med"
	current_quality = quality
	var p: Dictionary = PRESETS[quality]
	shadows_enabled   = bool(p["shadows"])
	var vp := get_viewport()
	if vp:
		vp.msaa_3d           = p["msaa"] as Viewport.MSAA
		vp.scaling_3d_scale  = float(p["scale"])
	quality_changed.emit(quality)
	if save:
		SaveManager.set_setting("graphics_quality", quality)

# ── FPS cap ───────────────────────────────────────────────────────────────────

func set_target_fps(fps: int, save: bool = true) -> void:
	current_fps    = fps
	Engine.max_fps = fps
	if save:
		SaveManager.set_setting("target_fps", fps)
