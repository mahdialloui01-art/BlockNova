#!/usr/bin/env bash
set -euo pipefail

mkdir -p assets/audio
VOICE_DIR="${RUNNER_TEMP:-/tmp}/blocknova-piper-voice"
mkdir -p "$VOICE_DIR"

# Offline Arabic neural TTS. Piper's available Arabic model is Jordanian Arabic,
# not a native Algerian voice; the phrases are written in Algerian Darija.
# All cues are pre-rendered at build time and bundled in the APK.
VOICE="ar_JO-kareem-medium"
MODEL="$VOICE_DIR/$VOICE.onnx"

python3 -m piper.download_voices "$VOICE" --download-dir "$VOICE_DIR"
test -s "$MODEL"
test -s "$MODEL.json"
command -v ffmpeg >/dev/null
command -v ffprobe >/dev/null

curl --fail --location --retry 3 \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/ar/ar_JO/kareem/medium/MODEL_CARD" \
  --output assets/audio/VOICE_MODEL_CARD.txt
grep -qi "ar_JO" assets/audio/VOICE_MODEL_CARD.txt

speak() {
  local filename="$1"
  local phrase="$2"
  local raw="$VOICE_DIR/$filename"
  # Preserve natural speaking speed while encouraging a more expressive delivery.
  python3 -m piper -m "$MODEL" --length-scale 1.0 --noise-scale 0.85 --noise-w 0.9 -f "$raw" -- "$phrase"
  test -s "$raw"

  # Force a conventional 48 kHz mono PCM WAV. FFmpeg's 192 kHz default
  # produced WAVE_FORMAT_EXTENSIBLE files that Godot 4.4.1 cannot import.
  ffmpeg -hide_banner -loglevel error -y -i "$raw" \
    -af "acompressor=threshold=-18dB:ratio=3:attack=5:release=90,loudnorm=I=-16:TP=-1.0:LRA=7" \
    -ar 48000 -ac 1 -c:a pcm_s16le -sample_fmt s16 -f wav "assets/audio/$filename"
  test -s "assets/audio/$filename"
  local output_codec output_rate
  output_codec="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "assets/audio/$filename")"
  output_rate="$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "assets/audio/$filename")"
  test "$output_codec" = "pcm_s16le"
  test "$output_rate" = "48000"
  echo "Generated 48 kHz PCM Arabic Darija voice cue: assets/audio/$filename"
}

speak voice_good.wav "يا سلام! كومبو مزدوج! بداية نارية!"
speak voice_amazing.wav "واش هذا الإبداع! خمسة كومبوهات! راك مولعها!"
speak voice_unstoppable.wav "يا لطيف! كومبو متواصل! ما توقفش، كمل يا بطل!"
speak voice_legendary.wav "لا لا لا! ضربة أسطورية! عشرة كومبوهات! مستحيل!"
speak voice_game_over.wav "ما عليهش! لعبت مليح يا بطل! نعاودوها ونرجعو أقوى!"
