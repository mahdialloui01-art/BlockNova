#!/usr/bin/env bash
set -euo pipefail
mkdir -p assets/audio
command -v espeak >/dev/null || { echo "espeak is required to build combo voice assets"; exit 1; }
espeak -v en-us+f3 -s 165 -p 58 -a 170 -w assets/audio/combo_good.wav "Good!"
espeak -v en-us+f3 -s 165 -p 58 -a 170 -w assets/audio/combo_amazing.wav "Amazing!"
espeak -v en-us+f3 -s 165 -p 58 -a 170 -w assets/audio/combo_unstoppable.wav "Unstoppable!"
espeak -v en-us+f3 -s 165 -p 58 -a 170 -w assets/audio/combo_legendary.wav "Legendary!"
for file in assets/audio/combo_*.wav; do
  test -s "$file"
  echo "Generated spoken combo cue: $file"
done
