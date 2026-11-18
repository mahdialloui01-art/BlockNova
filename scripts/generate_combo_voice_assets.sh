#!/usr/bin/env bash
set -euo pipefail

mkdir -p assets/audio
VOICE_DIR="${RUNNER_TEMP:-/tmp}/blocknova-piper-voice"
mkdir -p "$VOICE_DIR"

# Piper is a local neural TTS engine. The selected en_US-john-medium voice is
# documented as a US English male voice with a public-domain training dataset.
# Audio is rendered during the APK build and bundled locally; gameplay needs no
# network connection and no TTS engine at runtime.
VOICE="en_US-john-medium"
MODEL="$VOICE_DIR/$VOICE.onnx"

python3 -m piper.download_voices "$VOICE" --download-dir "$VOICE_DIR"
test -s "$MODEL"
test -s "$MODEL.json"

# Keep the model's provenance and license notice alongside the generated assets.
curl --fail --location --retry 3 \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/john/medium/MODEL_CARD" \
  --output assets/audio/VOICE_MODEL_CARD.txt
grep -qi "public domain" assets/audio/VOICE_MODEL_CARD.txt

speak() {
  local filename="$1"
  local phrase="$2"
  python3 -m piper -m "$MODEL" -f "assets/audio/$filename" -- "$phrase"
  test -s "assets/audio/$filename"
  echo "Generated offline male voice cue: assets/audio/$filename"
}

speak voice_good.wav "Good!"
speak voice_amazing.wav "Amazing!"
speak voice_unstoppable.wav "Unstoppable!"
speak voice_legendary.wav "Legendary!"
speak voice_game_over.wav "Game over!"
