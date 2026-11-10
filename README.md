# BlockNova

An original, mobile-first block puzzle game built with Godot 4.

## Current build

- Portrait-first interface designed for Android phones
- Home screen with Play and Settings
- 10×10 puzzle board and three shape choices
- Touch drag-and-drop placement with placement preview
- Completed row and column clearing
- Score, combo-style clear bonuses, and game-over flow
- Pause overlay with resume and return-to-home actions
- Persistent best score and settings using Godot's `user://` storage
- Optional handheld vibration feedback

## Run locally

1. Install Godot 4.x.
2. Open this repository's folder in Godot.
3. Run the project (main scene: `res://scenes/main.tscn`).

## Android status

The project is configured for a portrait mobile viewport and the compatibility renderer. An Android APK has **not yet been built or device-tested**. Android export templates, signing, and on-device touch/performance verification remain to be completed.

## Next development steps

1. Validate the current GDScript in Godot and test touch placement on a phone.
2. Add real audio effects, animation polish, and clearer placement feedback.
3. Add progression, daily challenges, and expanded game modes.
4. Configure Android export and produce a test APK.

BlockNova is an original project inspired by the block-puzzle genre. It does not use Block Blast branding or assets.
