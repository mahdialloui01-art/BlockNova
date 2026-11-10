# BlockNova

An original, mobile-first block puzzle game built with Godot 4.

## Current build

- Portrait-first interface designed for Android phones
- Home screen with Play and Settings
- 10×10 puzzle board and three shape choices
- Touch drag-and-drop placement with placement preview
- Completed row and column clearing
- Score, consecutive-clear combo streaks, and game-over flow
- Pause overlay with resume and return-to-home actions
- Persistent best score and settings using Godot's `user://` storage
- Optional handheld vibration feedback

## Run locally

1. Install Godot 4.x.
2. Open this repository's folder in Godot.
3. Run the project (main scene: `res://scenes/main.tscn`).

## Automated validation

GitHub Actions imports the original 3D model, parses the project, runs a main-scene startup smoke test, and executes a deterministic 10×10 placement/row-column-clear/combo regression test on pushes and pull requests.

## Android status

The Android workflow now exports and signs a debug APK successfully on pushes. The latest artifact must still be installed and tested on a physical phone; production signing, store configuration, and on-device touch/performance verification remain pending.

## Next development steps

1. Install the latest Actions APK and verify touch placement, drag preview, 10×10 scaling, and 3D rendering on a phone.
2. Add real audio effects, animation polish, and clearer placement feedback.
3. Add progression, daily challenges, and expanded game modes.
4. Profile rendering and memory use on lower-end Android devices.

BlockNova is an original project inspired by the block-puzzle genre. It does not use Block Blast branding or assets.
