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

    game.call("_reset_game")
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

    print("PASS: 10x10 active 2.5D scene, 3D viewport/mesh, Android VIBRATE permission, haptic guard, edge bounds, occupied-cell rejection, simultaneous row/column clear, combo x1, score 630, no-move detection")
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
