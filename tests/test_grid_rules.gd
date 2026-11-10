extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var game := Control.new()
    game.set_script(load("res://scripts/main.gd"))
    game.size = Vector2(1080, 2160)
    root.add_child(game)
    await process_frame

    game.call("_reset_game")
    var initial_board: Array = game.get("board")
    if not _check(initial_board.size() == 8, "New game must create exactly 8 rows"):
        return
    for row in initial_board:
        if not _check(row.size() == 8, "Every board row must contain exactly 8 cells"):
            return

    var test_board: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(8):
            row.append(-1)
        test_board.append(row)

    # Prepare a full bottom row and right column with one shared empty corner.
    for x in range(7):
        test_board[7][x] = 0
    for y in range(7):
        test_board[y][7] = 0

    game.set("board", test_board)
    game.set("pieces", [[Vector2i(0, 0)], [], []])
    game.set("piece_colors", [Color("#48D7F2")])
    game.set("selected", 0)
    game.call("_try_place", Vector2i(7, 7))

    var final_board: Array = game.get("board")
    for i in range(8):
        if not _check(int(final_board[7][i]) == -1, "Completed bottom row was not cleared"):
            return
        if not _check(int(final_board[i][7]) == -1, "Completed right column was not cleared"):
            return

    if not _check(int(game.get("combo_streak")) == 1, "A successful line clear must start combo x1"):
        return
    if not _check(int(game.get("score")) == 630, "Two-line clear score must include placement, clear, and combo bonuses"):
        return

    print("PASS: 8x8 board, edge placement, simultaneous row/column clear, combo x1, score 630")
    game.queue_free()
    quit(0)

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("FAIL: " + message)
        quit(1)
        return false
    return true
