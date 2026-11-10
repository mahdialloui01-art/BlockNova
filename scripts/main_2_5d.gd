extends "res://scripts/main.gd"

# KayKit Dungeon Pack 1.1 - box_small mesh (CC0).
# The original mesh buffer is gzip-compressed to keep the Android project small.
const BOX_DATA_GZIP_BASE64 := "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";
const BOX_GLTF_JSON := "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"mesh\":0}],\"materials\":[{\"pbrMetallicRoughness\":{\"metallicFactor\":0.05,\"roughnessFactor\":0.58,\"baseColorFactor\":[0.24,0.62,0.92,1]}}],\"meshes\":[{\"primitives\":[{\"attributes\":{\"POSITION\":0,\"TEXCOORD_0\":1,\"NORMAL\":2},\"indices\":3,\"material\":0}]}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":320,\"max\":[0.5,1,0.5],\"min\":[-0.5,0,-0.5],\"type\":\"VEC3\"},{\"bufferView\":1,\"componentType\":5126,\"count\":320,\"type\":\"VEC2\"},{\"bufferView\":2,\"componentType\":5126,\"count\":320,\"type\":\"VEC3\"},{\"bufferView\":3,\"componentType\":5123,\"count\":564,\"type\":\"SCALAR\"}],\"bufferViews\":[{\"buffer\":0,\"byteLength\":3840,\"byteOffset\":0,\"target\":34962},{\"buffer\":0,\"byteLength\":2560,\"byteOffset\":3840,\"target\":34962},{\"buffer\":0,\"byteLength\":3840,\"byteOffset\":6400,\"target\":34962},{\"buffer\":0,\"byteLength\":1128,\"byteOffset\":10240,\"target\":34963}],\"buffers\":[{\"byteLength\":11368,\"uri\":\"box_small.bin\"}]}";

var _viewport_container: SubViewportContainer
var _viewport: SubViewport
var _world_root: Node3D
var _camera: Camera3D
var _models_root: Node3D
var _kaykit_mesh: Mesh
var _sync_pending := true
var _last_signature := ""
var _material_cache: Dictionary = {}

func _ready() -> void:
    super._ready()
    _setup_3d_view()
    _kaykit_mesh = _load_kaykit_box_mesh()
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
    _viewport_container = SubViewportContainer.new()
    _viewport_container.name = "KayKit3DOverlay"
    _viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _viewport_container.stretch = true
    _viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _viewport_container.z_index = 1
    add_child(_viewport_container)

    _viewport = SubViewport.new()
    _viewport.name = "KayKit3DViewport"
    _viewport.size = Vector2i(1080, 2160)
    _viewport.transparent_bg = true
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
    light.shadow_enabled = false
    _world_root.add_child(light)

    _camera = Camera3D.new()
    _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    _camera.size = 40.0
    _camera.position = Vector3(0, 22, 10)
    _camera.look_at(Vector3.ZERO, Vector3.UP)
    _camera.current = true
    _world_root.add_child(_camera)

    _models_root = Node3D.new()
    _models_root.name = "PuzzleMeshes"
    _world_root.add_child(_models_root)

func _load_kaykit_box_mesh() -> Mesh:
    var folder := "user://blocknova_kaykit"
    var absolute_folder := ProjectSettings.globalize_path(folder)
    DirAccess.make_dir_recursive_absolute(absolute_folder)
    var compressed := Marshalls.base64_to_raw(BOX_DATA_GZIP_BASE64)
    var raw := compressed.decompress_dynamic(11368, FileAccess.COMPRESSION_GZIP)
    if raw.is_empty():
        push_warning("KayKit mesh decompression failed; using 3D primitive fallback.")
        return _fallback_box_mesh()
    var binary_file := FileAccess.open(folder + "/box_small.bin", FileAccess.WRITE)
    if binary_file == null:
        return _fallback_box_mesh()
    binary_file.store_buffer(raw)
    binary_file.close()
    var gltf_file := FileAccess.open(folder + "/box_small.gltf", FileAccess.WRITE)
    if gltf_file == null:
        return _fallback_box_mesh()
    gltf_file.store_string(BOX_GLTF_JSON)
    gltf_file.close()

    var document := GLTFDocument.new()
    var state := GLTFState.new()
    var error := document.append_from_file(folder + "/box_small.gltf", state)
    if error != OK:
        push_warning("KayKit GLTF import failed: " + str(error))
        return _fallback_box_mesh()
    var generated := document.generate_scene(state)
    var found := _find_mesh_instance(generated)
    var result: Mesh = found.mesh if found != null else _fallback_box_mesh()
    if generated != null:
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

func _fallback_box_mesh() -> Mesh:
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1, 1, 1)
    return mesh

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
    var material := StandardMaterial3D.new()
    material.albedo_color = color.lightened(0.10)
    material.roughness = 0.56
    material.metallic = 0.06
    material.metallic_specular = 0.28
    _material_cache[key] = material
    return material

func _add_mesh_instance(at: Vector2, world_scale: float, color: Color, node_name: String) -> void:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    instance.mesh = _kaykit_mesh
    instance.material_override = _material_for(color)
    instance.scale = Vector3.ONE * world_scale
    instance.position = _screen_to_board_plane(at) + Vector3(0, 0.025, 0)
    _models_root.add_child(instance)

func _sync_3d_models() -> void:
    if _viewport == null or _models_root == null:
        return
    var visible_game := screen == Screen.PLAYING and not game_over
    _viewport_container.visible = visible_game
    var signature := str(screen, "|", board, "|", pieces, "|", piece_colors, "|", selected, "|", size)
    if signature == _last_signature:
        return
    _last_signature = signature
    for child in _models_root.get_children():
        child.queue_free()
    if not visible_game or _kaykit_mesh == null:
        return

    _viewport.size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
    var world_per_pixel := 40.0 / float(maxi(1, _viewport.size.y))
    var block_world := cell * world_per_pixel * 0.91
    var tile_mesh := BoxMesh.new()
    tile_mesh.size = Vector3(block_world * 0.94, 0.11, block_world * 0.94)
    var tile_material := StandardMaterial3D.new()
    tile_material.albedo_color = Color("#253653")
    tile_material.roughness = 0.88

    for y in range(GRID):
        for x in range(GRID):
            var center := board_origin + Vector2((float(x) + 0.5) * cell, (float(y) + 0.5) * cell)
            var tile := MeshInstance3D.new()
            tile.mesh = tile_mesh
            tile.material_override = tile_material
            tile.position = _screen_to_board_plane(center) + Vector3(0, -0.105, 0)
            _models_root.add_child(tile)
            var color_index := int(board[y][x])
            if color_index >= 0 and color_index < COLORS.size():
                _add_mesh_instance(center, block_world, COLORS[color_index], "KayKitBlock_%d_%d" % [x, y])

    var w := size.x
    for i in range(3):
        if pieces[i].is_empty():
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
            _add_mesh_instance(piece_center, unit * world_per_pixel * 0.96, piece_colors[i], "Tray3D_%d" % i)
