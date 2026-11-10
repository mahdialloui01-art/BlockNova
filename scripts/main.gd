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

func _ready() -> void:
	font = ThemeDB.fallback_font
	_reset_game()
	queue_redraw()

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
	queue_redraw()

func _new_pieces() -> void:
	pieces.clear()
	piece_colors.clear()
	for i in range(3):
		var shape: Array = SHAPES[randi_range(0, SHAPES.size() - 1)].duplicate()
		pieces.append(shape)
		piece_colors.append(COLORS[randi_range(0, COLORS.size() - 1)])
	if not _any_move():
		game_over = true

func _layout() -> void:
	var w := size.x
	var h := size.y
	board_size = minf(w - 36.0, h * 0.49)
	cell = board_size / GRID
	board_origin = Vector2((w - board_size) * 0.5, h * 0.255)
	tray_y = h * 0.78

func _draw() -> void:
	_layout()
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#090F20"))
	# Soft ambient panels
	draw_circle(Vector2(w * 0.12, h * 0.16), w * 0.42, Color(0.12,0.28,0.48,0.10))
	draw_circle(Vector2(w * 0.92, h * 0.72), w * 0.38, Color(0.38,0.18,0.48,0.08))
	_draw_text("BLOCK NOVA", Vector2(0, h*0.075), 30, Color("#F5F8FF"), HORIZONTAL_ALIGNMENT_CENTER, w)
	_draw_text("PUZZLE • THINK • COMBO", Vector2(0, h*0.105), 11, Color("#7E91B8"), HORIZONTAL_ALIGNMENT_CENTER, w)
	_draw_panel(Rect2(22, h*0.135, w-44, 72), Color("#151F38"), 18)
	_draw_text("SCORE", Vector2(42,h*0.166), 11, Color("#8EA2CA"))
	_draw_text(str(score), Vector2(42,h*0.205), 25, Color.WHITE)
	_draw_text("BEST  " + str(max(best,score)), Vector2(w-150,h*0.19), 15, Color("#FFD477"))
	_draw_text("YOUR BOARD", Vector2(board_origin.x, board_origin.y-24), 12, Color("#8EA2CA"))
	for y in range(GRID):
		for x in range(GRID):
			var p := board_origin + Vector2(x*cell,y*cell)
			var rect := Rect2(p+Vector2(2,2),Vector2(cell-4,cell-4))
			if board[y][x] == -1:
				_draw_panel(rect,Color("#17233D"),5)
			else:
				_draw_block(rect,COLORS[board[y][x]])
	_draw_text("CHOOSE A SHAPE", Vector2(0,tray_y-26), 12, Color("#8EA2CA"), HORIZONTAL_ALIGNMENT_CENTER, w)
	for i in range(3):
		if pieces[i].is_empty():
			continue
		var center := Vector2(w*(float(i)+0.5)/3.0, tray_y+55)
		if selected == i:
			_draw_panel(Rect2(center.x-58,center.y-48,116,104),Color("#26385B"),16)
		var shape: Array = pieces[i]
		var minp := Vector2i(99,99)
		var maxp := Vector2i.ZERO
		for c in shape:
			minp.x=mini(minp.x,c.x); minp.y=mini(minp.y,c.y)
			maxp.x=maxi(maxp.x,c.x); maxp.y=maxi(maxp.y,c.y)
		var unit := minf(20.0, 66.0 / float(maxi(maxp.x-minp.x+1,maxp.y-minp.y+1)))
		var origin := center-Vector2((maxp.x-minp.x+1)*unit,(maxp.y-minp.y+1)*unit)*0.5
		for c in shape:
			var r := Rect2(origin+Vector2(c-minp)*unit+Vector2(1,1),Vector2(unit-2,unit-2))
			_draw_block(r,piece_colors[i])
	if dragging and selected >= 0 and not pieces[selected].is_empty():
		_draw_ghost()
	_draw_text("Drag a shape onto the board  •  Clear rows & columns",Vector2(0,h*0.94),11,Color("#7183A8"),HORIZONTAL_ALIGNMENT_CENTER,w)
	if game_over:
		_draw_panel(Rect2(28,h*0.36,w-56,220),Color("#202D4B"),22)
		_draw_text("NO MORE MOVES",Vector2(0,h*0.43),24,Color("#FFFFFF"),HORIZONTAL_ALIGNMENT_CENTER,w)
		_draw_text("Final score: "+str(score),Vector2(0,h*0.48),15,Color("#B8C8E8"),HORIZONTAL_ALIGNMENT_CENTER,w)
		_draw_panel(Rect2(w*0.25,h*0.52,w*0.5,48),Color("#6C5CE7"),14)
		_draw_text("PLAY AGAIN",Vector2(0,h*0.552),15,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER,w)

func _draw_ghost() -> void:
	var shape: Array = pieces[selected]
	var origin := _cell_at(pointer)
	for c in shape:
		var p := board_origin+Vector2(origin+c)*cell
		var color := piece_colors[selected]
		draw_rect(Rect2(p+Vector2(2,2),Vector2(cell-4,cell-4)),Color(color.r,color.g,color.b,0.42),true,5)

func _draw_panel(rect: Rect2, color: Color, radius: float) -> void:
	draw_rect(rect,color,true,radius)

func _draw_block(rect: Rect2, color: Color) -> void:
	draw_rect(rect,color,true,6)
	draw_rect(Rect2(rect.position+Vector2(3,2),Vector2(rect.size.x-6,4)),Color(1,1,1,0.20),true,3)

func _draw_text(value: String, pos: Vector2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var target_width := width if width > 0 else 300.0
	draw_string(font,Vector2(pos.x,pos.y),value,align,target_width,font_size,color)

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
	if game_over:
		if pos.y > size.y*0.50 and pos.y < size.y*0.60:
			_reset_game()
		return
	var center_y := tray_y+55
	for i in range(3):
		var center_x := size.x*(float(i)+0.5)/3.0
		if pos.distance_to(Vector2(center_x,center_y)) < 65 and not pieces[i].is_empty():
			selected=i
			dragging=true
			queue_redraw()
			return
	if selected >= 0 and _inside_board(pos):
		_try_place(_cell_at(pos))

func _pointer_up(pos: Vector2) -> void:
	pointer=pos
	if dragging and selected >= 0 and _inside_board(pos):
		_try_place(_cell_at(pos))
	dragging=false
	queue_redraw()

func _inside_board(pos: Vector2) -> bool:
	return pos.x >= board_origin.x and pos.y >= board_origin.y and pos.x < board_origin.x+board_size and pos.y < board_origin.y+board_size

func _cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori((pos.x-board_origin.x)/cell),floori((pos.y-board_origin.y)/cell))

func _can_place(shape: Array, at: Vector2i) -> bool:
	for c in shape:
		var x=at.x+c.x
		var y=at.y+c.y
		if x<0 or y<0 or x>=GRID or y>=GRID or board[y][x] != -1:
			return false
	return true

func _try_place(at: Vector2i) -> void:
	if selected < 0 or pieces[selected].is_empty():
		return
	var shape: Array = pieces[selected]
	if not _can_place(shape,at):
		return
	for c in shape:
		board[at.y+c.y][at.x+c.x]=COLORS.find(piece_colors[selected])
	score += shape.size()*5
	pieces[selected]=[]
	selected=-1
	_clear_lines()
	best=maxi(best,score)
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
			if board[y][x] == -1: full=false; break
		if full: rows.append(y)
	for x in range(GRID):
		var full=true
		for y in range(GRID):
			if board[y][x] == -1: full=false; break
		if full: cols.append(x)
	for y in rows:
		for x in range(GRID): board[y][x]=-1
	for x in cols:
		for y in range(GRID): board[y][x]=-1
	var cleared=rows.size()+cols.size()
	if cleared>0:
		score += cleared*cleared*100
		if cleared>=2: score += cleared*75

func _any_move() -> bool:
	for shape in pieces:
		if shape.is_empty(): continue
		for y in range(GRID):
			for x in range(GRID):
				if _can_place(shape,Vector2i(x,y)): return true
	return false
