extends "res://scripts/main.gd"

var _overlay_layer: CanvasLayer
var _viewport_container: SubViewportContainer
var _viewport: SubViewport
var _world_root: Node3D
var _camera: Camera3D
var _models_root: Node3D
var _block_mesh: Mesh
var _sync_pending := true
var _last_signature := ""
var _material_cache: Dictionary = {}

func _enter_tree() -> void:
    use_3d_visuals = true

func _ready() -> void:
    super._ready()
    _setup_3d_view()
    _block_mesh = _load_kaykit_box_mesh()
    _sync_pending = true
    set_process(true)

func _draw() -> void:
    super._draw()
    _sync_pending = true

func _process(_delta: float) -> void:
    if _sync_pending:
        _sync_pending = false
        _sync_3d_models()

func _setup_3d_view() -> void:
    _overlay_layer = CanvasLayer.new()
    _overlay_layer.name = "ThreeDRenderLayer"
    _overlay_layer.layer = 10
    add_child(_overlay_layer)

    _viewport_container = SubViewportContainer.new()
    _viewport_container.name = "KayKit3DOverlay"
    _viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _viewport_container.stretch = true
    _viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _viewport_container.z_index = 0
    _viewport_container.top_level = true
    _overlay_layer.add_child(_viewport_container)

    _viewport = SubViewport.new()
    _viewport.name = "KayKit3DViewport"
    _viewport.size = Vector2i(1080, 2160)
    _viewport.transparent_bg = true
    _viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _viewport_container.add_child(_viewport)

    _world_root = Node3D.new()
    _world_root.name = "PuzzleWorld"
    _viewport.add_child(_world_root)

    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0, 0, 0, 0)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.78, 0.92)
    environment.ambient_light_energy = 0.8
    environment_node.environment = environment
    _world_root.add_child(environment_node)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-48, -28, 0)
    light.light_energy = 1.15
    light.shadow_enabled = true
    light.shadow_bias = 0.05
    _world_root.add_child(light)

    _camera = Camera3D.new()
    _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    _camera.size = 40.0
    _world_root.add_child(_camera)
    # Apply the camera transform after it enters the SubViewport's SceneTree.
    # Otherwise Godot can keep the default orientation and render the board off-screen.
    _camera.position = Vector3(0, 22, 10)
    _camera.look_at(Vector3.ZERO, Vector3.UP)
    _camera.make_current()

    _models_root = Node3D.new()
    _models_root.name = "PuzzleMeshes"
    _world_root.add_child(_models_root)

func _load_kaykit_box_mesh() -> Mesh:
    const MODEL_PATH := "res://assets/kaykit/gltf/box_small.gltf"
    var packed_scene := ResourceLoader.load(MODEL_PATH) as PackedScene
    if packed_scene == null:
        push_error("Could not load KayKit 3D box model.")
        return null
    var generated := packed_scene.instantiate()
    var found := _find_mesh_instance(generated)
    if found == null or found.mesh == null:
        generated.free()
        push_error("KayKit box model has no mesh.")
        return null
    var result: Mesh = found.mesh
    generated.free()
    return result

func _find_mesh_instance(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and node.mesh != null:
        return node as MeshInstance3D
    for child in node.get_children():
        var found := _find_mesh_instance(child)
        if found != null:
            return found
    return null

func _screen_to_board_plane(screen_point: Vector2) -> Vector3:
    var origin := _camera.project_ray_origin(screen_point)
    var direction := _camera.project_ray_normal(screen_point)
    if absf(direction.y) < 0.0001:
        return Vector3.ZERO
    return origin + direction * (-origin.y / direction.y)

func _material_for(color: Color) -> StandardMaterial3D:
    var key := color.to_html(true)
    if _material_cache.has(key):
        return _material_cache[key]
    var material: StandardMaterial3D
    material = StandardMaterial3D.new()
    # Apply a polished colored material to the imported KayKit cube geometry.
    material.albedo_color = color.lightened(0.10)
    material.roughness = 0.24
    material.metallic = 0.12
    material.metallic_specular = 0.55
    _material_cache[key] = material
    return material

func _add_mesh_instance(at: Vector2, world_scale: float, color: Color, node_name: String, lift: float = 0.0, vertical_scale: float = 1.0) -> void:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    instance.mesh = _block_mesh
    instance.material_override = _material_for(color)
    instance.scale = Vector3(world_scale, world_scale * vertical_scale, world_scale)
    instance.position = _screen_to_board_plane(at) + Vector3(0, lift, 0)
    _models_root.add_child(instance)

func _append_box_surface(tool: SurfaceTool, box: BoxMesh, center: Vector3, dimensions: Vector3) -> void:
    var basis := Basis.from_scale(dimensions)
    tool.append_from(box, 0, Transform3D(basis, center))

func _build_single_board_mesh() -> MeshInstance3D:
    # A single physical board assembly with recessed wells, raised dividers and a thick base.
    # All board geometry is merged into one ArrayMesh with separate material surfaces.
    var top_left := _screen_to_board_plane(board_origin)
    var top_right := _screen_to_board_plane(board_origin + Vector2(board_size, 0))
    var bottom_left := _screen_to_board_plane(board_origin + Vector2(0, board_size))
    var bottom_right := _screen_to_board_plane(board_origin + Vector2(board_size, board_size))
    var center := (top_left + top_right + bottom_left + bottom_right) * 0.25
    var board_width := top_left.distance_to(top_right)
    var board_depth := top_left.distance_to(bottom_left)
    var cell_width := board_width / float(GRID)
    var cell_depth := board_depth / float(GRID)
    var rail := minf(cell_width, cell_depth) * 0.075
    var mesh := ArrayMesh.new()
    var box := BoxMesh.new()

    # Heavy uninterrupted underside gives the board a real solid body.
    var base_tool := SurfaceTool.new()
    base_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    _append_box_surface(base_tool, box, center + Vector3(0, -0.135, 0), Vector3(board_width + 0.42, 0.27, board_depth + 0.42))
    base_tool.commit(mesh)

    # Cell floors sit low inside the wells, leaving a visible recessed channel around each one.
    var floor_tool := SurfaceTool.new()
    floor_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for y in range(GRID):
        for x in range(GRID):
            var u := (float(x) + 0.5) / float(GRID) - 0.5
            var v := (float(y) + 0.5) / float(GRID) - 0.5
            var cell_center := center + Vector3(u * board_width, 0.005, v * board_depth)
            _append_box_surface(floor_tool, box, cell_center, Vector3(cell_width - rail * 1.35, 0.055, cell_depth - rail * 1.35))
    floor_tool.commit(mesh)

    # Raised dividers form the actual walls between the recessed cells, not painted grid lines.
    var wall_tool := SurfaceTool.new()
    wall_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var wall_height := 0.18
    var wall_y := 0.055
    for i in range(GRID + 1):
        var offset_x := -board_width * 0.5 + float(i) * cell_width
        var offset_z := -board_depth * 0.5 + float(i) * cell_depth
        _append_box_surface(wall_tool, box, center + Vector3(offset_x, wall_y, 0), Vector3(rail, wall_height, board_depth + 0.30))
        _append_box_surface(wall_tool, box, center + Vector3(0, wall_y, offset_z), Vector3(board_width + 0.30, wall_height, rail))
    wall_tool.commit(mesh)

    var board_node := MeshInstance3D.new()
    board_node.name = "OnePieceRecessed3DBoard"
    board_node.mesh = mesh
    var base_mat := StandardMaterial3D.new()
    base_mat.albedo_color = Color("#101A30")
    base_mat.roughness = 0.68
    base_mat.metallic = 0.12
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("#263D60")
    floor_mat.roughness = 0.42
    floor_mat.metallic = 0.08
    var wall_mat := StandardMaterial3D.new()
    wall_mat.albedo_color = Color("#526B91")
    wall_mat.roughness = 0.38
    wall_mat.metallic = 0.18
    mesh.surface_set_material(0, base_mat)
    mesh.surface_set_material(1, floor_mat)
    mesh.surface_set_material(2, wall_mat)
    board_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    _models_root.add_child(board_node)
    return board_node

func _sync_3d_models() -> void:
    if _viewport == null or _models_root == null:
        return
    var visible_game := screen == Screen.PLAYING and not game_over
    var visible_home := screen == Screen.HOME
    var visible_3d := visible_game or visible_home
    _viewport_container.visible = visible_3d
    var drag_cell := _cell_at(pointer) - drag_cell_offset if dragging else Vector2i(-999, -999)
    var signature := str(screen, "|", board, "|", pieces, "|", piece_colors, "|", selected, "|", dragging, "|", drag_cell, "|", drag_cell_offset, "|", size)
    if signature == _last_signature:
        return
    _last_signature = signature
    for child in _models_root.get_children():
        child.queue_free()
    if not visible_3d or _block_mesh == null:
        return

    var world_per_pixel := 40.0 / float(maxi(1, _viewport.size.y))
    if visible_home:
        var logo_center := Vector2(size.x * 0.5, size.y * 0.56)
        var logo_unit := minf(size.x * 0.105, 42.0)
        var logo_pattern := [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,0), Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]
        for i in range(logo_pattern.size()):
            var logo_point := logo_center + Vector2(logo_pattern[i]) * logo_unit
            _add_mesh_instance(logo_point, logo_unit * world_per_pixel * 0.94, COLORS[i % COLORS.size()], "HomeLogo3D_%d" % i)
        return

    # Render the board as one merged physical mesh, not 64 crate-like KayKit props.
    _build_single_board_mesh()
    var block_world := cell * world_per_pixel * 0.78
    for y in range(GRID):
        for x in range(GRID):
            var center := board_origin + Vector2((float(x) + 0.5) * cell, (float(y) + 0.5) * cell)
            var color_index := int(board[y][x])
            if color_index >= 0 and color_index < COLORS.size():
                _add_mesh_instance(center, block_world, COLORS[color_index], "BoardCube_%d_%d" % [x, y], block_world * 0.48)

    var w := size.x
    for i in range(3):
        if pieces[i].is_empty() or (dragging and selected == i):
            continue
        var shape: Array = pieces[i]
        var minp := Vector2i(99, 99)
        var maxp := Vector2i.ZERO
        for c in shape:
            minp.x = mini(minp.x, c.x)
            minp.y = mini(minp.y, c.y)
            maxp.x = maxi(maxp.x, c.x)
            maxp.y = maxi(maxp.y, c.y)
        var unit := minf(20.0, 66.0 / float(maxi(maxp.x - minp.x + 1, maxp.y - minp.y + 1)))
        var center := Vector2(w * (float(i) + 0.5) / 3.0, tray_y + 55)
        var origin := center - Vector2((maxp.x - minp.x + 1) * unit, (maxp.y - minp.y + 1) * unit) * 0.5
        for c in shape:
            var piece_center := origin + Vector2(c - minp) * unit + Vector2(unit * 0.5, unit * 0.5)
            _add_mesh_instance(piece_center, unit * world_per_pixel * 0.84, piece_colors[i], "TrayCube_%d" % i)

    if dragging and selected >= 0 and selected < pieces.size() and not pieces[selected].is_empty():
        var ghost_origin := _cell_at(pointer) - drag_cell_offset
        var ghost_valid := _can_place(pieces[selected], ghost_origin)
        var ghost_color: Color = piece_colors[selected] if ghost_valid else Color("#FF536B")
        for c in pieces[selected]:
            var ghost_center := board_origin + Vector2((ghost_origin.x + c.x + 0.5) * cell, (ghost_origin.y + c.y + 0.5) * cell)
            _add_mesh_instance(ghost_center, block_world * 0.90, ghost_color, "DragCube_%d_%d" % [c.x, c.y])
