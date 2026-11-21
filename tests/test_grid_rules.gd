extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var main_scene := load("res://scenes/main.tscn") as PackedScene
    if not _check(main_scene != null, "The active Android scene must load"):
        return
    var rules_script := load("res://scripts/main.gd") as GDScript
    if not _check(rules_script != null and int(rules_script.get_script_constant_map().get("GRID", -1)) == 10, "Shared gameplay rules must use a 10x10 board"):
        return
    var alternate_3d_script := load("res://scripts/main_3d.gd") as GDScript
    if not _check(alternate_3d_script != null and int(alternate_3d_script.get_script_constant_map().get("GRID", -1)) == 10, "Alternate 3D mode must also use a 10x10 board"):
        return
    var game := main_scene.instantiate() as Control
    if not _check(game != null and game.get_script().resource_path == "res://scripts/main_2_5d.gd", "Regression tests must instantiate the active 2.5D scene"):
        return
    root.add_child(game)
    await process_frame
    var home_ui: CanvasLayer = game.get("home_ui") as CanvasLayer
    if not _check(home_ui != null, "Active game must initialize the home UI before streak assertions"):
        return

    # Older installations stored one combined sound preference. When the new
    # music key is absent, both independent channels must inherit that value.
    var legacy_audio_config := ConfigFile.new()
    legacy_audio_config.set_value("records", "best", int(game.get("best")))
    legacy_audio_config.set_value("settings", "sound", false)
    legacy_audio_config.set_value("settings", "voice", true)
    legacy_audio_config.set_value("settings", "vibration", true)
    if not _check(legacy_audio_config.save("user://blocknova.cfg") == OK, "Legacy audio settings must be writable for migration coverage"):
        return
    game.call("_load_settings")
    game.call("_update_music_state")
    if not _check(not bool(game.get("sound_enabled")) and not bool(game.get("music_enabled")), "Legacy SOUND OFF must migrate to effects OFF and music OFF"):
        return

    legacy_audio_config.set_value("settings", "sound", true)
    if not _check(legacy_audio_config.save("user://blocknova.cfg") == OK, "Updated legacy audio settings must be writable"):
        return
    game.call("_load_settings")
    game.call("_update_music_state")
    if not _check(bool(game.get("sound_enabled")) and bool(game.get("music_enabled")), "Legacy SOUND ON must migrate to effects ON and music ON"):
        return
    
    # Daily streaks advance once per completed local calendar day.
    if not _check(int(game.call("_date_ordinal", "2028-02-29")) > 0 and int(game.call("_date_ordinal", "2027-02-29")) == -1, "Gregorian leap days must be validated correctly"):
        return
    if not _check(int(game.call("_date_ordinal", "2026-02-30")) == -1 and int(game.call("_date_ordinal", "bad-date")) == -1, "Malformed calendar dates must be rejected"):
        return
    if not _check(int(game.call("_next_daily_streak", 0, "", "2026-11-20")) == 1, "The first completed daily challenge must start a one-day streak"):
        return
    if not _check(int(game.call("_next_daily_streak", 4, "2026-11-20", "2026-11-20")) == 4, "Repeating a completed challenge on the same date must not increase the streak"):
        return
    if not _check(int(game.call("_next_daily_streak", 4, "2026-11-20", "2026-11-21")) == 5, "Completing the next calendar day must extend the streak"):
        return
    if not _check(int(game.call("_next_daily_streak", 4, "2026-11-19", "2026-11-21")) == 1, "Missing a calendar day must reset the streak"):
        return
    if not _check(int(game.call("_daily_streak_for_today", 5, "2026-11-20", "2026-11-20")) == 5 and int(game.call("_daily_streak_for_today", 5, "2026-11-20", "2026-11-21")) == 5, "An active streak must remain visible on its completion day and the following day"):
        return
    if not _check(int(game.call("_daily_streak_for_today", 5, "2026-11-19", "2026-11-21")) == 0 and int(game.call("_daily_streak_for_today", 5, "bad-date", "2026-11-21")) == 0, "A missed day or invalid date must not display a stale streak"):
        return
    if not _check(int(game.call("_next_daily_streak", 2, "2026-01-31", "2026-02-01")) == 3 and int(game.call("_next_daily_streak", 2, "2025-12-31", "2026-01-01")) == 3, "Streaks must continue across month and year boundaries"):
        return
    if not _check(int(game.call("_next_daily_streak", 2, "2028-02-28", "2028-02-29")) == 3 and int(game.call("_next_daily_streak", 3, "2028-02-29", "2028-03-01")) == 4, "Streaks must handle leap-day transitions"):
        return
    if not _check(home_ui.has_method("set_daily_streak") and home_ui.get_node_or_null("FullScreenHome/DailyStreakLabel") != null, "Home screen must expose the daily streak indicator"):
        return
    game.set("daily_mode", true)
    game.set("daily_streak", 2)
    game.set("daily_last_completed_date", "2026-11-19")
    game.set("daily_date_key", "2026-11-20")
    game.call("_record_daily_completion")
    if not _check(int(game.get("daily_streak")) == 3 and str(game.get("daily_last_completed_date")) == "2026-11-20", "Completing today's challenge must persist the incremented streak and date"):
        return
    game.call("_record_daily_completion")
    if not _check(int(game.get("daily_streak")) == 3, "Recording the same daily completion twice must not double-count it"):
        return
    var streak_config := ConfigFile.new()
    if not _check(streak_config.load("user://blocknova.cfg") == OK and int(streak_config.get_value("daily_progress", "streak", 0)) == 3 and str(streak_config.get_value("daily_progress", "last_completed_date", "")) == "2026-11-20", "Daily streak and completion date must survive a config reload"):
        return
    game.set("daily_mode", false)
    game.set("daily_date_key", "")
    game.set("daily_streak", 3)
    home_ui.call("set_daily_streak", 3)

    # Verify the raw WAV contract as well as Godot's ability to load each cue.
    var required_voice_assets := [
        "res://assets/audio/voice_good.wav",
        "res://assets/audio/voice_amazing.wav",
        "res://assets/audio/voice_unstoppable.wav",
        "res://assets/audio/voice_legendary.wav",
        "res://assets/audio/voice_game_over.wav"
    ]
    for voice_path in required_voice_assets:
        if not _check(FileAccess.file_exists(voice_path), "Generated combo voice asset is missing: " + voice_path):
            return
        if not _check(_voice_asset_is_pcm_48k_mono(voice_path), "Generated voice WAV must be 48 kHz, 16-bit mono PCM: " + voice_path):
            return

    # Verify that each combo milestone routes to a decodable Godot audio stream.
    var voice_cases := [
        {"level": 3, "cue": "good"},
        {"level": 5, "cue": "amazing"},
        {"level": 8, "cue": "unstoppable"},
        {"level": 10, "cue": "legendary"}
    ]
    game.set("sound_enabled", true)
    var voice_player := game.get("_combo_voice_player") as AudioStreamPlayer
    var loaded_voice_streams: Dictionary = game.get("_combo_voice_streams")
    for voice_case in voice_cases:
        var cue := str(voice_case["cue"])
        game.call("_play_combo_voice", int(voice_case["level"]))
        var voice_stream := loaded_voice_streams.get(cue) as AudioStream
        if not _check(voice_stream != null, "Combo milestone must load its mapped voice cue: " + cue):
            return
        if not _check(voice_player.stream == voice_stream, "Combo milestone must play the correct voice cue: " + cue):
            return
        voice_player.stop()

    game.call("_play_voice_cue", "game_over")
    var game_over_voice := loaded_voice_streams.get("game_over") as AudioStream
    if not _check(game_over_voice != null and voice_player.stream == game_over_voice, "Game-over voice cue must load and route correctly"):
        return
    voice_player.stop()
    var good_voice := loaded_voice_streams.get("good") as AudioStream
    game.set("sound_enabled", false)
    game.set("music_enabled", false)
    game.call("_update_music_state")
    game.set("voice_enabled", true)
    game.call("_play_voice_cue", "good")
    if not _check(voice_player.stream == good_voice, "Voice announcer must remain available when music and effects are disabled"):
        return
    voice_player.stop()
    game.set("voice_enabled", false)
    game.set("sound_enabled", true)
    game.call("_play_voice_cue", "amazing")
    if not _check(voice_player.stream == good_voice, "Disabling the announcer must prevent a new voice cue"):
        return

    # Sound effects and music have separate runtime gates.
    var background_music_player := game.get("_music_player") as AudioStreamPlayer
    var sfx_players: Dictionary = game.get("_sfx_players")
    var ui_sfx_player := sfx_players.get("ui") as AudioStreamPlayer
    game.set("sound_enabled", false)
    game.set("music_enabled", true)
    game.call("_update_music_state")
    game.call("_play_sfx", "ui")
    if not _check(not ui_sfx_player.playing and background_music_player.playing, "Disabling sound effects must not stop background music"):
        return
    game.set("sound_enabled", true)
    game.set("music_enabled", false)
    game.call("_update_music_state")
    game.call("_play_sfx", "ui")
    if not _check(ui_sfx_player.playing and not background_music_player.playing, "Disabling music must not stop sound effects"):
        return
    ui_sfx_player.stop()

    # Exercise all settings hit targets and verify each preference persists.
    game.set("screen", 1) # Screen.SETTINGS
    game.set("sound_enabled", true)
    game.set("music_enabled", true)
    game.set("voice_enabled", true)
    game.call("_pointer_down", Vector2(game.size.x * 0.70, game.size.y * 0.45))
    if not _check(not bool(game.get("sound_enabled")) and bool(game.get("music_enabled")), "Sound-effects row must not toggle music"):
        return
    game.call("_pointer_down", Vector2(game.size.x * 0.70, game.size.y * 0.535))
    if not _check(not bool(game.get("music_enabled")) and not bool(game.get("sound_enabled")), "Music row must not toggle sound effects"):
        return
    game.call("_pointer_down", Vector2(game.size.x * 0.70, game.size.y * 0.62))
    if not _check(not bool(game.get("voice_enabled")), "Voice row must toggle the announcer independently"):
        return
    var saved_settings := ConfigFile.new()
    saved_settings.load("user://blocknova.cfg")
    if not _check(not bool(saved_settings.get_value("settings", "sound", true)), "Sound-effects preference must persist"):
        return
    if not _check(not bool(saved_settings.get_value("settings", "music", true)), "Music preference must persist"):
        return
    if not _check(not bool(saved_settings.get_value("settings", "voice", true)), "Voice preference must persist"):
        return
    game.set("screen", 0) # Return to the home scene before later tests initialize a board.
    game.set("sound_enabled", false)
    game.set("music_enabled", false)
    game.call("_update_music_state")
    game.set("voice_enabled", true)
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
    if not _check(effects_root.get_child_count() == 3, "Placement pop, placement ripple, and line-clear feedback must create separate lightweight effects"):
        return
    if not _check(int(game.get("_active_visual_effects")) == 3, "All placement and line-clear visual effects must be tracked while animating"):
        return
    var placement_effect := effects_root.get_node_or_null("PlacementPop") as MeshInstance3D
    if not _check(placement_effect != null, "Each placed cube must receive a tracked placement-pop effect"):
        return
    var spark_positions: Array[Vector3] = []
    for child in placement_effect.get_children():
        if str(child.name).begins_with("PieceCellSpark_") and child is Node3D:
            spark_positions.append((child as Node3D).position)
    if not _check(spark_positions.size() == 6, "Each placed cube must emit six energy sparks"):
        return
    for i in range(spark_positions.size()):
        for j in range(i + 1, spark_positions.size()):
            if not _check(spark_positions[i].distance_to(spark_positions[j]) > 0.10, "Energy sparks must be distributed without overlapping"):
                return
    var effect_viewport := game.get("_viewport") as SubViewport
    if not _check(effect_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "The 3D viewport must update only while transient effects animate"):
        return
    await create_timer(0.70).timeout
    await process_frame
    if not _check(int(game.get("_active_visual_effects")) == 0 and effects_root.get_child_count() == 0, "Transient effects must clean themselves up after animation"):
        return
    if not _check(effect_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "The 3D viewport must return to idle mode after effects finish"):
        return
    var music_player := game.get("_music_player") as AudioStreamPlayer
    var music_stream := music_player.stream as AudioStreamWAV if music_player != null else null
    if not _check(music_stream != null and music_stream.mix_rate == 48000, "Background music must use clean 48 kHz mobile playback"):
        return
    if not _check(music_stream.data.size() == 48000 * 10 * 4, "Background music must remain a 10-second stereo loop"):
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

    # Exercise the Android touch path: grab the right cell of a two-cell piece and drop it at board cell (5, 4).
    game.size = Vector2(1080, 2160)
    game.call("_layout")
    game.call("_reset_game")
    game.set("board", _empty_board())
    game.set("pieces", [[Vector2i(0, 0), Vector2i(1, 0)], [], []])
    game.set("piece_colors", [Color("#27DDF2"), Color("#FFB84D"), Color("#A78BFA")])
    var tray_center := Vector2(game.size.x / 6.0, float(game.get("tray_y")) + 55.0)
    var grab_point := tray_center + Vector2(10.0, 0.0)
    var touch_start := InputEventScreenTouch.new()
    touch_start.index = 0
    touch_start.position = grab_point
    touch_start.pressed = true
    game.call("_input", touch_start)
    if not _check(int(game.get("selected")) == 0 and bool(game.get("dragging")), "Touching a tray piece must begin a drag"):
        return
    if not _check(game.get("drag_cell_offset") == Vector2i(1, 0), "Touch drag must preserve the exact piece cell held under the finger"):
        return
    var board_origin: Vector2 = game.get("board_origin")
    var cell_size: float = game.get("cell")
    var drop_point := board_origin + Vector2(5.5 * cell_size, 4.5 * cell_size)
    # A second finger may neither steal the selected piece nor move/release the first finger's drag.
    var secondary_touch := InputEventScreenTouch.new()
    secondary_touch.index = 1
    secondary_touch.position = Vector2(game.size.x * 0.5, float(game.get("tray_y")) + 55.0)
    secondary_touch.pressed = true
    game.call("_input", secondary_touch)
    if not _check(int(game.get("selected")) == 0 and bool(game.get("dragging")) and int(game.get("_active_touch_index")) == 0, "A second finger must not steal the active piece"):
        return
    var secondary_drag := InputEventScreenDrag.new()
    secondary_drag.index = 1
    secondary_drag.position = drop_point
    game.call("_input", secondary_drag)
    if not _check(game.get("pointer") == grab_point and bool(game.get("dragging")), "A second finger must not move the first finger's preview"):
        return
    var secondary_end := InputEventScreenTouch.new()
    secondary_end.index = 1
    secondary_end.position = drop_point
    secondary_end.pressed = false
    game.call("_input", secondary_end)
    if not _check(bool(game.get("dragging")) and int(game.get("_active_touch_index")) == 0, "A second finger must not release the active drag"):
        return
    var touch_drag := InputEventScreenDrag.new()
    touch_drag.index = 0
    touch_drag.position = drop_point
    game.call("_input", touch_drag)
    var touch_end := InputEventScreenTouch.new()
    touch_end.index = 0
    touch_end.position = drop_point
    touch_end.pressed = false
    game.call("_input", touch_end)
    var touch_board: Array = game.get("board")
    if not _check(int(touch_board[4][4]) == 0 and int(touch_board[4][5]) == 0, "Releasing the held right cell over board cell (5, 4) must place the piece at origin (4, 4)"):
        return
    if not _check(int(game.get("score")) == 10 and int(game.get("selected")) == -1 and not bool(game.get("dragging")) and int(game.get("_active_touch_index")) == -1, "A completed touch drop must score once and clear drag selection and pointer ownership"):
        return
    game.call("_reset_game")

    # Returning home during an active gesture must still release the owning finger.
    game.set("screen", 0)
    game.set("_active_touch_index", 2)
    var home_release := InputEventScreenTouch.new()
    home_release.index = 2
    home_release.position = grab_point
    home_release.pressed = false
    game.call("_input", home_release)
    if not _check(int(game.get("_active_touch_index")) == -1, "A touch release must clear pointer ownership even when the home UI handles the screen"):
        return
    game.call("_reset_game")

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
    var actual_cleared_cells: Array = game.get("_last_cleared_cells")
    var actual_cleared_colors: Dictionary = game.get("_last_cleared_colors")
    if not _check(actual_cleared_cells.size() == 19 and actual_cleared_colors.size() == 19, "Simultaneous row and column clearing must capture each unique cell and its color"):
        return
    if not _check(int(game.get("_active_visual_effects")) >= 19, "Every cleared tile must receive one short visual fade alongside combo celebration effects"):
        return
    await create_timer(0.90).timeout
    await process_frame
    if not _check(int(game.get("_active_visual_effects")) == 0, "All real line-clear and combo animations must finish and clean up"):
        return
    var final_board: Array = game.get("board")
    for i in range(10):
        if not _check(int(final_board[9][i]) == -1, "Completed bottom row was not cleared"):
            return
        if not _check(int(final_board[i][9]) == -1, "Completed right column was not cleared"):
            return

    var cleared_cells: Array = game.get("_last_cleared_cells")
    var cleared_colors: Dictionary = game.get("_last_cleared_colors")
    if not _check(cleared_cells.size() == 19, "Simultaneous 10x10 row and column clearing must report each cell once"):
        return
    if not _check(cleared_colors.size() == 19 and int(cleared_colors.get(Vector2i(9, 9), -1)) == 0, "Cleared-cell colors must be captured for renderer effects"):
        return

    if not _check(int(game.get("combo_streak")) == 2, "A simultaneous row and column clear in one placement must produce combo x2"):
        return
    game.call("_update_combo_streak", 1)
    if not _check(int(game.get("combo_streak")) == 3, "A following one-line clear must accumulate to combo x3"):
        return
    game.call("_update_combo_streak", 0)
    game.call("_update_combo_streak", 0)
    if not _check(int(game.get("combo_streak")) == 3 and int(game.get("combo_missed_placements")) == 2, "Combo must survive the first two pieces that clear no lines"):
        return
    game.call("_update_combo_streak", 2)
    if not _check(int(game.get("combo_streak")) == 5 and int(game.get("combo_missed_placements")) == 0, "A line clear must extend combo and reset the missed-piece counter"):
        return
    game.call("_update_combo_streak", 0)
    game.call("_update_combo_streak", 0)
    game.call("_update_combo_streak", 0)
    if not _check(int(game.get("combo_streak")) == 0 and int(game.get("combo_missed_placements")) == 0, "Combo must reset after three consecutive pieces without a line clear"):
        return
    game.call("_update_combo_streak", 3)
    if not _check(int(game.get("combo_streak")) == 3, "Clearing three lines together must immediately create combo x3"):
        return
    game.call("_update_combo_streak", 4)
    if not _check(int(game.get("combo_streak")) == 7, "Clearing four lines together must add four to the running combo"):
        return
    if not _check(int(game.call("_combo_score_bonus", 1)) == 50, "Combo x1 bonus must be 50 points"):
        return
    if not _check(int(game.call("_combo_score_bonus", 2)) == 200, "Combo x2 bonus must rise quadratically to 200 points"):
        return
    if not _check(int(game.call("_combo_score_bonus", 3)) == 450, "Combo x3 bonus must exceed the x2 bonus by a larger amount"):
        return
    if not _check(int(game.call("_combo_score_bonus", 5)) == 1250 and int(game.call("_combo_score_bonus", 10)) == 5000, "High combo levels must receive rapidly increasing rewards"):
        return
    game.set("combo_streak", 1)
    game.set("combo_missed_placements", 2)
    if not _check(int(game.get("score")) == 755, "Two-line same-placement clear score must include placement, clear, and x2 combo bonuses"):
        return
    if not _check(int(game.get("daily_best")) >= 755, "Daily challenge best score must persist the current run"):
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

    # A native 10x10 save must retain even occupied cells on the outer edge.
    var native_board := _empty_board()
    native_board[9][9] = 4
    saved_config.set_value("session", "available", true)
    saved_config.set_value("session", "version", 1)
    saved_config.set_value("session", "board", native_board)
    saved_config.save("user://blocknova.cfg")
    game.set("config", saved_config)
    if not _check(bool(game.call("_restore_saved_session")), "A native 10x10 session must restore successfully"):
        return
    var native_restored: Array = game.get("board")
    if not _check(native_restored.size() == 10 and int(native_restored[9][9]) == 4, "Native 10x10 saves must preserve occupied outer-edge cells"):
        return

    # Older 8x8 saves are expanded into the center of the 10x10 board without losing cells.
    var legacy_board: Array = []
    for y in range(8):
        var legacy_row: Array = []
        for x in range(8):
            legacy_row.append(-1)
        legacy_board.append(legacy_row)
    legacy_board[0][0] = 1
    legacy_board[3][4] = 2
    legacy_board[7][7] = 3
    saved_config.set_value("session", "available", true)
    saved_config.set_value("session", "version", 1)
    saved_config.set_value("session", "board", legacy_board)
    saved_config.save("user://blocknova.cfg")
    game.set("config", saved_config)
    if not _check(bool(game.call("_restore_saved_session")), "A valid legacy 8x8 session must migrate to 10x10"):
        return
    var migrated_board: Array = game.get("board")
    if not _check(migrated_board.size() == 10 and migrated_board[0].size() == 10, "Legacy sessions must become a 10x10 board"):
        return
    if not _check(int(migrated_board[1][1]) == 1 and int(migrated_board[4][5]) == 2 and int(migrated_board[8][8]) == 3, "Legacy board contents must be preserved in the centered 8x8 area"):
        return
    if not _check(int(migrated_board[0][0]) == -1 and int(migrated_board[9][9]) == -1, "New outer ring cells must start empty after migration"):
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

    # The 10x10 tray must not cause a false game-over when even one cell remains.
    var almost_full_board := []
    for y in range(10):
        var row: Array = []
        for x in range(10):
            row.append(-1 if y == 0 and x == 0 else 0)
        almost_full_board.append(row)
    game.set("board", almost_full_board)
    game.set("game_over", false)
    var tray_rng := game.get("game_rng") as RandomNumberGenerator
    tray_rng.seed = 8128
    game.call("_new_pieces")
    if not _check(bool(game.call("_any_move")) and not bool(game.get("game_over")), "Tray generation must preserve a legal one-cell move on an almost-full 10x10 board"):
        return
    if not _check(game.get("pieces")[0].size() == 1, "Almost-full board fallback must provide a one-cell piece"):
        return

    # A completely filled board has no legal move, even with the fallback piece.
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
    game.set("game_over", false)
    game.call("_new_pieces")
    if not _check(bool(game.get("game_over")), "A completely full board must still trigger game over after tray retries"):
        return

    print("PASS: 10x10 daily challenge, active 2.5D scene/3D mesh, independent voice/sound settings and persistence, Android haptics, placement bounds, occupied-cell rejection, fair tray retries, one-cell fallback, simultaneous line clear, 19-cell fade cleanup, placement pop, quadratic combo score 755, touch drag offset and drop, no-move detection, disk save/reload/resume, corrupt-save rejection, deterministic RNG continuation")
    # Stop generated music and sound effects before releasing the scene tree.
    for child in game.get_children():
        if child is AudioStreamPlayer:
            var audio_player := child as AudioStreamPlayer
            audio_player.stop()
            audio_player.stream = null
    game.queue_free()
    await process_frame
    # Let the audio server release any final playback references before exit.
    await create_timer(0.35).timeout
    await process_frame
    await process_frame
    # Release loaded scenes/scripts/streams before the headless runner exits.
    game = null
    main_scene = null
    rules_script = null
    alternate_3d_script = null
    music_player = null
    music_stream = null
    call_deferred("quit", 0)

func _empty_board() -> Array:
    var result: Array = []
    for y in range(10):
        var row: Array = []
        for x in range(10):
            row.append(-1)
        result.append(row)
    return result

func _voice_asset_is_pcm_48k_mono(path: String) -> bool:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() < 44:
        return false
    var riff := file.get_buffer(4).get_string_from_ascii()
    file.seek(8)
    var wave := file.get_buffer(4).get_string_from_ascii()
    file.seek(20)
    var audio_format := file.get_16()
    var channels := file.get_16()
    var sample_rate := file.get_32()
    file.seek(34)
    var bits_per_sample := file.get_16()
    file.close()
    return riff == "RIFF" and wave == "WAVE" and audio_format == 1 and channels == 1 and sample_rate == 48000 and bits_per_sample == 16

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("FAIL: " + message)
        quit(1)
        return false
    return true
