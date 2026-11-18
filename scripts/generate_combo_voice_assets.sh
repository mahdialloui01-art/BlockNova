#!/usr/bin/env bash
set -euo pipefail

mkdir -p assets/audio
VOICE_DIR="${RUNNER_TEMP:-/tmp}/blocknova-piper-voice"
mkdir -p "$VOICE_DIR"

# Use a native Arabic male neural voice (Kareem), then render English game
# callouts in Arabic phonetic script. This produces an English-speaking Arabic
# accent rather than the previous generic US-English voice. Audio is bundled
# offline; no network/TTS dependency is needed while playing.
VOICE="ar_JO-kareem-medium"
MODEL="$VOICE_DIR/$VOICE.onnx"

python3 -m piper.download_voices "$VOICE" --download-dir "$VOICE_DIR"
test -s "$MODEL"
test -s "$MODEL.json"

curl --fail --location --retry 3 \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/ar/ar_JO/kareem/medium/MODEL_CARD" \
  --output assets/audio/VOICE_MODEL_CARD.txt
grep -qi "ar_JO" assets/audio/VOICE_MODEL_CARD.txt

speak() {
  local filename="$1"
  local phrase="$2"
  # 1.0 is normal speaking speed; emphatic wording and punctuation add energy.
  python3 -m piper -m "$MODEL" --length-scale 1.0 --noise-scale 0.78 --noise-w 0.8 -f "assets/audio/$filename" -- "$phrase"
  test -s "assets/audio/$filename"
  echo "Generated Arabic-accented English male voice cue: assets/audio/$filename"
}

# Phonetic Arabic spelling guides Kareem to pronounce the English callouts
# with a clear Arabic accent while keeping the spoken words recognizably English.
speak voice_good.wav "يَس!!! ذَاتْ إِزْ أَ جْرَيْتْ مُوف!!!"
speak voice_amazing.wav "وَاتْ أَ مُوف!!! يُو آرْ أُونْ فَايَر!!!"
speak voice_unstoppable.wav "أَنْسْتُوبَبُل!!! كِيبْ ذَاتْ سْتْرِيكْ أَلَايْڤ!!!"
speak voice_legendary.wav "إِنْكْرِدَبُل!!! ذَاتْ إِزْ لِجِنْدَرِي!!!"
speak voice_game_over.wav "گَيْمْ أُوڤَر!!! وَاتْ أَ رَنْ!!! كَمْ بَاكْ إِيڤِنْ سْتْرُونْگَر!!!"
