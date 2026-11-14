# BlockNova

An original, mobile-first block puzzle game built with Godot 4.4.1. BlockNova has its own name, visual identity, procedural audio, and 3D block presentation.

## Active Android game

- Portrait-first interface for Android phones
- Dedicated home screen with Play and Settings
- **10×10 puzzle board** with three shape choices per turn
- Touch drag-and-drop placement with a continuously updated 3D preview
- Valid/invalid placement feedback and bounds/occupancy checks
- Completed row and column clearing, including simultaneous clears
- Short 3D placement-pop and line-clear fade animations, with temporary viewport updates only while effects are active
- Score, consecutive-clear combo streaks, and no-move/game-over detection
- Pause overlay with resume and return-to-home actions
- Original procedurally generated sound effects and ambient synth music
- Optional haptic feedback for pickup, invalid moves, placement, and line clears, with a user-controlled setting
- Deterministic daily challenge: the same local-date seed and piece/color sequence for every replay, with a date-specific best score
- Persistent best score, sound/settings preferences, and an in-progress game session in Godot's `user://` storage
- A conditional **Resume Last Game** home-screen action that restores the 10×10 board, tray pieces, score, combo, daily-mode date/record, and the dedicated random-number-generator state
- Automatic migration of older saved 8×8 sessions into the center of the 10×10 board, preserving their placed blocks

The active scene is `res://scenes/main.tscn`, which uses `scripts/main_2_5d.gd` and the shared rules in `scripts/main.gd`. The separate `scripts/main_3d.gd` prototype is kept aligned to the same 10×10 board size.

## Run locally

1. Install Godot 4.4.1.
2. Open this repository's folder in Godot.
3. Run the project (main scene: `res://scenes/main.tscn`).

## Automated validation

GitHub Actions imports the original 3D model, parses the project, runs a main-scene startup smoke test, and executes deterministic regression checks against the actual 2.5D Android scene. The tests verify its 3D viewport and rounded block mesh, deterministic daily challenge seed and date-specific record, Android VIBRATE permission and safe haptic preference guard, plus 10×10 bounds, occupied cells, simultaneous row/column clearing, combo scoring, no-move detection, saved-session round trips, malformed-save rejection, and deterministic RNG continuation after resume. The Android build also inspects the exported manifest for VIBRATE and verifies the APK signature before uploading it.

## Android build status

The Android workflow exports and signs a debug APK on pushes to `main`. The debug APK is suitable for installation/testing, but it is not a production release signed with a Play Store upload key.

## Remaining verification and development

1. Install the latest Actions APK on a physical phone and verify touch placement, drag preview, 10×10 scaling, 3D rendering, and performance.
2. Confirm haptic strength and timing on a physical phone, verify the placement-pop and line-clear fade animations and tune their timing.
3. Expand daily challenges with progression, streaks, and additional original game modes.
4. Profile rendering, audio generation cost, and memory use on lower-end Android devices.
5. Configure production signing and store metadata before release.

BlockNova is an original project inspired by the block-puzzle genre. It does not use Block Blast branding or assets.
