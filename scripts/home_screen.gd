extends CanvasLayer

signal play_requested
signal settings_requested
signal daily_challenge_requested
signal weekly_challenge_requested
signal resume_requested

var best_score: int = 0
var _best_label: Label
var _root_control: Control
var _resume_button: Button
var _play_button: Button
var _daily_button: Button
var _weekly_button: Button
var _settings_button: Button
var _best_panel: PanelContainer
var _daily_streak_label: Label
var _daily_rewards_button: Button
var _daily_rewards_overlay: Control
var _daily_rewards_detail: Label
var _daily_reward_labels: Dictionary = {}
var _player_stats_button: Button
var _player_stats_overlay: Control
var _player_stats_labels: Dictionary = {}
var lifetime_games_finished: int = 0
var lifetime_pieces_placed: int = 0
var lifetime_lines_cleared: int = 0
var lifetime_total_score: int = 0
var lifetime_best_combo: int = 0
var daily_streak: int = 0
var daily_best_streak: int = 0

const INK := Color("#F3F6FF")
const MUTED := Color("#A9B5D2")
const CYAN := Color("#28DDF2")
const VIOLET := Color("#805BFF")
const PANEL := Color("#141D35")

func _ready() -> void:
	layer = 20
	_build()

func _build() -> void:
	var root := Control.new()
	_root_control = root
	root.name = "FullScreenHome"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var eyebrow := Label.new()
	eyebrow.text = "✦  PUZZLE STUDIO  /  2026"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", CYAN)
	eyebrow.anchor_left = 0.08
	eyebrow.anchor_right = 0.92
	eyebrow.anchor_top = 0.145
	eyebrow.anchor_bottom = 0.18
	root.add_child(eyebrow)

	var title := Label.new()
	title.text = "BLOCK NOVA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", INK)
	title.add_theme_color_override("font_shadow_color", Color(0.10, 0.80, 1.0, 0.24))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.anchor_left = 0.04
	title.anchor_right = 0.96
	title.anchor_top = 0.205
	title.anchor_bottom = 0.275
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A NEW DIMENSION OF PUZZLE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.anchor_left = 0.08
	subtitle.anchor_right = 0.92
	subtitle.anchor_top = 0.282
	subtitle.anchor_bottom = 0.315
	root.add_child(subtitle)

	var feature := Label.new()
	feature.text = "3D BLOCKS     •     SMART COMBOS"
	feature.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feature.add_theme_font_size_override("font_size", 10)
	feature.add_theme_color_override("font_color", Color("#9AA9CE"))
	feature.anchor_left = 0.04
	feature.anchor_right = 0.64
	feature.anchor_top = 0.625
	feature.anchor_bottom = 0.655
	root.add_child(feature)

	var stats := _make_button("▦  PLAYER STATS", Color("#1B2945"), Color("#3D5C82"), INK)
	stats.name = "PlayerStatsButton"
	stats.anchor_left = 0.67
	stats.anchor_right = 0.95
	stats.anchor_top = 0.625
	stats.anchor_bottom = 0.655
	stats.add_theme_font_size_override("font_size", 10)
	stats.pressed.connect(_open_player_stats)
	root.add_child(stats)
	_player_stats_button = stats

	var streak := Label.new()
	streak.name = "DailyStreakLabel"
	streak.text = "✦  STREAK 0D  •  BEST 0D"
	streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak.add_theme_font_size_override("font_size", 11)
	streak.add_theme_color_override("font_color", Color("#F5D77B"))
	streak.anchor_left = 0.05
	streak.anchor_right = 0.66
	streak.anchor_top = 0.66
	streak.anchor_bottom = 0.695
	root.add_child(streak)
	_daily_streak_label = streak

	var rewards := _make_button("✦  REWARDS 0/3", Color("#F5D77B"), Color("#A77E2B"), Color("#241A05"))
	rewards.name = "DailyRewardsButton"
	rewards.anchor_left = 0.68
	rewards.anchor_right = 0.95
	rewards.anchor_top = 0.66
	rewards.anchor_bottom = 0.695
	rewards.add_theme_font_size_override("font_size", 10)
	rewards.pressed.connect(_open_daily_rewards)
	root.add_child(rewards)
	_daily_rewards_button = rewards

	var resume := _make_button("↻   RESUME LAST GAME", Color("#FFC857"), Color("#B78328"), Color("#241A05"))
	resume.name = "ResumeButton"
	resume.pressed.connect(func(): resume_requested.emit())
	root.add_child(resume)
	_resume_button = resume

	var play := _make_button("▶   PLAY NOW", CYAN, Color("#138FAE"), Color("#071B30"))
	play.anchor_left = 0.11
	play.anchor_right = 0.89
	play.anchor_top = 0.725
	play.anchor_bottom = 0.785
	play.pressed.connect(func(): play_requested.emit())
	root.add_child(play)
	_play_button = play

	var daily := _make_button("✦   DAILY CHALLENGE", Color("#35D6A5"), Color("#1A9275"), Color("#062A29"))
	daily.name = "DailyChallengeButton"
	daily.anchor_left = 0.11
	daily.anchor_right = 0.89
	daily.anchor_top = 0.79
	daily.anchor_bottom = 0.845
	daily.pressed.connect(func(): daily_challenge_requested.emit())
	root.add_child(daily)
	_daily_button = daily

	var weekly := _make_button("✧   WEEKLY CHALLENGE", Color("#A78BFA"), Color("#6D55C6"), Color("#160E35"))
	weekly.name = "WeeklyChallengeButton"
	weekly.anchor_left = 0.11
	weekly.anchor_right = 0.89
	weekly.anchor_top = 0.85
	weekly.anchor_bottom = 0.90
	weekly.pressed.connect(func(): weekly_challenge_requested.emit())
	root.add_child(weekly)
	_weekly_button = weekly

	var settings := _make_button("⚙   SETTINGS", VIOLET, Color("#5840B4"), Color.WHITE)
	settings.anchor_left = 0.11
	settings.anchor_right = 0.89
	settings.anchor_top = 0.91
	settings.anchor_bottom = 0.96
	settings.pressed.connect(func(): settings_requested.emit())
	root.add_child(settings)
	_settings_button = settings

	var best_panel := PanelContainer.new()
	best_panel.anchor_left = 0.22
	best_panel.anchor_right = 0.78
	best_panel.anchor_top = 0.92
	best_panel.anchor_bottom = 0.975
	best_panel.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("#344568"), 18, 1))
	root.add_child(best_panel)

	_best_label = Label.new()
	_best_label.text = "✦  PERSONAL BEST     %s" % best_score
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override("font_size", 14)
	_best_label.add_theme_color_override("font_color", Color("#F5D77B"))
	best_panel.add_child(_best_label)
	_best_panel = best_panel
	_layout_action_buttons()
	_build_daily_rewards_overlay(root)
	_build_player_stats_overlay(root)

func _build_daily_rewards_overlay(root: Control) -> void:
	var overlay := Control.new()
	overlay.name = "DailyRewardsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	root.add_child(overlay)
	_daily_rewards_overlay = overlay

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.025, 0.055, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.name = "DailyRewardsPanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.315
	panel.anchor_bottom = 0.685
	var panel_style := _panel_style(PANEL, Color("#52658F"), 24, 2)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "DAILY REWARDS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", INK)
	content.add_child(heading)

	var detail := Label.new()
	detail.name = "DailyRewardsDetail"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", MUTED)
	content.add_child(detail)
	_daily_rewards_detail = detail

	for reward in [
		{"days": 3, "title": "FIRST SPARK"},
		{"days": 7, "title": "NOVA KEEPER"},
		{"days": 30, "title": "CONSTELLATION"}
	]:
		var milestone := int(reward["days"])
		var row := Label.new()
		row.name = "DailyReward%dLabel" % milestone
		row.add_theme_font_size_override("font_size", 14)
		row.add_theme_color_override("font_color", MUTED)
		content.add_child(row)
		_daily_reward_labels[milestone] = row

	var close := _make_button("CLOSE", VIOLET, Color("#5840B4"), Color.WHITE)
	close.name = "DailyRewardsCloseButton"
	close.custom_minimum_size = Vector2(0, 48)
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(_close_daily_rewards)
	content.add_child(close)
	_refresh_daily_rewards()

func _open_daily_rewards() -> void:
	_close_player_stats()
	_refresh_daily_rewards()
	if is_instance_valid(_daily_rewards_overlay):
		_daily_rewards_overlay.visible = true

func _close_daily_rewards() -> void:
	if is_instance_valid(_daily_rewards_overlay):
		_daily_rewards_overlay.visible = false

func _refresh_daily_rewards() -> void:
	var unlocked := int(daily_best_streak >= 3) + int(daily_best_streak >= 7) + int(daily_best_streak >= 30)
	if is_instance_valid(_daily_rewards_button):
		_daily_rewards_button.text = "✦  REWARDS %d/3" % unlocked
	if is_instance_valid(_daily_rewards_detail):
		_daily_rewards_detail.text = "CURRENT %d DAYS   •   PERSONAL BEST %d DAYS" % [daily_streak, daily_best_streak]
	var reward_titles := {3: "FIRST SPARK", 7: "NOVA KEEPER", 30: "CONSTELLATION"}
	for milestone in [3, 7, 30]:
		var row := _daily_reward_labels.get(milestone) as Label
		if not is_instance_valid(row):
			continue
		if daily_best_streak >= milestone:
			row.text = "✓  %d DAYS  •  %s  •  UNLOCKED" % [milestone, reward_titles[milestone]]
			row.add_theme_color_override("font_color", Color("#35D6A5"))
		else:
			row.text = "○  %d DAYS  •  %s  •  %d/%d" % [milestone, reward_titles[milestone], mini(daily_best_streak, milestone), milestone]
			row.add_theme_color_override("font_color", MUTED)

func _build_player_stats_overlay(root: Control) -> void:
	var overlay := Control.new()
	overlay.name = "PlayerStatsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	root.add_child(overlay)
	_player_stats_overlay = overlay

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.025, 0.055, 0.84)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.name = "PlayerStatsPanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.245
	panel.anchor_bottom = 0.755
	var panel_style := _panel_style(PANEL, Color("#52658F"), 24, 2)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 22
	panel_style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "PLAYER RECORD"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", INK)
	content.add_child(heading)

	var detail := Label.new()
	detail.text = "LIFETIME PERFORMANCE  •  THIS DEVICE"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 11)
	detail.add_theme_color_override("font_color", MUTED)
	content.add_child(detail)

	for stat in [
		{"key": "games", "node": "PlayerStatGamesLabel", "title": "GAMES FINISHED"},
		{"key": "pieces", "node": "PlayerStatPiecesLabel", "title": "PIECES PLACED"},
		{"key": "lines", "node": "PlayerStatLinesLabel", "title": "LINES CLEARED"},
		{"key": "score", "node": "PlayerStatScoreLabel", "title": "TOTAL SCORE"},
		{"key": "combo", "node": "PlayerStatComboLabel", "title": "BEST COMBO"}
	]:
		var row := Label.new()
		row.name = str(stat["node"])
		row.custom_minimum_size = Vector2(0, 34)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", MUTED)
		content.add_child(row)
		_player_stats_labels[str(stat["key"])] = row

	var close := _make_button("CLOSE", VIOLET, Color("#5840B4"), Color.WHITE)
	close.name = "PlayerStatsCloseButton"
	close.custom_minimum_size = Vector2(0, 48)
	close.add_theme_font_size_override("font_size", 14)
	close.pressed.connect(_close_player_stats)
	content.add_child(close)
	_refresh_player_stats()

func _open_player_stats() -> void:
	_close_daily_rewards()
	_refresh_player_stats()
	if is_instance_valid(_player_stats_overlay):
		_player_stats_overlay.visible = true

func _close_player_stats() -> void:
	if is_instance_valid(_player_stats_overlay):
		_player_stats_overlay.visible = false

func _refresh_player_stats() -> void:
	var values := {
		"games": lifetime_games_finished,
		"pieces": lifetime_pieces_placed,
		"lines": lifetime_lines_cleared,
		"score": lifetime_total_score,
		"combo": lifetime_best_combo
	}
	var titles := {
		"games": "GAMES FINISHED",
		"pieces": "PIECES PLACED",
		"lines": "LINES CLEARED",
		"score": "TOTAL SCORE",
		"combo": "BEST COMBO"
	}
	for key in values:
		var row := _player_stats_labels.get(key) as Label
		if not is_instance_valid(row):
			continue
		var value_text := "x%d" % int(values[key]) if key == "combo" else str(values[key])
		row.text = "%s   •   %s" % [titles[key], value_text]

func _layout_action_buttons() -> void:
	if not is_instance_valid(_play_button) or not is_instance_valid(_weekly_button) or not is_instance_valid(_best_panel):
		return
	var has_resume := is_instance_valid(_resume_button) and _resume_button.visible
	if has_resume:
		_resume_button.anchor_top = 0.700
		_resume_button.anchor_bottom = 0.738
		_play_button.anchor_top = 0.741
		_play_button.anchor_bottom = 0.784
		_daily_button.anchor_top = 0.787
		_daily_button.anchor_bottom = 0.830
		_weekly_button.anchor_top = 0.833
		_weekly_button.anchor_bottom = 0.876
		_settings_button.anchor_top = 0.879
		_settings_button.anchor_bottom = 0.922
		_best_panel.anchor_top = 0.935
		_best_panel.anchor_bottom = 0.985
	else:
		_play_button.anchor_top = 0.690
		_play_button.anchor_bottom = 0.745
		_daily_button.anchor_top = 0.750
		_daily_button.anchor_bottom = 0.805
		_weekly_button.anchor_top = 0.810
		_weekly_button.anchor_bottom = 0.865
		_settings_button.anchor_top = 0.870
		_settings_button.anchor_bottom = 0.925
		_best_panel.anchor_top = 0.935
		_best_panel.anchor_bottom = 0.985

func set_resume_available(value: bool) -> void:
	if is_instance_valid(_resume_button):
		_resume_button.visible = value
		_layout_action_buttons()

func _make_button(caption: String, fill: Color, border: Color, text_color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 22, 2))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.10), border.lightened(0.10), 22, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.12), border.darkened(0.12), 22, 2))
	button.add_theme_stylebox_override("focus", _panel_style(fill, border, 22, 2))
	return button

func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func set_best_score(value: int) -> void:
	best_score = value
	if is_instance_valid(_best_label):
		_best_label.text = "✦  PERSONAL BEST     %s" % best_score

func set_lifetime_stats(games_finished: int, pieces_placed: int, lines_cleared: int, total_score: int, best_combo: int) -> void:
	lifetime_games_finished = maxi(games_finished, 0)
	lifetime_pieces_placed = maxi(pieces_placed, 0)
	lifetime_lines_cleared = maxi(lines_cleared, 0)
	lifetime_total_score = maxi(total_score, 0)
	lifetime_best_combo = maxi(best_combo, 0)
	_refresh_player_stats()

func set_daily_progress(current_streak: int, best_streak: int) -> void:
	daily_streak = maxi(current_streak, 0)
	daily_best_streak = maxi(maxi(best_streak, 0), daily_streak)
	if is_instance_valid(_daily_streak_label):
		_daily_streak_label.text = "✦  STREAK %dD  •  BEST %dD" % [daily_streak, daily_best_streak]
	_refresh_daily_rewards()

func set_daily_streak(value: int) -> void:
	# Keep the original setter available for existing callers and older tests.
	set_daily_progress(value, daily_best_streak)

func set_ui_visible(value: bool) -> void:
	if not value:
		_close_daily_rewards()
		_close_player_stats()
	if is_instance_valid(_root_control):
		_root_control.visible = value
