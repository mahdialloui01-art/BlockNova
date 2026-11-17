#!/usr/bin/env bash
set -euo pipefail
mkdir -p assets/audio
command -v espeak >/dev/null || { echo "espeak is required to build offline voice assets"; exit 1; }

# Warm, energetic English game-announcer voice. WAV files are bundled into the APK,
# so voice playback works offline and does not depend on Android TTS availability.
VOICE="en-us+f3"
SPEED=165
PITCH=58
AMPLITUDE=170

speak() {
  local filename="$1"
  local phrase="$2"
  espeak -v "$VOICE" -s "$SPEED" -p "$PITCH" -a "$AMPLITUDE" -w "assets/audio/$filename" "$phrase"
  test -s "assets/audio/$filename"
  echo "Generated offline voice cue: assets/audio/$filename"
}

speak voice_good.wav "Good!"
speak voice_amazing.wav "Amazing!"
speak voice_unstoppable.wav "Unstoppable!"
speak voice_legendary.wav "Legendary!"
speak voice_game_over.wav "Game over!"
