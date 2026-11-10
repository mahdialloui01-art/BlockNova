extends CanvasLayer

signal play_requested
signal settings_requested

var best_score: int = 0
var _best_label: Label

const INK := Color("#263B4D")
const MUTED := Color("#6D7D86")
const CREAM := Color("#FFF9EC")
const ORANGE := Color("#F28A32")
const TEAL := Color("#258C83")

func _ready() -> void:
	layer = 20
	_build()

func _build() -> void:
	var root := Control.new()
	root.name = "FullScreenHome"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var brand := Label.new()
	brand.text = "A LITTLE SPACE TO THINK"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 15)
	brand.add_theme_color_override("font_color", Color("#A65B32"))
	brand.anchor_left = 0.08
	brand.anchor_right = 0.92
	brand.anchor_top = 0.205
	brand.anchor_bottom = 0.235
	root.add_child(brand)

	var title := Label.new()
	title.text = "BLOCK NOVA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 47)
	title.add_theme_color_override("font_color", INK)
	title.add_theme_color_override("font_shadow_color", Color(0.28, 0.19, 0.12, 0.20))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.anchor_left = 0.05
	title.anchor_right = 0.95
	title.anchor_top = 0.245
	title.anchor_bottom = 0.295
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "THINK  ·  PLACE  ·  CLEAR"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.anchor_left = 0.08
	subtitle.anchor_right = 0.92
	subtitle.anchor_top = 0.30
	subtitle.anchor_bottom = 0.33
	root.add_child(subtitle)

	var play := _make_button("PLAY", ORANGE, Color("#C96C22"))
	play.anchor_left = 0.13
	play.anchor_right = 0.87
	play.anchor_top = 0.735
	play.anchor_bottom = 0.785
	play.pressed.connect(func(): play_requested.emit())
	root.add_child(play)

	var settings := _make_button("SETTINGS", TEAL, Color("#176B67"))
	settings.anchor_left = 0.13
	settings.anchor_right = 0.87
	settings.anchor_top = 0.805
	settings.anchor_bottom = 0.85
	settings.pressed.connect(func(): settings_requested.emit())
	root.add_child(settings)

	var best_panel := PanelContainer.new()
	best_panel.anchor_left = 0.25
	best_panel.anchor_right = 0.75
	best_panel.anchor_top = 0.895
	best_panel.anchor_bottom = 0.945
	best_panel.add_theme_stylebox_override("panel", _panel_style(Color(1.0, 0.97, 0.88, 0.88), Color("#E3C9A5"), 18, 1))
	root.add_child(best_panel)

	_best_label = Label.new()
	_best_label.text = "BEST SCORE     %s" % best_score
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override("font_size", 15)
	_best_label.add_theme_color_override("font_color", INK)
	best_panel.add_child(_best_label)

func _make_button(caption: String, fill: Color, border: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#FFF3DC"))
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 22, 2))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.08), border.lightened(0.08), 22, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.10), border.darkened(0.10), 22, 2))
	button.add_theme_stylebox_override("focus", _panel_style(fill, border, 22, 2))
	return button

func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	style.shadow_color = Color(0.20, 0.25, 0.26, 0.20)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func set_best_score(value: int) -> void:
	best_score = value
	if is_instance_valid(_best_label):
		_best_label.text = "BEST SCORE     %s" % best_score
