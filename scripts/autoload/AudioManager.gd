extends Node

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

func _ready() -> void:
	_ensure_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)
	_apply_volumes_from_save()

func _ensure_buses() -> void:
	# Buses should exist in default_bus_layout.tres; this is a safety net.
	for bus_name in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)

func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(0.0)
	_music_player.play()
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", linear_to_db(1.0), fade_in)

func stop_music(fade_out: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", linear_to_db(0.0), fade_out)
	tw.tween_callback(_music_player.stop)

func play_sfx(stream: AudioStream, pitch_variance: float = 0.0) -> void:
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
			p.play()
			return

func _apply_volumes_from_save() -> void:
	_set_bus_volume(BUS_MASTER, SaveManager.get_setting("master_volume", 1.0))
	_set_bus_volume(BUS_MUSIC, SaveManager.get_setting("music_volume", 0.8))
	_set_bus_volume(BUS_SFX, SaveManager.get_setting("sfx_volume", 1.0))

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))
