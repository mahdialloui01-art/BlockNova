extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var main_scene := load("res://scenes/main.tscn") as PackedScene
    if not _check(main_scene != null, "The active Android scene must load"):
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
    if not _check(initial_board.size() == 10, "New game must create exactly 10 rows"):
        return
    for row in initial_board:
        if not _check(row is Array and row.size() == 10, "Every board row must contain exactly 10 cells"):
            return

    # Prepare a full bottom row and right column with one shared empty corner.
    var test_board := _empty_board()
    for x in range(9):
        test_board[9][x] = 0
    for y in range(9):
        test_board[y][9] = 0

    game.set("board", test_board)
    game.set("pieces", [[Vector2i(0, 0)], [], []])
    game.set("piece_colors", [Color("#27DDF2")])
    game.set("selected", 0)

    if not _check(game.call("_can_place", [Vector2i(0, 0)], Vector2i(9, 9)), "A single block must fit in the bottom-right cell"):
        return
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(10, 9)), "Placement beyond the right edge must be rejected"):
        return
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(9, 10)), "Placement beyond the bottom edge must be rejected"):
        return
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(-1, 9)), "Negative coordinates must be rejected"):
        return

    game.call("_try_place", Vector2i(9, 9))
    var final_board: Array = game.get("board")
    for i in range(10):
        if not _check(int(final_board[9][i]) == -1, "Completed bottom row was not cleared"):
            return
        if not _check(int(final_board[i][9]) == -1, "Completed right column was not cleared"):
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
    if not _check(game.get("board") == saved_board, "Resume must restore all 100 board cells"):
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

    # Occupied cells and malformed boards must never be accepted as legal moves.
    var occupied_board := _empty_board()
    occupied_board[4][4] = 2
    game.set("board", occupied_board)
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i(4, 4)), "An occupied cell must reject placement"):
        return

    game.set("board", [[0]])
    if not _check(not game.call("_can_place", [Vector2i(0, 0)], Vector2i.ZERO), "Malformed board dimensions must be rejected safely"):
        return

    # A completely filled board with a one-cell piece has no legal move.
    var blocked_board := []
    for y in range(10):
        var row: Array = []
        for x in range(10):
            row.append(0)
        blocked_board.append(row)
    game.set("board", blocked_board)
    game.set("pieces", [[Vector2i(0, 0)], [], []])
    if not _check(not game.call("_any_move"), "A completely full board must report no legal moves"):
        return

    print("PASS: 10x10 daily challenge seed/record, active 2.5D scene, 3D viewport/mesh, Android VIBRATE permission, haptic guard, edge bounds, occupied-cell rejection, simultaneous row/column clear, combo x1, score 630, no-move detection")
    game.free()
    quit(0)

func _empty_board() -> Array:
    var result: Array = []
    for y in range(10):
        var row: Array = []
        for x in range(10):
            row.append(-1)
        result.append(row)
    return result

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("FAIL: " + message)
        quit(1)
        return false
    return true
