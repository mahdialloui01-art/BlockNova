extends Control

const GRID := 10
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
var best := 0
var selected := -1
var dragging := false
var pointer := Vector2.ZERO
var game_over := false
var cell := 34.0
var board_origin := Vector2.ZERO
var board_size := 0.0
var tray_y := 0.0
var font: Font
var sound_enabled := true
var vibration_enabled := true
var config: ConfigFile

func _ready() -> void:
	font = ThemeDB.fallback_font
	_load_settings()
	_layout()
	queue_redraw()

func _load_settings() -> void:
	config = ConfigFile.new()
	config.load("user://blocknova.cfg")
	best = int(config.get_value("records", "best", 0))
	sound_enabled = bool(config.get_value("settings", "sound", true))
	vibration_enabled = bool(config.get_value("settings", "vibration", true))

func _save_settings() -> void:
	config.set_value("records", "best", best)
	config.set_value("settings", "sound", sound_enabled)
	config.set_value("settings", "vibration", vibration_enabled)
	config.save("user://blocknova.cfg")

func _layout() -> void:
	var w := size.x
	var h := size.y
	board_size = minf(w - 36.0, h * 0.49)
	cell = board_size / GRID
	board_origin = Vector2((w - board_size) * 0.5, h * 0.255)
	tray_y = h * 0.78

func _reset_game() -> void:
	board.clear()
	for y in range(GRID):
		var row: Array = []
		for x in range(GRID):
			row.append(-1)
		board.append(row)
	score = 0
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
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#090F20"))
	draw_circle(Vector2(w * 0.12, h * 0.16), w * 0.42, Color(0.12,0.28,0.48,0.10))
	draw_circle(Vector2(w * 0.92, h * 0.72), w * 0.38, Color(0.38,0.18,0.48,0.08))
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
	var w := size.x
	var h := size.y
	_draw_text("BLOCK", Vector2(0,h*0.27), 27, Color("#8EA2CA"), HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("NOVA", Vector2(0,h*0.35), 64, Color("#F5F8FF"), HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_text("THINK • PLACE • CLEAR", Vector2(0,h*0.395), 13, Color("#48D7F2"), HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_logo_board(Vector2(w*0.5,h*0.56))
	_draw_button(Rect2(w*0.14,h*0.73,w*0.72,62),"PLAY",Color("#6658E8"))
	_draw_button(Rect2(w*0.14,h*0.815,w*0.72,54),"SETTINGS",Color("#1C2B49"))
	_draw_text("BEST SCORE  "+str(best),Vector2(0,h*0.93),13,Color("#FFD477"),HORIZONTAL_ALIGNMENT_CENTER,w)

func _draw_logo_board(center: Vector2) -> void:
	var unit := minf(size.x*0.105,42.0)
	var pattern := [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1),Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]
	for i in range(pattern.size()):
		var p := center+Vector2(pattern[i])*unit
		_draw_block(Rect2(p-Vector2(unit*0.43,unit*0.43),Vector2(unit-4,unit-4)),COLORS[i%COLORS.size()])

func _draw_settings() -> void:
	var w := size.x
	var h := size.y
	_draw_text("SETTINGS",Vector2(0,h*0.20),31,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,w)
	_draw_panel(Rect2(w*0.09,h*0.30,w*0.82,220),Color("#151F38"),20)
	_draw_text("VIBRATION",Vector2(w*0.16,h*0.37),15,Color("#EAF0FF"))
	_draw_button(Rect2(w*0.64,h*0.34,w*0.20,42),"ON" if vibration_enabled else "OFF",Color("#287E78") if vibration_enabled else Color("#39445C"))
	_draw_text("AUDIO EFFECTS",Vector2(w*0.16,h*0.47),15,Color("#EAF0FF"))
	_draw_text("COMING SOON",Vector2(w*0.61,h*0.47),10,Color("#8EA2CA"))
	_draw_text("BEST SCORE  "+str(best),Vector2(0,h*0.62),15,Color("#FFD477"),HORIZONTAL_ALIGNMENT_CENTER,w)
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
	_draw_button(Rect2(w-65,18,44,38),"Ⅱ",Color("#26385B"))
	_draw_text("YOUR BOARD",Vector2(board_origin.x,board_origin.y-24),12,Color("#8EA2CA"))
	for y in range(GRID):
		for x in range(GRID):
			var p := board_origin+Vector2(x*cell,y*cell)
			var rect := Rect2(p+Vector2(2,2),Vector2(cell-4,cell-4))
			if board[y][x] == -1:
				_draw_panel(rect,Color("#17233D"),5)
			else:
				_draw_block(rect,COLORS[board[y][x]])
	_draw_text("CHOOSE A SHAPE",Vector2(0,tray_y-26),12,Color("#8EA2CA"),HORIZONTAL_ALIGNMENT_CENTER,w)
	for i in range(3):
		if pieces[i].is_empty():
			continue
		var center := Vector2(w*(float(i)+0.5)/3.0,tray_y+55)
		if selected == i:
			_draw_panel(Rect2(center.x-58,center.y-48,116,104),Color("#26385B"),16)
		var shape: Array = pieces[i]
		var minp := Vector2i(99,99)
		var maxp := Vector2i.ZERO
		for c in shape:
			minp.x=mini(minp.x,c.x)
			minp.y=mini(minp.y,c.y)
			maxp.x=maxi(maxp.x,c.x)
			maxp.y=maxi(maxp.y,c.y)
		var unit := minf(20.0,66.0/float(maxi(maxp.x-minp.x+1,maxp.y-minp.y+1)))
		var origin := center-Vector2((maxp.x-minp.x+1)*unit,(maxp.y-minp.y+1)*unit)*0.5
		for c in shape:
			_draw_block(Rect2(origin+Vector2(c-minp)*unit+Vector2(1,1),Vector2(unit-2,unit-2)),piece_colors[i])
	if dragging and selected >= 0 and not pieces[selected].is_empty():
		_draw_ghost()
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

func _draw_ghost() -> void:
	var shape: Array = pieces[selected]
	var origin := _cell_at(pointer)
	var valid := _can_place(shape, origin)
	var base: Color = piece_colors[selected] if valid else Color("#FF536B")
	for c in shape:
		var p := board_origin+Vector2(origin+c)*cell
		var rect := Rect2(p+Vector2(2,2),Vector2(cell-4,cell-4))
		_draw_panel(rect,Color(base.r,base.g,base.b,0.48),5)
		draw_rect(Rect2(rect.position+Vector2(3,2),Vector2(maxf(1,rect.size.x-6),3)),Color(1,1,1,0.22),true)

func _draw_panel(rect: Rect2,color: Color,radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(roundi(radius))
	draw_style_box(style,rect)

func _draw_button(rect: Rect2,label: String,color: Color) -> void:
	_draw_panel(rect,color,14)
	_draw_text(label,Vector2(0,rect.position.y+rect.size.y*0.62),15,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,size.x)

func _draw_block(rect: Rect2,color: Color) -> void:
	_draw_panel(rect,color,6)
	draw_rect(Rect2(rect.position+Vector2(3,2),Vector2(maxf(1,rect.size.x-6),4)),Color(1,1,1,0.20),true)

func _draw_text(value: String,pos: Vector2,font_size: int,color: Color,align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT,width: float=-1.0) -> void:
	draw_string(font,pos,value,align,width if width>0 else 300.0,font_size,color)

func _input(event: InputEvent) -> void:
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
		pointer=event.position
		dragging=true
		queue_redraw()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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
			if pos.y >= h*0.32 and pos.y <= h*0.41 and pos.x >= w*0.60:
				vibration_enabled = not vibration_enabled
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
				if pos.distance_to(Vector2(center_x,center_y)) < 65 and not pieces[i].is_empty():
					selected=i
					dragging=true
					queue_redraw()
					return
			if selected >= 0 and _inside_board(pos):
				_try_place(_cell_at(pos))

func _pointer_up(pos: Vector2) -> void:
	pointer=pos
	if screen == Screen.PLAYING and dragging and selected >= 0 and _inside_board(pos):
		_try_place(_cell_at(pos))
	dragging=false
	queue_redraw()

func _inside_board(pos: Vector2) -> bool:
	return pos.x>=board_origin.x and pos.y>=board_origin.y and pos.x<board_origin.x+board_size and pos.y<board_origin.y+board_size

func _cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori((pos.x-board_origin.x)/cell),floori((pos.y-board_origin.y)/cell))

func _can_place(shape: Array,at: Vector2i) -> bool:
	for c in shape:
		var x=at.x+c.x
		var y=at.y+c.y
		if x<0 or y<0 or x>=GRID or y>=GRID or board[y][x] != -1:
			return false
	return true

func _try_place(at: Vector2i) -> void:
	if selected<0 or pieces[selected].is_empty():
		return
	var shape: Array=pieces[selected]
	if not _can_place(shape,at):
		return
	for c in shape:
		board[at.y+c.y][at.x+c.x]=COLORS.find(piece_colors[selected])
	score+=shape.size()*5
	pieces[selected]=[]
	selected=-1
	_clear_lines()
	if score>best:
		best=score
		_save_settings()
	if vibration_enabled:
		Input.vibrate_handheld(25)
	if pieces.all(func(p): return p.is_empty()):
		_new_pieces()
	elif not _any_move():
		game_over=true
	queue_redraw()

func _clear_lines() -> void:
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

func _any_move() -> bool:
	for shape in pieces:
		if shape.is_empty():
			continue
		for y in range(GRID):
			for x in range(GRID):
				if _can_place(shape,Vector2i(x,y)):
					return true
	return false
