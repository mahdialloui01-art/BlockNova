# BlockNova

An original, mobile-first block puzzle game built with Godot 4.4.1. BlockNova has its own name, visual identity, procedural audio, and 3D block presentation.

## Active Android game

- Portrait-first interface for Android phones
- Dedicated home screen with Play and Settings
- **10×10 puzzle board** with three shape choices per turn
- Touch drag-and-drop placement with a continuously updated 3D preview
- Valid/invalid placement feedback and bounds/occupancy checks
- Completed row and column clearing, including simultaneous clears
- Score, consecutive-clear combo streaks, and no-move/game-over detection
- Pause overlay with resume and return-to-home actions
- Original procedurally generated sound effects and ambient synth music
- Persistent best score and sound/settings preferences in Godot's `user://` storage

The active scene is `res://scenes/main.tscn`, which uses `scripts/main_2_5d.gd` and the shared rules in `scripts/main.gd`. The separate `scripts/main_3d.gd` prototype is kept aligned to the same 10×10 board size.

## Run locally

1. Install Godot 4.4.1.
2. Open this repository's folder in Godot.
3. Run the project (main scene: `res://scenes/main.tscn`).

## Automated validation

GitHub Actions imports the original 3D model, parses the project, runs a main-scene startup smoke test, and executes deterministic 10×10 gameplay regression checks. The tests cover board dimensions, legal edge placement, invalid bounds, occupied cells, simultaneous row/column clearing, combo scoring, and no-move detection.

## Android build status

The Android workflow exports and signs a debug APK on pushes to `main`. The debug APK is suitable for installation/testing, but it is not a production release signed with a Play Store upload key.

## Remaining verification and development

1. Install the latest Actions APK on a physical phone and verify touch placement, drag preview, 10×10 scaling, 3D rendering, and performance.
2. Add and test haptic feedback and more placement/clear animations.
3. Add progression, daily challenges, and expanded game modes.
4. Profile rendering and memory use on lower-end Android devices.
5. Configure production signing and store metadata before release.

BlockNova is an original project inspired by the block-puzzle genre. It does not use Block Blast branding or assets.
