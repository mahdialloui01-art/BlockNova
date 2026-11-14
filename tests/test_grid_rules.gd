extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var main_scene := load("res://scenes/main.tscn") as PackedScene
    if not _check(main_scene != null, "The active Android scene must load"):
        return
    var rules_script := load("res://scripts/main.gd") as GDScript
    if not _check(rules_script != null and int(rules_script.get_script_constant_map().get("GRID", -1)) == 8, "Shared gameplay rules must use an 8x8 board"):
        return
    var alternate_3d_script := load("res://scripts/main_3d.gd") as GDScript
    if not _check(alternate_3d_script != null and int(alternate_3d_script.get_script_constant_map().get("GRID", -1)) == 8, "Alternate 3D mode must also use an 8x8 board"):
        return
    var game := main_scene.instantiate() as Control
    if not _check(game != null and game.get_script().resource_path == "res://scripts/main_2_5d.gd", "Regression tests must instantiate the active 2.5D scene"):
        return
    root.add_child(game)
    await process_frame
    if not _check(game.get("_viewport") is SubViewport, "The active scene must initialize its 3D viewport"):
        return
    if not _check(game.get("_block_mesh") is Mesh, "The active scene must build its rounded 3D block mesh"):
        return
    var glow_parent := Node3D.new()
    game.add_child(glow_parent)
    game.call("_add_center_glow", glow_parent, 1.25, Color("#27DDF2"))
    var glow_node := glow_parent.get_node_or_null("SoftCenterHighlight") as MeshInstance3D
    if not _check(glow_node != null and glow_node.mesh is PlaneMesh, "Block highlight must create a plane mesh"):
        return
    if not _check(absf(glow_node.rotation.x + PI * 0.5) < 0.001, "Block highlight plane must face upward onto the top face"):
        return
    if not _check(glow_node.scale.is_equal_approx(Vector3.ONE), "Block highlight must use local unit scale to avoid double scaling"):
        return
    if not _check(glow_node.position.is_equal_approx(Vector3(0, 0.505, 0)), "Block highlight must sit just above the cube top"):
        return
    glow_parent.queue_free()
    if not _check(game.get("_effects_root") is Node3D, "Transient effects must live outside the rebuilt puzzle mesh root"):
        return
    var placed_visual_cells: Array[Vector2i] = [Vector2i(0, 0)]
    var cleared_visual_cells: Array[Vector2i] = [Vector2i(1, 0)]
    game.set("_last_cleared_colors", {Vector2i(1, 0): 1})
    game.call("_on_placement_resolved", placed_visual_cells, cleared_visual_cells, 0)
    var effects_root := game.get("_effects_root") as Node3D
    if not _check(effects_root.get_child_count() == 2, "Placement and line-clear feedback must create separate lightweight effects"):
        return
    if not _check(int(game.get("_active_visual_effects")) == 2, "Both visual effects must be tracked while animating"):
        return
    var effect_viewport := game.get("_viewport") as SubViewport
    if not _check(effect_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "The 3D viewport must update only while transient effects animate"):
        return
    await create_timer(0.35).timeout
    await process_frame
    if not _check(int(game.get("_active_visual_effects")) == 0 and effects_root.get_child_count() == 0, "Transient effects must clean themselves up after animation"):
        return
    if not _check(effect_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "The 3D viewport must return to idle mode after effects finish"):
        return
    var music_player := game.get("_music_player") as AudioStreamPlayer
    var music_stream := music_player.stream as AudioStreamWAV if music_player != null else null
    if not _check(music_stream != null and music_stream.mix_rate == 24000, "Background music must use the mobile-optimized 24 kHz sample rate"):
        return
    if not _check(music_stream.data.size() == 24000 * 8 * 4, "Background music must remain an 8-second stereo loop"):
        return

    var home_ui := game.get("home_ui") as CanvasLayer
    if not _check(home_ui != null and home_ui.has_signal("daily_challenge_requested"), "Home screen must expose the daily challenge action"):
        return
    home_ui.emit_signal("daily_challenge_requested")
    if not _check(bool(game.get("daily_mode")), "Daily challenge action must start daily mode"):
        return
    var first_daily_pieces: Array = game.get("pieces").duplicate(true)
    var first_daily_colors: Array = game.get("piece_colors").duplicate(true)
    var daily_key := str(game.get("daily_date_key"))
    if not _check(daily_key.split("-").size() == 3, "Daily challenge must use a local calendar date key"):
        return
    game.call("_seed_daily_challenge")
    game.call("_reset_game")
    if not _check(game.get("pieces") == first_daily_pieces, "Daily challenge piece sequence must be deterministic for the same date"):
        return
    if not _check(game.get("piece_colors") == first_daily_colors, "Daily challenge colors must be deterministic for the same date"):
        return
    # Exercise the haptic preference guard in CI; headless desktop runs must stay safe.
    game.set("vibration_enabled", false)
    game.call("_trigger_haptic", 24, 0.35)
    game.set("vibration_enabled", true)
    game.call("_trigger_haptic", 24, 0.35)
    var preset_file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
    if not _check(preset_file != null, "Android export preset must be available to tests"):
        return
    var preset_text := preset_file.get_as_text()
    preset_file.close()
    if not _check(preset_text.contains("permissions/vibrate=true"), "Android export must declare the VIBRATE permission"):
        return
    var initial_board: Array = game.get("board")
    if not _check(initial_board.size() == 8, "New game must create exactly 8 rows"):
        return
    for row in initial_board:
        if not _check(row is Array and row.size() == 8, "Every board row must contain exactly 8 cells"):
            return

    # Prepare a full bottom row and right column with one shared empty corner.
    var test_board := _empty_board()
    for x in range(7):
        test_board[7][x] = 0
    for y in range(7):
        test_board[y][7] = 0

    game.set("board", test_board)
    game.set("pieces", [[Vector2i(0, 0)], [], []])
    game.set("piece_colors", [Color("#27DDF2")])
    game.set("selected", 0)

    if not _check(game.call("_can_place", [Vector2i(0, 0)], Vector2i(7, 7)), "A single block must fit in the bottom-right cell"):
        return
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(8, 7)), "Placement beyond the right edge must be rejected"):
        return
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(7, 8)), "Placement beyond the bottom edge must be rejected"):
        return
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(-1, 7)), "Negative coordinates must be rejected"):
        return

    game.call("_try_place", Vector2i(7, 7))
    var actual_cleared_cells: Array = game.get("_last_cleared_cells")
    var actual_cleared_colors: Dictionary = game.get("_last_cleared_colors")
    if not _check(actual_cleared_cells.size() == 15 and actual_cleared_colors.size() == 15, "Simultaneous row and column clearing must capture each unique cell and its color"):
        return
    if not _check(int(game.get("_active_visual_effects")) == 15, "Every cleared tile must receive one short visual fade"):
        return
    await create_timer(0.35).timeout
    await process_frame
    if not _check(int(game.get("_active_visual_effects")) == 0, "All real line-clear animations must finish and clean up"):
        return
    var final_board: Array = game.get("board")
    for i in range(8):
        if not _check(int(final_board[7][i]) == -1, "Completed bottom row was not cleared"):
            return
        if not _check(int(final_board[i][7]) == -1, "Completed right column was not cleared"):
            return

    var cleared_cells: Array = game.get("_last_cleared_cells")
    var cleared_colors: Dictionary = game.get("_last_cleared_colors")
    if not _check(cleared_cells.size() == 15, "Simultaneous 8x8 row and column clearing must report each cell once"):
        return
    if not _check(cleared_colors.size() == 15 and int(cleared_colors.get(Vector2i(7, 7), -1)) == 0, "Cleared-cell colors must be captured for renderer effects"):
        return

    if not _check(int(game.get("combo_streak")) == 1, "A successful line clear must start combo x1"):
        return
    if not _check(int(game.get("score")) == 630, "Two-line clear score must include placement, clear, and combo bonuses"):
        return
    if not _check(int(game.get("daily_best")) >= 630, "Daily challenge best score must persist the current run"):
        return

    if not _check(home_ui.has_signal("resume_requested"), "Home screen must expose a resume action"):
        return
    game.call("_save_session")
    var disk_config := ConfigFile.new()
    if not _check(disk_config.load("user://blocknova.cfg") == OK, "Saved game data must be readable after reopening the config file"):
        return
    game.set("config", disk_config)
    if not _check(bool(game.call("_has_saved_session")), "A valid active game must be saved for resume"):
        return
    var resume_button := home_ui.get_node_or_null("FullScreenHome/ResumeButton") as Button
    if not _check(resume_button != null and resume_button.visible, "Saved game must reveal the home-screen resume button"):
        return
    var saved_score := int(game.get("score"))
    var saved_board: Array = game.get("board").duplicate(true)
    var saved_pieces: Array = game.get("pieces").duplicate(true)
    var saved_rng := game.get("game_rng") as RandomNumberGenerator
    var expected_rng := RandomNumberGenerator.new()
    expected_rng.state = saved_rng.state
    var expected_next_random := expected_rng.randi()
    saved_rng.randi()
    game.set("score", 0)
    game.set("board", _empty_board())
    if not _check(bool(game.call("_restore_saved_session")), "A valid saved game must restore successfully"):
        return
    if not _check(int(game.get("score")) == saved_score, "Resume must restore the score"):
        return
    if not _check(game.get("board") == saved_board, "Resume must restore all 64 board cells"):
        return
    if not _check(game.get("pieces") == saved_pieces, "Resume must restore the three tray pieces"):
        return
    var restored_rng := game.get("game_rng") as RandomNumberGenerator
    if not _check(restored_rng.randi() == expected_next_random, "Resume must preserve the next deterministic piece RNG state"):
        return
    var saved_config := game.get("config") as ConfigFile
    saved_config.set_value("session", "board", [[0]])
    saved_config.save("user://blocknova.cfg")
    if not _check(not bool(game.call("_restore_saved_session")), "Malformed saved sessions must be rejected safely"):
        return
    game.call("_clear_saved_session")
    if not _check(not bool(game.call("_has_saved_session")) and not resume_button.visible, "Clearing a session must hide the resume action"):
        return

    # A saved 10x10 game is cropped to its central 8x8 area.
    var legacy_board: Array = []
    for y in range(10):
        var legacy_row: Array = []
        for x in range(10):
            legacy_row.append(-1)
        legacy_board.append(legacy_row)
    legacy_board[2][3] = 2
    saved_config.set_value("session", "available", true)
    saved_config.set_value("session", "version", 1)
    saved_config.set_value("session", "board", legacy_board)
    saved_config.save("user://blocknova.cfg")
    game.set("config", saved_config)
    if not _check(bool(game.call("_restore_saved_session")), "A valid legacy 10x10 session must migrate to 8x8"):
        return
    var migrated_board: Array = game.get("board")
    if not _check(migrated_board.size() == 8 and migrated_board[0].size() == 8, "Legacy sessions must become an 8x8 board"):
        return
    if not _check(int(migrated_board[1][2]) == 2, "Legacy board contents must be preserved in the central 8x8 area"):
        return
    game.call("_clear_saved_session")

    # Occupied cells and malformed boards must never be accepted as legal moves.
    var occupied_board := _empty_board()
    occupied_board[4][4] = 2
    game.set("board", occupied_board)
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(4, 4)), "An occupied cell must reject placement"):
        return

    game.set("board", [[0]])
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i.ZERO), "Malformed board dimensions must be rejected safely"):
        return

    # The 8x8 tray must not cause a false game-over when even one cell remains.
    var almost_full_board := []
    for y in range(8):
        var row: Array = []
        for x in range(8):
            row.append(-1 if y == 0 and x == 0 else 0)
        almost_full_board.append(row)
    game.set("board", almost_full_board)
    game.set("game_over", false)
    var tray_rng := game.get("game_rng") as RandomNumberGenerator
    tray_rng.seed = 8128
    game.call("_new_pieces")
    if not _check(bool(game.call("_any_move")) and not bool(game.get("game_over")), "Tray generation must preserve a legal one-cell move on an almost-full 8x8 board"):
        return
    if not _check(game.get("pieces")[0].size() == 1, "Almost-full board fallback must provide a one-cell piece"):
        return

    # A completely filled board has no legal move, even with the fallback piece.
    var blocked_board := []
    for y in range(8):
        var row: Array = []
        for x in range(8):
            row.append(0)
        blocked_board.append(row)
    game.set("board", blocked_board)
    game.set("pieces", [[Vector2i(0, 0)], [], []])
    if not _check(not game.call("_any_move"), "A completely full board must report no legal moves"):
        return
    game.set("game_over", false)
    game.call("_new_pieces")
    if not _check(bool(game.get("game_over")), "A completely full board must still trigger game over after tray retries"):
        return

    print("PASS: 8x8 daily challenge, active 2.5D scene/3D mesh, Android haptics, placement bounds, occupied-cell rejection, fair tray retries, one-cell fallback, simultaneous line clear, 15-cell fade cleanup, placement pop, combo score 630, no-move detection, disk save/reload/resume, corrupt-save rejection, deterministic RNG continuation")
    game.free()
    quit(0)

func _empty_board() -> Array:
    var result: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(8):
            row.append(-1)
        result.append(row)
    return result

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("FAIL: " + message)
        quit(1)
        return false
    return true
