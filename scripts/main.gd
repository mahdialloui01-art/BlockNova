extends Control

const GRID := 10
# Contemporary luminous palette: cyan, ultraviolet, magenta, amber, mint and coral.
const COLORS := [
	Color("#27DDF2"), Color("#8B6CFF"), Color("#FF62B5"),
	Color("#FFC857"), Color("#35D6A5"), Color("#FF7968")
]
const SHAPES := [
	[Vector2i(0,0)],
	[Vector2i(0,0),Vector2i(1,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)]
]

enum Screen { HOME, SETTINGS, PLAYING, PAUSED }
var screen: Screen = Screen.HOME
var board: Array = []
var pieces: Array = []
var piece_colors: Array = []
var score := 0
var combo_streak := 0
var best := 0
var selected := -1
var dragging := false
var pointer := Vector2.ZERO
# Cell inside the grabbed piece that stays under the user's finger.
var drag_cell_offset := Vector2i.ZERO
var game_over := false
var cell := 34.0
var board_origin := Vector2.ZERO
var board_size := 0.0
var tray_y := 0.0
var font: Font
var use_3d_visuals := false
var sound_enabled := true
var vibration_enabled := true
var config: ConfigFile
var home_ui: CanvasLayer
var _sfx_players: Dictionary = {}
var _music_player: AudioStreamPlayer
var _theme_color := Color("#27DDF2")
var _theme_target := Color("#27DDF2")
var placement_note_index := 0

func _setup_audio() -> void:
	# Layered, original game-audio palette. Generated locally so no external
	# asset downloads, licensing uncertainty, or missing-file startup failures.
	for effect in ["ui", "pickup", "place", "clear", "combo", "error", "gameover"]:
		var player := AudioStreamPlayer.new()
		player.name = "SFX_" + effect
		player.volume_db = -9.0
		match effect:
			"place": player.volume_db = -4.0
			"clear", "combo": player.volume_db = -2.5
			"gameover": player.volume_db = -3.5
			"error": player.volume_db = -7.0
		player.stream = _make_sfx_stream(effect)
		add_child(player)
		_sfx_players[effect] = player
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ModernAmbientMusic"
	_music_player.volume_db = -24.0
	_music_player.stream = _make_music_stream()
	add_child(_music_player)
	_update_music_state()

func _make_music_stream() -> AudioStreamWAV:
	# Original Modern Hybrid Cinematic score: a 12-second stereo loop with
	# warm Dm9/Bbmaj7/Fadd9/Cadd9 pads, felt-piano plucks, sub-bass and glass air.
	# Synthesized locally at 48 kHz; no external samples or third-party music.
	const sample_rate := 48000
	const duration := 12.0
	const bar_duration := 3.0
	const sample_count := int(sample_rate * duration)
	const crossfade_seconds := 0.36
	const crossfade_frames := int(sample_rate * crossfade_seconds)
	var progression := [
		[146.83, 174.61, 220.00, 261.63, 329.63],
		[116.54, 146.83, 174.61, 220.00, 261.63],
		[174.61, 220.00, 261.63, 329.63, 392.00],
		[130.81, 164.81, 196.00, 246.94, 293.66]
	]
	var bass_roots := [73.42, 58.27, 87.31, 65.41]
	var left := PackedFloat32Array()
	var right := PackedFloat32Array()
	left.resize(sample_count)
	right.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(sample_rate)
		var bar := posmod(int(t / bar_duration), 4)
		var local_bar := fmod(t, bar_duration)
		var chord: Array = progression[bar]
		var previous_chord: Array = progression[posmod(bar - 1, 4)]
		var pad_current := 0.0
		var pad_previous := 0.0
		for note_index in range(chord.size()):
			var frequency := float(chord[note_index])
			pad_current += sin(TAU * frequency * t) * 0.014
			pad_current += sin(TAU * frequency * 1.0017 * t + 0.17) * 0.008
			pad_current += sin(TAU * frequency * 2.002 * t) * 0.0022
			if local_bar < crossfade_seconds:
				var previous_frequency := float(previous_chord[note_index])
				pad_previous += sin(TAU * previous_frequency * t) * 0.014
				pad_previous += sin(TAU * previous_frequency * 1.0017 * t + 0.17) * 0.008
				pad_previous += sin(TAU * previous_frequency * 2.002 * t) * 0.0022
		var chord_blend := smoothstep(0.0, crossfade_seconds, local_bar)
		var breathing := 0.88 + 0.12 * sin(TAU * 0.055 * t)
		var pad := lerpf(pad_previous, pad_current, chord_blend) * breathing
		var bass_t := fmod(local_bar, 1.5)
		var bass_frequency := float(bass_roots[bar])
		var bass_envelope := exp(-3.8 * bass_t) * (1.0 - exp(-bass_t * 45.0))
		var bass := sin(TAU * bass_frequency * bass_t) * bass_envelope * 0.105
		var beat_t := fmod(local_bar, 0.75)
		var beat_index := mini(int(local_bar / 0.75), 3)
		var pluck := 0.0
		if beat_t < 0.48:
			var pluck_frequency := float(chord[beat_index]) * 2.0
			pluck = _piano_voice(pluck_frequency, beat_t, 0.16)
			pluck += _modern_pluck(pluck_frequency * 1.5, beat_t, 0.13, 5.6)
		# Slow stereo shimmer supplies width while leaving the bass firmly centered.
		var motion := sin(TAU * 0.032 * t)
		var air_phase := TAU * 1046.5 * t + 0.34 * sin(TAU * 0.071 * t)
		var air := (sin(air_phase) + 0.42 * sin(air_phase * 1.498)) * 0.0065
		var left_sample := pad * 0.82 + bass * 0.76 + pluck * (0.82 + motion * 0.12) + air * (0.78 + motion * 0.22)
		var right_sample := pad * 0.82 + bass * 0.76 + pluck * (0.82 - motion * 0.12) + air * (0.78 - motion * 0.22)
		# Gentle saturation rounds peaks without audible hard clipping.
		left[i] = left_sample / (1.0 + absf(left_sample) * 0.72)
		right[i] = right_sample / (1.0 + absf(right_sample) * 0.72)
	# Equal-power-like overlap at the loop seam prevents a click on repeat.
	for i in range(crossfade_frames):
		var blend := float(i) / float(maxi(crossfade_frames - 1, 1))
		var head_index := i
		var tail_index := sample_count - crossfade_frames + i
		var mixed_left := lerpf(left[tail_index], left[head_index], blend)
		var mixed_right := lerpf(right[tail_index], right[head_index], blend)
		left[head_index] = mixed_left
		right[head_index] = mixed_right
		left[tail_index] = mixed_left
		right[tail_index] = mixed_right
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 4)
	for i in range(sample_count):
		pcm.encode_s16(i * 4, int(round(clampf(left[i], -1.0, 1.0) * 32767.0)))
		pcm.encode_s16(i * 4 + 2, int(round(clampf(right[i], -1.0, 1.0) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = pcm
	return stream

func _update_music_state() -> void:
	if not is_instance_valid(_music_player):
		return
	if sound_enabled:
		if not _music_player.playing:
			_music_player.play()
	else:
		_music_player.stop()

func _make_sfx_stream(effect: String, note_index: int = 0, combo_index: int = 0) -> AudioStreamWAV:
	const sample_rate := 48000
	var duration := 0.12
	match effect:
		"ui": duration = 0.075
		"pickup": duration = 0.11
		"place": duration = 0.115
		"clear": duration = 0.82
		"combo": duration = 0.92
		"error": duration = 0.17
		"gameover": duration = 0.62
	var sample_count: int = maxi(1, int(round(sample_rate * duration)))
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var placement_offsets := [-75.0, 55.0, -60.0, 85.0, -45.0, 100.0, -90.0, 65.0, -55.0, 90.0, -80.0, 45.0]
	var placement_pitch: float = 2050.0 + placement_offsets[posmod(note_index, placement_offsets.size())]
	var combo_shift: float = pow(2.0, float(mini(combo_index, 18) * 2) / 12.0)
	var combo_root: float = minf(520.0 * combo_shift, 1080.0)
	var lowpass_state := 0.0
	var highpass_previous_input := 0.0
	var highpass_previous_output := 0.0
	var error_phase := 0.0
	for i in range(sample_count):
		var t := float(i) / float(sample_rate)
		var normalized_t := float(i) / float(sample_count)
		var sample := 0.0
		match effect:
			"place":
				# Short, tactile wooden/plastic click. Main resonances stay in 1.5–3 kHz.
				var attack := minf(1.0, t * 700.0)
				var body := sin(TAU * placement_pitch * t) * exp(-42.0 * t) * 0.58
				body += sin(TAU * minf(placement_pitch * 1.25, 2990.0) * t) * exp(-58.0 * t) * 0.24
				body += sin(TAU * minf(placement_pitch * 1.43, 2990.0) * t) * exp(-78.0 * t) * 0.10
				var tap := (sin(TAU * 4700.0 * t) * 0.55 + sin(TAU * 6900.0 * t) * 0.25) * exp(-125.0 * t)
				var placement_tone := _modern_pluck(740.0 + float(posmod(note_index, 7)) * 42.0, t, 0.22, 19.0)
				sample = (body + tap * 0.12) * attack * 0.72 + placement_tone
			"clear", "combo":
				# Warm synthesized grand-piano arpeggio: C/E/G-style triad, with each
				# consecutive combo transposed upward by two semitones.
				var note_duration := 0.15
				var note_slot := mini(int(t / note_duration), 3)
				var note_offsets := [0.0, 3.0, 7.0, 10.0]
				var note_frequency: float = minf(combo_root * pow(2.0, note_offsets[note_slot] / 12.0), 1190.0)
				var local_t := fmod(t, note_duration)
				if t < note_duration * 4.0:
					# Keep the warm piano body, then add a modern glassy synth-pluck layer.
					sample = _piano_voice(note_frequency, local_t, 0.62 if effect == "clear" else 0.70)
					sample += _modern_pluck(note_frequency * 1.5, local_t, 0.38, 5.8)
					var shimmer_frequency := clampf(note_frequency * 5.02, 2500.0, 5900.0)
					sample += sin(TAU * shimmer_frequency * local_t) * exp(-15.0 * local_t) * 0.045
					if effect == "combo":
						# A restrained sub impact gives multi-line clears cinematic weight.
						var impact_frequency := lerpf(92.0, 48.0, minf(t / 0.28, 1.0))
						sample += sin(TAU * impact_frequency * t) * exp(-8.5 * t) * 0.19
					else:
						# A bright upper harmonic makes a single clear feel crystalline.
						sample += _modern_pluck(note_frequency * 2.0, local_t, 0.12, 4.2)
			"error":
				# Muted downward drop: 300 Hz to 100 Hz during the first 100 ms.
				var drop_t := minf(t / 0.1, 1.0)
				var drop_frequency := 300.0 * pow(100.0 / 300.0, drop_t)
				var error_env := exp(-13.0 * t) * minf(1.0, t * 90.0)
				error_phase += drop_frequency / float(sample_rate)
				sample = (sin(TAU * error_phase) * 0.78 + sin(TAU * error_phase * 0.5) * 0.12) * error_env
			"ui":
				# Short, polished digital-glass chime for modern interface feedback.
				sample = _modern_pluck(880.0, t, 0.42, 12.0) + _piano_voice(1318.51, t, 0.12)
			"pickup":
				# A brighter rising synth key with a soft piano undertone.
				sample = _modern_pluck(987.77, t, 0.52, 9.0) + _piano_voice(659.25, t, 0.16)
			"gameover":
				# Three descending piano notes instead of a synthetic pitch sweep.
				var gameover_slot := mini(int(t / 0.19), 2)
				var gameover_freqs := [523.25, 392.00, 261.63]
				var gameover_local := fmod(t, 0.19)
				sample = _piano_voice(gameover_freqs[gameover_slot], gameover_local, 0.48) + _modern_pluck(gameover_freqs[gameover_slot] * 1.5, gameover_local, 0.22, 6.0)
			_:
				var env := exp(-8.0 * normalized_t)
				sample = sin(TAU * 520.0 * t) * env * 0.3
		# DSP: high-pass placement at 150 Hz; low-pass invalid drops at 800 Hz.
		if effect == "place":
			var hp_rc := 1.0 / (TAU * 150.0)
			var hp_dt := 1.0 / float(sample_rate)
			var hp_alpha := hp_rc / (hp_rc + hp_dt)
			var hp_output := hp_alpha * (highpass_previous_output + sample - highpass_previous_input)
			highpass_previous_input = sample
			highpass_previous_output = hp_output
			sample = hp_output
		elif effect == "error":
			var lp_alpha := 1.0 - exp(-TAU * 800.0 / float(sample_rate))
			lowpass_state += lp_alpha * (sample - lowpass_state)
			sample = lowpass_state
		samples[i] = clampf(sample, -1.0, 1.0)
	# A quiet pair of delayed repeats adds a short room-like tail to line clears.
	if effect == "clear" or effect == "combo":
		var delay_one := int(0.105 * float(sample_rate))
		var delay_two := int(0.205 * float(sample_rate))
		for i in range(sample_count):
			var echo := 0.0
			if i >= delay_one:
				echo += samples[i - delay_one] * 0.20
			if i >= delay_two:
				echo += samples[i - delay_two] * 0.10
			samples[i] = clampf(samples[i] + echo, -1.0, 1.0)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in range(sample_count):
		pcm.encode_s16(i * 2, int(round(samples[i] * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream


# Physically-inspired piano voice built from inharmonic partials and a fast hammer attack.
# Every partial decays at its own rate, giving a plucked-string/piano character.
# Rich, physically-inspired piano voice: three slightly detuned strings,
# inharmonic upper partials, hammer transient, and a resonant soundboard.
func _piano_voice(frequency: float, local_t: float, velocity: float = 0.7) -> float:
	var t := maxf(local_t, 0.0)
	var attack := 1.0 - exp(-t * 1500.0)
	var release := exp(-t * 2.15)
	# Three piano strings create natural beating and width without a synthetic chorus.
	var string_a := sin(TAU * frequency * t) * 0.37
	var string_b := sin(TAU * frequency * 1.0018 * t + 0.12) * 0.34
	var string_c := sin(TAU * frequency * 0.9983 * t - 0.09) * 0.29
	var fundamental := (string_a + string_b + string_c) * exp(-3.9 * t)
	# Stiff piano strings are slightly inharmonic; upper partials decay faster.
	var partial_2 := sin(TAU * frequency * 2.004 * t) * exp(-6.2 * t) * 0.24
	var partial_3 := sin(TAU * frequency * 3.016 * t) * exp(-9.0 * t) * 0.125
	var partial_4 := sin(TAU * frequency * 4.038 * t) * exp(-12.8 * t) * 0.064
	var partial_5 := sin(TAU * frequency * 5.070 * t) * exp(-17.5 * t) * 0.030
	var partial_6 := sin(TAU * frequency * 6.115 * t) * exp(-23.0 * t) * 0.012
	# Felt hammer noise gives a soft, detailed attack rather than a beep-like onset.
	var hammer := (sin(TAU * 2870.0 * t) * 0.48 + sin(TAU * 4310.0 * t) * 0.31 + sin(TAU * 6170.0 * t) * 0.21) * exp(-105.0 * t) * 0.075
	# Low soundboard modes add warmth and a wooden piano-body character.
	var body := sin(TAU * 118.0 * t) * exp(-5.8 * t) * 0.035
	body += sin(TAU * 226.0 * t) * exp(-7.0 * t) * 0.025
	body += sin(TAU * 347.0 * t) * exp(-8.5 * t) * 0.016
	var tone := fundamental + partial_2 + partial_3 + partial_4 + partial_5 + partial_6 + hammer + body
	return tone * attack * release * velocity

func _modern_pluck(frequency: float, local_t: float, velocity: float = 0.5, decay: float = 12.0) -> float:
	var t := maxf(local_t, 0.0)
	var bend := 0.42 * exp(-34.0 * t)
	var phase := TAU * frequency * t + bend * sin(TAU * frequency * 2.0 * t)
	var fundamental := sin(phase) * 0.72
	var octave := sin(TAU * frequency * 2.01 * t) * 0.19
	var shimmer := sin(TAU * frequency * 4.03 * t) * 0.07
	var transient := sin(TAU * 5800.0 * t) * exp(-95.0 * t) * 0.045
	var envelope := (1.0 - exp(-t * 1800.0)) * exp(-decay * t)
	return (fundamental + octave + shimmer + transient) * envelope * velocity

func _play_sfx(effect: String, note_index: int = 0, combo_index: int = 0) -> void:
	if not sound_enabled or not _sfx_players.has(effect):
		return
	var player: AudioStreamPlayer = _sfx_players[effect]
	player.stop()
	if effect == "place" or effect == "clear" or effect == "combo" or effect == "error":
		player.stream = _make_sfx_stream(effect, note_index, combo_index)
	player.play()

func _ready() -> void:
	Input.set_use_accumulated_input(false)
	font = ThemeDB.fallback_font
	_load_settings()
	_setup_audio()
	_setup_home_ui()
	_layout()
	queue_redraw()

func _process(delta: float) -> void:
	# Follow the most common block/tray color with a soft, cinematic transition.
	_theme_target = _dominant_board_color()
	var blend := 1.0 - exp(-delta * 2.6)
	var next_color := _theme_color.lerp(_theme_target, blend)
	var color_delta := maxf(maxf(absf(_theme_color.r - next_color.r), absf(_theme_color.g - next_color.g)), maxf(absf(_theme_color.b - next_color.b), absf(_theme_color.a - next_color.a)))
	if color_delta > 0.0015:
		_theme_color = next_color
		queue_redraw()

func _load_settings() -> void:
	config = ConfigFile.new()
	config.load("user://blocknova.cfg")
	best = int(config.get_value("records", "best", 0))
	sound_enabled = bool(config.get_value("settings", "sound", true))
	vibration_enabled = bool(config.get_value("settings", "vibration", true))

	if is_instance_valid(home_ui):
		home_ui.set("best_score", best)

func _setup_home_ui() -> void:
	var ui_script = load("res://scripts/home_screen.gd")
	home_ui = ui_script.new()
	home_ui.name = "ProfessionalHomeUI"
	add_child(home_ui)
	home_ui.set("best_score", best)
	home_ui.connect("play_requested", Callable(self, "_on_home_play"))
	home_ui.connect("settings_requested", Callable(self, "_on_home_settings"))

func _on_home_play() -> void:
	_play_sfx("ui")
	_reset_game()
	if is_instance_valid(home_ui):
		home_ui.call("set_ui_visible", false)

func _on_home_settings() -> void:
	_play_sfx("ui")
	screen = Screen.SETTINGS
	if is_instance_valid(home_ui):
		home_ui.call("set_ui_visible", false)
	queue_redraw()

func _save_settings() -> void:
	config.set_value("records", "best", best)
	config.set_value("settings", "sound", sound_enabled)
	config.set_value("settings", "vibration", vibration_enabled)
	config.save("user://blocknova.cfg")

func _layout() -> void:
	var w := size.x
	var h := size.y
	board_size = minf(w * 0.78, h * 0.38)
	cell = board_size / GRID
	board_origin = Vector2((w - board_size) * 0.5, h * 0.285)
	tray_y = h * 0.77

func _reset_game() -> void:
	board.clear()
	for y in range(GRID):
		var row: Array = []
		for x in range(GRID):
			row.append(-1)
		board.append(row)
	score = 0
	combo_streak = 0
	placement_note_index = 0
	selected = -1
	dragging = false
	game_over = false
	_new_pieces()
	screen = Screen.PLAYING
	queue_redraw()

func _new_pieces() -> void:
	pieces.clear()
	piece_colors.clear()
	for i in range(3):
		pieces.append(SHAPES[randi_range(0, SHAPES.size() - 1)].duplicate())
		piece_colors.append(COLORS[randi_range(0, COLORS.size() - 1)])
	if not _any_move():
		game_over = true
		_play_sfx("gameover")

func _draw() -> void:
	_layout()
	if is_instance_valid(home_ui):
		home_ui.call("set_ui_visible", screen == Screen.HOME)
	var w := size.x
	var h := size.y
	_draw_background()

	match screen:
		Screen.HOME:
			_draw_home()
		Screen.SETTINGS:
			_draw_settings()
		Screen.PLAYING:
			_draw_game()
		Screen.PAUSED:
			_draw_game()
			_draw_modal("PAUSED", "Take a breath. Your board is waiting.", "RESUME", "HOME")
	if screen == Screen.HOME:
		return

func _draw_home() -> void:
	if is_instance_valid(home_ui):
		return
	var w := size.x
	var h := size.y
	_draw_text("BLOCK", Vector2(0,h*0.27), 27, Color("#B85D27"), HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("NOVA", Vector2(0,h*0.35), 64, Color("#FFF8E8"), HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("THINK • PLACE • CLEAR", Vector2(0,h*0.395), 13, Color("#FFF0B0"), HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_logo_board(Vector2(w*0.5,h*0.56))
	_draw_button(Rect2(w*0.14,h*0.73,w*0.72,62),"PLAY",Color("#FF9F1C"))
	_draw_button(Rect2(w*0.14,h*0.815,w*0.72,54),"SETTINGS",Color("#159E8C"))
	_draw_text("BEST SCORE  "+str(best),Vector2(0,h*0.93),13,Color("#FFF0B0"),HORIZONTAL_ALIGNMENT_CENTER,w)

func _draw_logo_board(center: Vector2) -> void:
	if use_3d_visuals:
		return
	var unit := minf(size.x*0.105,42.0)
	var pattern := [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1),Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]
	for i in range(pattern.size()):
		var p := center+Vector2(pattern[i])*unit
		_draw_block(Rect2(p-Vector2(unit*0.43,unit*0.43),Vector2(unit-4,unit-4)),COLORS[i%COLORS.size()])

func _draw_settings() -> void:
	var w := size.x
	var h := size.y
	_draw_text("SETTINGS",Vector2(0,h*0.20),31,Color("#F3F6FF"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("MAKE THE EXPERIENCE YOURS",Vector2(0,h*0.235),11,Color("#8FA4C9"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_panel(Rect2(w*0.08,h*0.285,w*0.84,310),Color("#141F39"),24)
	_draw_text("HAPTIC FEEDBACK",Vector2(w*0.14,h*0.355),14,Color("#C7D2EA"))
	_draw_button(Rect2(w*0.66,h*0.33,w*0.20,42),"ON" if vibration_enabled else "OFF",Color("#27BBD4") if vibration_enabled else Color("#34415D"))
	_draw_text("SOUND & MUSIC",Vector2(w*0.14,h*0.445),14,Color("#C7D2EA"))
	_draw_button(Rect2(w*0.66,h*0.42,w*0.20,42),"ON" if sound_enabled else "OFF",Color("#8B6CFF") if sound_enabled else Color("#34415D"))
	_draw_text("Modern synth tones and ambient music",Vector2(0,h*0.505),11,Color("#8294B8"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("PERSONAL BEST     "+str(best),Vector2(0,h*0.625),15,Color("#F5D77B"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_button(Rect2(w*0.14,h*0.76,w*0.72,58),"BACK",Color("#8B6CFF"))

func _draw_game() -> void:
	var w := size.x
	var h := size.y
	_draw_text("BLOCK NOVA",Vector2(0,h*0.075),27,Color("#F3F6FF"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("PUZZLE  •  THINK  •  COMBO",Vector2(0,h*0.105),10,Color("#8FA4C9"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_panel(Rect2(22,h*0.135,w-44,72),Color("#141F39"),18)
	_draw_text("SCORE",Vector2(42,h*0.166),11,Color("#91A4C8"))
	_draw_text(str(score),Vector2(42,h*0.205),25,Color("#F3F6FF"))
	_draw_text("BEST  "+str(max(best,score)),Vector2(w-150,h*0.19),15,Color("#F5D77B"))
	if combo_streak > 0:
		_draw_text("COMBO x"+str(combo_streak),Vector2(w*0.43,h*0.205),13,Color("#32E6D1"))
	_draw_button(Rect2(w-65,18,44,38),"Ⅱ",Color("#805BFF"))
	_draw_text("YOUR BOARD",Vector2(board_origin.x,board_origin.y-24),12,Color("#34DDF0"))
	_draw_text("CHOOSE A SHAPE",Vector2(0,tray_y-26),12,Color("#A8B6D4"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("DRAG A SHAPE  •  CLEAR ROWS & COLUMNS",Vector2(0,h*0.94),10,Color("#7F91B6"),HORIZONTAL_ALIGNMENT_CENTER,w)
	if game_over:
		_draw_modal("NO MORE MOVES","Final score: "+str(score),"PLAY AGAIN","HOME")

func _draw_modal(heading: String, subtitle: String, primary: String, secondary: String) -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.06,0.78))
	_draw_panel(Rect2(28,h*0.36,w-56,250),Color("#17223D"),22)
	_draw_text(heading,Vector2(0,h*0.43),24,Color("#F3F6FF"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text(subtitle,Vector2(0,h*0.48),13,Color("#A9B7D4"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_button(Rect2(w*0.20,h*0.53,w*0.60,48),primary,Color("#27CFE8"))
	_draw_button(Rect2(w*0.20,h*0.59,w*0.60,42),secondary,Color("#805BFF"))

func _dominant_board_color() -> Color:
	var counts: Array[int] = []
	for i in range(COLORS.size()):
		counts.append(0)
	if board.size() == GRID:
		for row in board:
			if row is Array:
				for value in row:
					var index := int(value)
					if index >= 0 and index < counts.size():
						counts[index] += 1
	# When the board is empty, theme the screen around the strongest color in the current tray.
	if counts.max() == 0:
		for value in piece_colors:
			for i in range(COLORS.size()):
				if value is Color and value.is_equal_approx(COLORS[i]):
					counts[i] += 1
	var dominant_index := 0
	for i in range(1, counts.size()):
		if counts[i] > counts[dominant_index]:
			dominant_index = i
	return COLORS[dominant_index]

func _draw_background() -> void:
	var menu_screen := screen == Screen.HOME or screen == Screen.SETTINGS
	var tint := _theme_color
	# Keep the interface dark and legible while letting the dominant block hue
	# subtly recolor the entire atmosphere.
	var top_base := Color("#080D1C") if not menu_screen else Color("#0B1024")
	var bottom_base := Color("#111A32") if not menu_screen else Color("#171A38")
	var top_color := top_base.lerp(tint.darkened(0.66), 0.24)
	var bottom_color := bottom_base.lerp(tint.darkened(0.54), 0.34)
	var bands := 88
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / float(bands) + 2.0), top_color.lerp(bottom_color, t))
	# Large, blurred-feeling color pools track the dominant block hue.
	var glow := Color(tint.r, tint.g, tint.b, 0.105)
	var secondary_glow := Color(tint.r, tint.g, tint.b, 0.055)
	draw_circle(Vector2(size.x * 0.08, size.y * 0.22), size.x * 0.54, glow)
	draw_circle(Vector2(size.x * 0.92, size.y * 0.72), size.x * 0.58, Color(tint.lightened(0.18).r, tint.lightened(0.18).g, tint.lightened(0.18).b, 0.075))
	draw_circle(Vector2(size.x * 0.52, size.y * 0.48), size.x * 0.34, secondary_glow)
	# Fine particles pick up a hint of the active hue, without reducing contrast.
	for i in range(34):
		var px := fmod(float(i) * 83.0 + 23.0, size.x)
		var py := fmod(float(i) * 137.0 + 61.0, size.y)
		var alpha := 0.18 if i % 3 == 0 else 0.08
		draw_circle(Vector2(px, py), 1.2 if i % 4 == 0 else 0.8, Color(tint.r, tint.g, tint.b, alpha))
	# A subtle luminous line echoes the dominant block color.
	if not menu_screen:
		draw_line(Vector2(size.x * 0.08, size.y * 0.12), Vector2(size.x * 0.92, size.y * 0.12), Color(tint.r, tint.g, tint.b, 0.22), 1.2, true)

func _draw_panel(rect: Rect2,color: Color,radius: float) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color("#070B18")
	shadow.set_corner_radius_all(int(radius))
	shadow.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	shadow.shadow_size = 12
	shadow.shadow_offset = Vector2(0, 7)
	draw_style_box(shadow, rect)
	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.set_corner_radius_all(int(radius))
	panel.set_border_width_all(1)
	panel.border_color = Color("#344568")
	draw_style_box(panel, rect)
	draw_line(rect.position + Vector2(radius, 1.5), Vector2(rect.end.x - radius, rect.position.y + 1.5), Color(0.62, 0.86, 1.0, 0.12), 1.5, true)

func _draw_button(rect: Rect2,label: String,color: Color) -> void:
	_draw_panel(rect, color, 18)
	var sheen := StyleBoxFlat.new()
	sheen.bg_color = Color(1, 1, 1, 0.12)
	sheen.set_corner_radius_all(14)
	draw_style_box(sheen, Rect2(rect.position + Vector2(5, 4), Vector2(rect.size.x - 10, rect.size.y * 0.32)))
	_draw_text(label,Vector2(0,rect.position.y+rect.size.y*0.62),15,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,size.x)

func _draw_text(value: String,pos: Vector2,font_size: int,color: Color,align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT,width: float=-1.0) -> void:
	var text_width := width if width > 0 else 300.0
	draw_string(font, pos + Vector2(0, 2), value, align, text_width, font_size, Color(0.12, 0.16, 0.22, 0.22))
	draw_string(font,pos,value,align,text_width,font_size,color)

func _input(event: InputEvent) -> void:
	if screen == Screen.HOME and is_instance_valid(home_ui):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_down(event.position)
		else:
			_pointer_up(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down(event.position)
		else:
			_pointer_up(event.position)
	elif event is InputEventScreenDrag:
		if screen == Screen.PLAYING and selected >= 0 and selected < pieces.size() and not pieces[selected].is_empty():
			pointer=event.position
			dragging=true
			queue_redraw()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if screen == Screen.PLAYING and selected >= 0 and selected < pieces.size() and not pieces[selected].is_empty():
			pointer=event.position
			dragging=true
			queue_redraw()

func _pointer_down(pos: Vector2) -> void:
	pointer=pos
	var w := size.x
	var h := size.y
	match screen:
		Screen.HOME:
			if pos.y >= h*0.70 and pos.y <= h*0.80:
				_reset_game()
			elif pos.y >= h*0.80 and pos.y <= h*0.90:
				screen=Screen.SETTINGS
			queue_redraw()
			return
		Screen.SETTINGS:
			if pos.y >= h*0.32 and pos.y <= h*0.40 and pos.x >= w*0.60:
				_play_sfx("ui")
				vibration_enabled = not vibration_enabled
			elif pos.y >= h*0.41 and pos.y <= h*0.49 and pos.x >= w*0.60:
				_play_sfx("ui")
				sound_enabled = not sound_enabled
			elif pos.y >= h*0.73:
				_play_sfx("ui")
				screen=Screen.HOME
			_save_settings()
			_update_music_state()
			queue_redraw()
			return
		Screen.PAUSED:
			if pos.y >= h*0.52 and pos.y <= h*0.59:
				_play_sfx("ui")
				screen=Screen.PLAYING
			elif pos.y >= h*0.59 and pos.y <= h*0.67:
				_play_sfx("ui")
				screen=Screen.HOME
				selected=-1
			queue_redraw()
			return
		Screen.PLAYING:
			if game_over:
				if pos.y >= h*0.52 and pos.y <= h*0.59:
					_play_sfx("ui")
					_reset_game()
				elif pos.y >= h*0.59 and pos.y <= h*0.67:
					_play_sfx("ui")
					screen=Screen.HOME
				queue_redraw()
				return
			if pos.x >= w-78 and pos.y < 70:
				_play_sfx("ui")
				screen=Screen.PAUSED
				queue_redraw()
				return
			var center_y := tray_y+55
			for i in range(3):
				var center_x := w*(float(i)+0.5)/3.0
				if pos.distance_to(Vector2(center_x,center_y)) < 82 and not pieces[i].is_empty():
					selected=i
					_play_sfx("pickup")
					drag_cell_offset = _piece_cell_under_finger(i, pos)
					dragging=true
					queue_redraw()
					return
			if selected >= 0 and _inside_board(pos):
				_try_place(_cell_at(pos))

func _pointer_up(pos: Vector2) -> void:
	pointer=pos
	if screen == Screen.PLAYING and dragging and selected >= 0:
		if _inside_board(pos):
			_try_place(_cell_at(pos) - drag_cell_offset)
		else:
			# Releasing outside the board cancels the move instead of leaving a stale selection.
			selected = -1
	dragging=false
	drag_cell_offset = Vector2i.ZERO
	queue_redraw()

func _piece_cell_under_finger(piece_index: int, pos: Vector2) -> Vector2i:
	if piece_index < 0 or piece_index >= pieces.size() or pieces[piece_index].is_empty():
		return Vector2i.ZERO
	var shape: Array = pieces[piece_index]
	var minp := Vector2i(99, 99)
	var maxp := Vector2i.ZERO
	for c in shape:
		minp.x = mini(minp.x, c.x)
		minp.y = mini(minp.y, c.y)
		maxp.x = maxi(maxp.x, c.x)
		maxp.y = maxi(maxp.y, c.y)
	var unit := minf(20.0, 66.0 / float(maxi(maxp.x - minp.x + 1, maxp.y - minp.y + 1)))
	var center := Vector2(size.x * (float(piece_index) + 0.5) / 3.0, tray_y + 55)
	var origin := center - Vector2((maxp.x - minp.x + 1) * unit, (maxp.y - minp.y + 1) * unit) * 0.5
	var nearest := Vector2i.ZERO
	var nearest_distance := INF
	for c in shape:
		var block_center := origin + Vector2(c - minp) * unit + Vector2(unit * 0.5, unit * 0.5)
		var distance := pos.distance_squared_to(block_center)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = c
	return nearest

func _inside_board(pos: Vector2) -> bool:
	return pos.x>=board_origin.x and pos.y>=board_origin.y and pos.x<board_origin.x+board_size and pos.y<board_origin.y+board_size

func _cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori((pos.x-board_origin.x)/cell),floori((pos.y-board_origin.y)/cell))

func _can_place(shape: Array,at: Vector2i) -> bool:
	# Never index the board until its dimensions have been verified.
	if board.size() != GRID or shape.is_empty():
		return false
	for y in range(GRID):
		if not (board[y] is Array) or board[y].size() != GRID:
			return false
	for c in shape:
		var x: int = at.x + c.x
		var y: int = at.y + c.y
		if x < 0 or y < 0 or x >= GRID or y >= GRID:
			return false
		if int(board[y][x]) != -1:
			return false
	return true

func _try_place(at: Vector2i) -> void:
	if selected < 0 or selected >= pieces.size() or selected >= piece_colors.size() or pieces[selected].is_empty():
		return
	var shape: Array=pieces[selected]
	if not _can_place(shape,at):
		_play_sfx("error")
		return
	# Validate the board before writing to avoid invalid Android grid access.
	if board.size() != GRID:
		return
	for y in range(GRID):
		if not (board[y] is Array) or board[y].size() != GRID:
			return
	var color_index := 0
	for i in range(COLORS.size()):
		if piece_colors[selected].is_equal_approx(COLORS[i]):
			color_index = i
			break
	for c in shape:
		var target_y: int = at.y + c.y
		var target_x: int = at.x + c.x
		if target_y < 0 or target_y >= GRID or target_x < 0 or target_x >= GRID:
			return
		var row: Array = board[target_y]
		row[target_x] = color_index
		board[target_y] = row
	score += shape.size() * 5
	_play_sfx("place", placement_note_index)
	placement_note_index = (placement_note_index + 1) % 12
	pieces[selected]=[]
	selected=-1
	var cleared := _clear_lines()
	if cleared > 0:
		_play_sfx("combo" if cleared >= 2 or combo_streak >= 1 else "clear", 0, combo_streak)
		combo_streak += 1
		score += 75 * combo_streak
	else:
		combo_streak = 0
	if score>best:
		best=score
		_save_settings()
		if is_instance_valid(home_ui):
			home_ui.call("set_best_score", best)
	# Temporarily disable Android haptics while isolating the placement crash.
	# Keep board placement independent from device vibrator APIs.
	if _all_pieces_used():
		_new_pieces()
	elif not _any_move():
		game_over=true
		_play_sfx("gameover")
	queue_redraw()

func _clear_lines() -> int:
	if board.size() != GRID:
		return 0
	for y in range(GRID):
		if not (board[y] is Array) or board[y].size() != GRID:
			return 0
	var rows: Array[int]=[]
	var cols: Array[int]=[]
	for y in range(GRID):
		var full=true
		for x in range(GRID):
			if board[y][x]==-1:
				full=false
				break
		if full:
			rows.append(y)
	for x in range(GRID):
		var full=true
		for y in range(GRID):
			if board[y][x]==-1:
				full=false
				break
		if full:
			cols.append(x)
	for y in rows:
		for x in range(GRID):
			board[y][x]=-1
	for x in cols:
		for y in range(GRID):
			board[y][x]=-1
	var cleared=rows.size()+cols.size()
	if cleared>0:
		score+=cleared*cleared*100
		if cleared>=2:
			score+=cleared*75
	return cleared

func _any_move() -> bool:
	if board.size() != GRID:
		return false
	for y in range(GRID):
		if not (board[y] is Array) or board[y].size() != GRID:
			return false
	for shape in pieces:
		if shape.is_empty():
			continue
		for y in range(GRID):
			for x in range(GRID):
				if _can_place(shape,Vector2i(x,y)):
					return true
	return false

func _all_pieces_used() -> bool:
	for piece in pieces:
		if not piece.is_empty():
			return false
	return true

func _draw_block(rect: Rect2, color: Color) -> void:
	# Retained only for the non-gameplay home logo fallback; the board itself is rendered in 3D.
	draw_rect(rect, color, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), color.lightened(0.28), true)