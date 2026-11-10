extends Control

const GRID := 8
const COLORS := [
	Color("#48D7F2"), Color("#FFB84D"), Color("#A78BFA"),
	Color("#62E6A5"), Color("#FF6F91"), Color("#F5E96B")
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

func _ready() -> void:
	Input.set_use_accumulated_input(false)
	font = ThemeDB.fallback_font
	_load_settings()
	_setup_home_ui()
	_layout()
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
	_reset_game()
	if is_instance_valid(home_ui):
		home_ui.call("set_ui_visible", false)

func _on_home_settings() -> void:
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
	_draw_text("SETTINGS",Vector2(0,h*0.20),31,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_panel(Rect2(w*0.08,h*0.285,w*0.84,270),Color("#182943"),24)
	_draw_text("HAPTIC FEEDBACK",Vector2(w*0.14,h*0.355),14,Color("#EAF0FF"))
	_draw_button(Rect2(w*0.66,h*0.33,w*0.20,42),"ON" if vibration_enabled else "OFF",Color("#287E78") if vibration_enabled else Color("#39445C"))
	_draw_text("SOUND",Vector2(w*0.14,h*0.445),14,Color("#EAF0FF"))
	_draw_button(Rect2(w*0.66,h*0.42,w*0.20,42),"ON" if sound_enabled else "OFF",Color("#287E78") if sound_enabled else Color("#39445C"))
	_draw_text("Your preferences are saved on this device",Vector2(0,h*0.505),11,Color("#91A4BC"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("PERSONAL BEST     "+str(best),Vector2(0,h*0.625),15,Color("#FFD477"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_button(Rect2(w*0.14,h*0.76,w*0.72,58),"BACK",Color("#6658E8"))

func _draw_game() -> void:
	var w := size.x
	var h := size.y
	_draw_text("BLOCK NOVA",Vector2(0,h*0.075),27,Color("#F5F8FF"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("PUZZLE  •  THINK  •  COMBO",Vector2(0,h*0.105),10,Color("#7E91B8"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_panel(Rect2(22,h*0.135,w-44,72),Color("#151F38"),18)
	_draw_text("SCORE",Vector2(42,h*0.166),11,Color("#8EA2CA"))
	_draw_text(str(score),Vector2(42,h*0.205),25,Color.WHITE)
	_draw_text("BEST  "+str(max(best,score)),Vector2(w-150,h*0.19),15,Color("#FFD477"))
	if combo_streak > 0:
		_draw_text("COMBO x"+str(combo_streak),Vector2(w*0.43,h*0.205),13,Color("#48D7F2"))
	_draw_button(Rect2(w-65,18,44,38),"Ⅱ",Color("#26385B"))
	_draw_text("YOUR BOARD",Vector2(board_origin.x,board_origin.y-24),12,Color("#8EA2CA"))
	_draw_text("CHOOSE A SHAPE",Vector2(0,tray_y-26),12,Color("#8EA2CA"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("Drag a shape onto the board  •  Clear rows & columns",Vector2(0,h*0.94),10,Color("#7183A8"),HORIZONTAL_ALIGNMENT_CENTER,w)
	if game_over:
		_draw_modal("NO MORE MOVES","Final score: "+str(score),"PLAY AGAIN","HOME")

func _draw_modal(heading: String, subtitle: String, primary: String, secondary: String) -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.04,0.09,0.72))
	_draw_panel(Rect2(28,h*0.36,w-56,250),Color("#202D4B"),22)
	_draw_text(heading,Vector2(0,h*0.43),24,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text(subtitle,Vector2(0,h*0.48),13,Color("#B8C8E8"),HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_button(Rect2(w*0.20,h*0.53,w*0.60,48),primary,Color("#6658E8"))
	_draw_button(Rect2(w*0.20,h*0.59,w*0.60,42),secondary,Color("#35435F"))

func _draw_background() -> void:
	var menu_screen := screen == Screen.HOME or screen == Screen.SETTINGS
	var top_color := Color("#FFF0D2") if menu_screen else Color("#101B35")
	var bottom_color := Color("#E9A45F") if menu_screen else Color("#172747")
	# Layered vertical gradient: clean at phone scale and sharp on high-density displays.
	var bands := 72
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var band_color := top_color.lerp(bottom_color, t)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / float(bands) + 2.0), band_color)
	if menu_screen:
		# Warm sun halo and soft cloud silhouettes.
		draw_circle(Vector2(size.x * 0.82, size.y * 0.135), size.x * 0.19, Color(1.0, 0.72, 0.30, 0.10))
		draw_circle(Vector2(size.x * 0.82, size.y * 0.135), size.x * 0.135, Color(1.0, 0.84, 0.45, 0.18))
		draw_circle(Vector2(size.x * 0.82, size.y * 0.135), size.x * 0.082, Color("#FFF4C9"))
		for cloud in [Vector2(size.x * 0.13, size.y * 0.17), Vector2(size.x * 0.49, size.y * 0.105), Vector2(size.x * 0.93, size.y * 0.30)]:
			draw_circle(cloud, size.x * 0.037, Color(1.0, 1.0, 0.96, 0.70))
			draw_circle(cloud + Vector2(size.x * 0.035, -size.y * 0.012), size.x * 0.047, Color(1.0, 1.0, 0.96, 0.78))
			draw_circle(cloud + Vector2(size.x * 0.075, 0), size.x * 0.034, Color(1.0, 1.0, 0.96, 0.70))
		var far_hill := PackedVector2Array([Vector2(0,size.y*0.68),Vector2(size.x*0.18,size.y*0.57),Vector2(size.x*0.43,size.y*0.66),Vector2(size.x*0.73,size.y*0.54),Vector2(size.x,size.y*0.65),Vector2(size.x,size.y),Vector2(0,size.y)])
		draw_colored_polygon(far_hill, Color("#E9A16A"))
		var near_hill := PackedVector2Array([Vector2(0,size.y*0.80),Vector2(size.x*0.25,size.y*0.70),Vector2(size.x*0.56,size.y*0.79),Vector2(size.x*0.82,size.y*0.68),Vector2(size.x,size.y*0.77),Vector2(size.x,size.y),Vector2(0,size.y)])
		draw_colored_polygon(near_hill, Color("#55A979"))
		var front_hill := PackedVector2Array([Vector2(0,size.y*0.90),Vector2(size.x*0.30,size.y*0.82),Vector2(size.x*0.66,size.y*0.91),Vector2(size.x,size.y*0.83),Vector2(size.x,size.y),Vector2(0,size.y)])
		draw_colored_polygon(front_hill, Color("#347F68"))
		for i in range(22):
			var fx := fmod(float(i) * 67.0 + 19.0, size.x)
			var fy := size.y * (0.76 + fmod(float(i) * 0.027, 0.20))
			draw_circle(Vector2(fx, fy), 2.2, Color(1.0, 0.94, 0.65, 0.78))
	else:
		# Restrained ambient light pools keep the play board readable.
		draw_circle(Vector2(size.x * 0.08, size.y * 0.31), size.x * 0.48, Color(0.18, 0.48, 0.76, 0.075))
		draw_circle(Vector2(size.x * 0.94, size.y * 0.78), size.x * 0.42, Color(0.42, 0.24, 0.76, 0.07))

func _draw_panel(rect: Rect2,color: Color,radius: float) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.035, 0.07, 0.13, 0.30)
	shadow.set_corner_radius_all(int(radius))
	shadow.shadow_color = Color(0.04, 0.07, 0.12, 0.34)
	shadow.shadow_size = 9
	shadow.shadow_offset = Vector2(0, 6)
	draw_style_box(shadow, rect)
	var panel := StyleBoxFlat.new()
	panel.bg_color = color
	panel.set_corner_radius_all(int(radius))
	panel.set_border_width_all(1)
	panel.border_color = color.lightened(0.22)
	draw_style_box(panel, rect)
	draw_line(rect.position + Vector2(radius, 1.5), Vector2(rect.end.x - radius, rect.position.y + 1.5), Color(1, 1, 1, 0.18), 1.5, true)

func _draw_button(rect: Rect2,label: String,color: Color) -> void:
	_draw_panel(rect, color, 18)
	var sheen := StyleBoxFlat.new()
	sheen.bg_color = Color(1, 1, 1, 0.10)
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
				vibration_enabled = not vibration_enabled
			elif pos.y >= h*0.41 and pos.y <= h*0.49 and pos.x >= w*0.60:
				sound_enabled = not sound_enabled
			elif pos.y >= h*0.73:
				screen=Screen.HOME
			_save_settings()
			queue_redraw()
			return
		Screen.PAUSED:
			if pos.y >= h*0.52 and pos.y <= h*0.59:
				screen=Screen.PLAYING
			elif pos.y >= h*0.59 and pos.y <= h*0.67:
				screen=Screen.HOME
				selected=-1
			queue_redraw()
			return
		Screen.PLAYING:
			if game_over:
				if pos.y >= h*0.52 and pos.y <= h*0.59:
					_reset_game()
				elif pos.y >= h*0.59 and pos.y <= h*0.67:
					screen=Screen.HOME
				queue_redraw()
				return
			if pos.x >= w-78 and pos.y < 70:
				screen=Screen.PAUSED
				queue_redraw()
				return
			var center_y := tray_y+55
			for i in range(3):
				var center_x := w*(float(i)+0.5)/3.0
				if pos.distance_to(Vector2(center_x,center_y)) < 82 and not pieces[i].is_empty():
					selected=i
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
		return
	# Validate the board before writing to avoid invalid Android grid access.
	if board.size() != GRID:
		return
	for y in range(GRID):
		if not (board[y] is Array) or board[y].size() != GRID:
			return
	var color_index: int = COLORS.find(piece_colors[selected])
	if color_index < 0:
		color_index = 0
	for c in shape:
		var target_y: int = at.y + c.y
		var target_x: int = at.x + c.x
		if target_y < 0 or target_y >= GRID or target_x < 0 or target_x >= GRID:
			return
		var row: Array = board[target_y]
		row[target_x] = color_index
		board[target_y] = row
	score += shape.size() * 5
	pieces[selected]=[]
	selected=-1
	var cleared := _clear_lines()
	if cleared > 0:
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
