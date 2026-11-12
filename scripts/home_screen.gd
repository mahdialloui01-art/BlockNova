extends CanvasLayer

signal play_requested
signal settings_requested
signal daily_challenge_requested

var best_score: int = 0
var _best_label: Label
var _root_control: Control

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
	feature.text = "3D BLOCKS     •     SMART COMBOS     •     ENDLESS PLAY"
	feature.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feature.add_theme_font_size_override("font_size", 10)
	feature.add_theme_color_override("font_color", Color("#9AA9CE"))
	feature.anchor_left = 0.04
	feature.anchor_right = 0.96
	feature.anchor_top = 0.66
	feature.anchor_bottom = 0.695
	root.add_child(feature)

	var play := _make_button("▶   PLAY NOW", CYAN, Color("#138FAE"), Color("#071B30"))
	play.anchor_left = 0.11
	play.anchor_right = 0.89
	play.anchor_top = 0.725
	play.anchor_bottom = 0.785
	play.pressed.connect(func(): play_requested.emit())
	root.add_child(play)

	var daily := _make_button("✦   DAILY CHALLENGE", Color("#35D6A5"), Color("#1A9275"), Color("#062A29"))
	daily.name = "DailyChallengeButton"
	daily.anchor_left = 0.11
	daily.anchor_right = 0.89
	daily.anchor_top = 0.79
	daily.anchor_bottom = 0.845
	daily.pressed.connect(func(): daily_challenge_requested.emit())
	root.add_child(daily)

	var settings := _make_button("⚙   SETTINGS", VIOLET, Color("#5840B4"), Color.WHITE)
	settings.anchor_left = 0.11
	settings.anchor_right = 0.89
	settings.anchor_top = 0.855
	settings.anchor_bottom = 0.91
	settings.pressed.connect(func(): settings_requested.emit())
	root.add_child(settings)

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

func set_ui_visible(value: bool) -> void:
	if is_instance_valid(_root_control):
		_root_control.visible = value
