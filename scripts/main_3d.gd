extends Node3D

const GRID := 8
const CELL := 1.0
const BOARD_Z := -1.8
const TRAY_Z := 6.1
const COLORS := [Color("#48D7F2"), Color("#FFB84D"), Color("#A78BFA"), Color("#62E6A5"), Color("#FF6F91"), Color("#F5E96B")]
const SHAPES := [
 [Vector2i(0,0)], [Vector2i(0,0),Vector2i(1,0)],
 [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
 [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
 [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)]
]
enum Screen { HOME, SETTINGS, PLAYING, PAUSED }
var screen := Screen.HOME
var board: Array = []
var pieces: Array = []
var piece_colors: Array = []
var score := 0
var best := 0
var selected := -1
var dragging := false
var pointer_world := Vector3.ZERO
var game_over := false
var world_blocks: Node3D
var camera_3d: Camera3D
var ui_layer: CanvasLayer
var ui_root: Control
var home_panel: Control
var settings_panel: Control
var game_panel: Control
var pause_panel: Control
var score_label: Label
var best_label: Label
var _materials: Dictionary = {}

func _ready() -> void:
 randomize()
 _build_world()
 _build_ui()
 _load_best()
 _show_screen()
 _new_board()
 _rebuild_3d()

func _build_world() -> void:
 var env_node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_SKY
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#9AAED0")
 env.ambient_light_energy = 0.72
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env_node.environment = env
 add_child(env_node)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
 sun.light_energy = 1.35
 sun.shadow_enabled = true
 add_child(sun)
 camera_3d = Camera3D.new()
 camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera_3d.size = 20.5
 camera_3d.position = Vector3(0, 22, 16)
 camera_3d.look_at(Vector3(0, 0, 1.7), Vector3.UP)
 camera_3d.current = true
 add_child(camera_3d)
 var floor := MeshInstance3D.new()
 var floor_mesh := PlaneMesh.new()
 floor_mesh.size = Vector2(80, 80)
 floor.mesh = floor_mesh
 var floor_mat := StandardMaterial3D.new()
 floor_mat.albedo_color = Color("#0A1428")
 floor_mat.roughness = 0.94
 floor.material_override = floor_mat
 floor.position = Vector3(0, -0.42, 0)
 add_child(floor)
 world_blocks = Node3D.new()
 world_blocks.name = "3D_Game_Board_And_Pieces"
 add_child(world_blocks)

func _build_ui() -> void:
 ui_layer = CanvasLayer.new()
 ui_layer.layer = 20
 add_child(ui_layer)
 ui_root = Control.new()
 ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
 ui_layer.add_child(ui_root)
 home_panel = _panel()
 var title := _label(home_panel, "BLOCK NOVA", 38, Vector2(0.08,0.20), Vector2(0.92,0.30), HORIZONTAL_ALIGNMENT_CENTER)
 title.add_theme_color_override("font_color", Color("#F5F8FF"))
 var sub := _label(home_panel, "A TRUE 3D BLOCK PUZZLE", 14, Vector2(0.08,0.31), Vector2(0.92,0.37), HORIZONTAL_ALIGNMENT_CENTER)
 sub.add_theme_color_override("font_color", Color("#48D7F2"))
 _button(home_panel, "PLAY", Vector2(0.14,0.69), Vector2(0.86,0.77), _start_game)
 _button(home_panel, "SETTINGS", Vector2(0.14,0.79), Vector2(0.86,0.86), _open_settings)
 settings_panel = _panel()
 _label(settings_panel, "SETTINGS", 30, Vector2(0.08,0.23), Vector2(0.92,0.32), HORIZONTAL_ALIGNMENT_CENTER)
 _button(settings_panel, "BACK", Vector2(0.14,0.72), Vector2(0.86,0.81), _go_home)
 game_panel = _panel()
 game_panel.visible = false
 var game_title := _label(game_panel, "BLOCK NOVA", 22, Vector2(0.05,0.025), Vector2(0.95,0.075), HORIZONTAL_ALIGNMENT_CENTER)
 game_title.add_theme_color_override("font_color", Color("#F5F8FF"))
 score_label = _label(game_panel, "SCORE  0", 19, Vector2(0.08,0.105), Vector2(0.52,0.16), HORIZONTAL_ALIGNMENT_LEFT)
 best_label = _label(game_panel, "BEST  0", 15, Vector2(0.55,0.11), Vector2(0.92,0.16), HORIZONTAL_ALIGNMENT_RIGHT)
 best_label.add_theme_color_override("font_color", Color("#FFD477"))
 _button(game_panel, "Ⅱ", Vector2(0.86,0.025), Vector2(0.96,0.075), _pause_game)
 var instruction := _label(game_panel, "DRAG 3D BLOCKS ONTO THE BOARD", 12, Vector2(0.05,0.91), Vector2(0.95,0.96), HORIZONTAL_ALIGNMENT_CENTER)
 instruction.add_theme_color_override("font_color", Color("#AFC1E2"))
 pause_panel = _panel()
 pause_panel.visible = false
 _label(pause_panel, "PAUSED", 32, Vector2(0.08,0.34), Vector2(0.92,0.43), HORIZONTAL_ALIGNMENT_CENTER)
 _button(pause_panel, "RESUME", Vector2(0.14,0.52), Vector2(0.86,0.60), _resume_game)
 _button(pause_panel, "HOME", Vector2(0.14,0.63), Vector2(0.86,0.71), _go_home)
 settings_panel.visible = false
 _show_screen()

func _panel() -> Control:
 var p := Control.new()
 p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 p.mouse_filter = Control.MOUSE_FILTER_PASS
 ui_root.add_child(p)
 return p

func _label(parent: Control, value: String, font_size: int, a: Vector2, b: Vector2, align: HorizontalAlignment) -> Label:
 var l := Label.new()
 l.text = value
 l.horizontal_alignment = align
 l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", Color("#EAF0FF"))
 l.anchor_left = a.x
 l.anchor_top = a.y
 l.anchor_right = b.x
 l.anchor_bottom = b.y
 parent.add_child(l)
 return l

func _button(parent: Control, value: String, a: Vector2, b: Vector2, callback: Callable) -> void:
 var btn := Button.new()
 btn.text = value
 btn.anchor_left = a.x
 btn.anchor_top = a.y
 btn.anchor_right = b.x
 btn.anchor_bottom = b.y
 btn.add_theme_font_size_override("font_size", 17)
 btn.add_theme_color_override("font_color", Color.WHITE)
 btn.add_theme_color_override("font_hover_color", Color.WHITE)
 btn.add_theme_stylebox_override("normal", _button_style(Color("#6658E8")))
 btn.add_theme_stylebox_override("hover", _button_style(Color("#8275FF")))
 btn.add_theme_stylebox_override("pressed", _button_style(Color("#4036A8")))
 btn.pressed.connect(callback)
 parent.add_child(btn)

func _button_style(color: Color) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = color
 s.corner_radius_top_left = 16
 s.corner_radius_top_right = 16
 s.corner_radius_bottom_left = 16
 s.corner_radius_bottom_right = 16
 s.content_margin_left = 10
 s.content_margin_right = 10
 return s

func _load_best() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://blocknova.cfg") == OK:
  best = int(cfg.get_value("records", "best", 0))

func _save_best() -> void:
 var cfg := ConfigFile.new()
 cfg.set_value("records", "best", best)
 cfg.save("user://blocknova.cfg")

func _show_screen() -> void:
 home_panel.visible = screen == Screen.HOME
 settings_panel.visible = screen == Screen.SETTINGS
 game_panel.visible = screen == Screen.PLAYING or screen == Screen.PAUSED
 pause_panel.visible = screen == Screen.PAUSED
 if score_label != null:
  score_label.text = "SCORE  " + str(score)
  best_label.text = "BEST  " + str(max(best, score))

func _start_game() -> void:
 _new_board()
 _new_pieces()
 screen = Screen.PLAYING
 _show_screen()
 _rebuild_3d()

func _new_board() -> void:
 board.clear()
 for y in range(GRID):
  var row: Array = []
  for x in range(GRID):
   row.append(-1)
  board.append(row)
 score = 0
 game_over = false
 selected = -1
 dragging = false

func _new_pieces() -> void:
 pieces.clear()
 piece_colors.clear()
 for i in range(3):
  pieces.append(SHAPES[randi_range(0, SHAPES.size()-1)].duplicate())
  piece_colors.append(COLORS[randi_range(0, COLORS.size()-1)])
 if not _any_move():
  game_over = true

func _mat(color: Color) -> StandardMaterial3D:
 var key := color.to_html(true)
 if _materials.has(key):
  return _materials[key]
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.48
 m.metallic = 0.04
 m.metallic_specular = 0.35
 _materials[key] = m
 return m

func _cube(parent: Node3D, pos: Vector3, color: Color, scale: Vector3, name: String) -> void:
 var mesh_node := MeshInstance3D.new()
 mesh_node.name = name
 var mesh := BoxMesh.new()
 mesh.size = Vector3.ONE
 mesh_node.mesh = mesh
 mesh_node.material_override = _mat(color)
 mesh_node.position = pos
 mesh_node.scale = scale
 mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 parent.add_child(mesh_node)

func _rebuild_3d() -> void:
 if world_blocks == null:
  return
 for child in world_blocks.get_children():
  child.free()
 if screen == Screen.HOME:
  var logo := [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1),Vector2i(-1,0),Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]
  for i in range(logo.size()):
   _cube(world_blocks, Vector3(float(logo[i].x)*1.12,0.45,0.2+float(logo[i].y)*1.12), COLORS[i%COLORS.size()], Vector3(1.02,0.9,1.02), "LogoCube")
  return
 if screen != Screen.PLAYING and screen != Screen.PAUSED:
  return
 var board_base := MeshInstance3D.new()
 var base_mesh := BoxMesh.new()
 base_mesh.size = Vector3(8.35,0.28,8.35)
 board_base.mesh = base_mesh
 board_base.material_override = _mat(Color("#101D35"))
 board_base.position = Vector3(0,-0.19,BOARD_Z)
 world_blocks.add_child(board_base)
 for y in range(GRID):
  for x in range(GRID):
   var wx := (float(x)-3.5)*CELL
   var wz := BOARD_Z+(float(y)-3.5)*CELL
   _cube(world_blocks, Vector3(wx,-0.015,wz), Color("#263957"), Vector3(0.94,0.12,0.94), "BoardCell")
   var ci := int(board[y][x])
   if ci >= 0 and ci < COLORS.size():
    _cube(world_blocks, Vector3(wx,0.48,wz), COLORS[ci], Vector3(0.88,0.92,0.88), "PlacedBlock")
 for i in range(3):
  if pieces[i].is_empty() or (dragging and selected == i):
   continue
  var shape: Array = pieces[i]
  var bounds := _shape_bounds(shape)
  var unit := minf(0.78,2.55/float(maxi(bounds.x,bounds.y)))
  var center_x := (float(i)-1.0)*3.45
  var start_x := center_x-(float(bounds.x)-1.0)*unit*0.5
  var start_z := TRAY_Z-(float(bounds.y)-1.0)*unit*0.5
  for c in shape:
   _cube(world_blocks, Vector3(start_x+float(c.x)*unit,0.48,start_z+float(c.y)*unit), piece_colors[i], Vector3(unit*0.88,0.92,unit*0.88), "TrayBlock")
 if dragging and selected >= 0 and selected < pieces.size() and not pieces[selected].is_empty():
  var at := _world_to_cell(pointer_world)
  var valid := _can_place(pieces[selected],at)
  var ghost_color := piece_colors[selected] if valid else Color("#FF536B")
  for c in pieces[selected]:
   _cube(world_blocks, Vector3((float(at.x+c.x)-3.5)*CELL,0.50,BOARD_Z+(float(at.y+c.y)-3.5)*CELL), ghost_color, Vector3(0.88,0.94,0.88), "DragPreview")

func _shape_bounds(shape: Array) -> Vector2i:
 var mx := 0
 var my := 0
 for c in shape:
  mx = maxi(mx,c.x)
  my = maxi(my,c.y)
 return Vector2i(mx+1,my+1)

func _screen_to_plane(screen_pos: Vector2) -> Vector3:
 var origin := camera_3d.project_ray_origin(screen_pos)
 var direction := camera_3d.project_ray_normal(screen_pos)
 if absf(direction.y) < 0.00001:
  return Vector3(999,0,999)
 var t := -origin.y/direction.y
 return origin+direction*t

func _world_to_cell(p: Vector3) -> Vector2i:
 return Vector2i(floori(p.x+4.0),floori(p.z-BOARD_Z+4.0))

func _can_place(shape: Array, at: Vector2i) -> bool:
 for c in shape:
  var x := at.x+c.x
  var y := at.y+c.y
  if x < 0 or y < 0 or x >= GRID or y >= GRID:
   return false
  if int(board[y][x]) != -1:
   return false
 return true

func _try_place(at: Vector2i) -> void:
 if selected < 0 or selected >= pieces.size() or pieces[selected].is_empty():
  return
 var shape: Array = pieces[selected]
 if not _can_place(shape,at):
  return
 for c in shape:
  board[at.y+c.y][at.x+c.x] = COLORS.find(piece_colors[selected])
 score += shape.size()*5
 pieces[selected] = []
 selected = -1
 _clear_lines()
 if score > best:
  best = score
  _save_best()
 if _all_used():
  _new_pieces()
 elif not _any_move():
  game_over = true
 _show_screen()
 _rebuild_3d()

func _clear_lines() -> void:
 var rows: Array[int] = []
 var cols: Array[int] = []
 for y in range(GRID):
  var full := true
  for x in range(GRID):
   if board[y][x] == -1:
    full = false
    break
  if full:
   rows.append(y)
 for x in range(GRID):
  var full := true
  for y in range(GRID):
   if board[y][x] == -1:
    full = false
    break
  if full:
   cols.append(x)
 for y in rows:
  for x in range(GRID):
   board[y][x] = -1
 for x in cols:
  for y in range(GRID):
   board[y][x] = -1
 var cleared := rows.size()+cols.size()
 if cleared > 0:
  score += cleared*cleared*100

func _all_used() -> bool:
 for p in pieces:
  if not p.is_empty():
   return false
 return true

func _any_move() -> bool:
 for shape in pieces:
  if shape.is_empty():
   continue
  for y in range(GRID):
   for x in range(GRID):
    if _can_place(shape,Vector2i(x,y)):
     return true
 return false

func _input(event: InputEvent) -> void:
 if screen != Screen.PLAYING:
  return
 if event is InputEventScreenTouch:
  if event.pressed:
   _touch_down(event.position)
  else:
   _touch_up(event.position)
 elif event is InputEventScreenDrag:
  _touch_move(event.position)
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed:
   _touch_down(event.position)
  else:
   _touch_up(event.position)
 elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  _touch_move(event.position)

func _touch_down(pos: Vector2) -> void:
 var p := _screen_to_plane(pos)
 if absf(p.x) < 5.8 and p.z > TRAY_Z-2.8 and p.z < TRAY_Z+2.8:
  var best_dist := 999.0
  var best_index := -1
  for i in range(3):
   if pieces[i].is_empty():
    continue
   var center := Vector2((float(i)-1.0)*3.45,TRAY_Z)
   var dist := Vector2(p.x,p.z).distance_to(center)
   if dist < best_dist:
    best_dist = dist
    best_index = i
  if best_index >= 0 and best_dist < 2.2:
   selected = best_index
   dragging = true
   pointer_world = _screen_to_plane(pos)
   _rebuild_3d()
 elif selected >= 0:
  pointer_world = p
  _try_place(_world_to_cell(p))

func _touch_move(pos: Vector2) -> void:
 if not dragging:
  return
 pointer_world = _screen_to_plane(pos)
 _rebuild_3d()

func _touch_up(pos: Vector2) -> void:
 if not dragging:
  return
 pointer_world = _screen_to_plane(pos)
 var p := pointer_world
 if p.x >= -4.2 and p.x < 4.2 and p.z >= BOARD_Z-4.2 and p.z < BOARD_Z+4.2:
  _try_place(_world_to_cell(p))
 dragging = false
 selected = -1
 _rebuild_3d()

func _pause_game() -> void:
 screen = Screen.PAUSED
 _show_screen()
 _rebuild_3d()

func _resume_game() -> void:
 screen = Screen.PLAYING
 _show_screen()
 _rebuild_3d()

func _open_settings() -> void:
 screen = Screen.SETTINGS
 _show_screen()
 _rebuild_3d()

func _go_home() -> void:
 screen = Screen.HOME
 selected = -1
 dragging = false
 _show_screen()
 _rebuild_3d()
