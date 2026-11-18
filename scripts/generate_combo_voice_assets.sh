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
command -v ffmpeg >/dev/null
command -v ffprobe >/dev/null

# Keep the model's provenance and license notice alongside the generated assets.
curl --fail --location --retry 3 \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/john/medium/MODEL_CARD" \
  --output assets/audio/VOICE_MODEL_CARD.txt
grep -qi "public domain" assets/audio/VOICE_MODEL_CARD.txt

speak() {
  local filename="$1"
  local phrase="$2"
  local raw="$VOICE_DIR/$filename"
  # Keep natural timing, but ask for a more animated delivery.
  python3 -m piper -m "$MODEL" --length-scale 1.0 --noise-scale 0.85 --noise-w 0.9 -f "$raw" -- "$phrase"
  test -s "$raw"

  # Master the cue for an energetic, forward sound: a subtle pitch lift,
  # controlled dynamics and consistent perceived loudness, without speeding it up.
  local sample_rate
  sample_rate="$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$raw")"
  ffmpeg -hide_banner -loglevel error -y -i "$raw" \
    -af "asetrate=${sample_rate}*1.035,aresample=${sample_rate},atempo=0.966184,acompressor=threshold=-18dB:ratio=3:attack=5:release=90,loudnorm=I=-16:TP=-1.0:LRA=7" \
    -c:a pcm_s16le "assets/audio/$filename"
  test -s "assets/audio/$filename"
  echo "Generated and mastered high-energy English voice cue: assets/audio/$filename"
}

speak voice_good.wav "OH YES! THAT IS A POWER MOVE!"
speak voice_amazing.wav "WHAT A MOVE! YOU ARE ABSOLUTELY ON FIRE!"
speak voice_unstoppable.wav "UNSTOPPABLE! KEEP THAT INCREDIBLE STREAK GOING!"
speak voice_legendary.wav "WOW! THAT IS LEGENDARY! YOU ARE A BEAST!"
speak voice_game_over.wav "WHAT A RUN! YOU FOUGHT LIKE A CHAMPION! LET'S GO AGAIN!"
