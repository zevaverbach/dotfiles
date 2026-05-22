#!/bin/bash
# Setup KittenTTS in a dedicated venv inside VoiceServer/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.kitten-venv"

echo "🐱 Setting up KittenTTS..."

if [ -d "$VENV_DIR" ]; then
    echo "   Venv exists at $VENV_DIR, reinstalling..."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

pip install -q \
    'https://github.com/KittenML/KittenTTS/releases/download/0.8.1/kittentts-0.8.1-py3-none-any.whl' \
    soundfile \
    'numpy<2'

# Pre-download the nano model (default, fastest)
echo "🐱 Pre-downloading nano model..."
python3 -c "
from kittentts import KittenTTS
m = KittenTTS('KittenML/kitten-tts-nano-0.8')
audio = m.generate('Setup complete.', voice='Jasper')
print(f'   Generated {len(audio)/24000:.1f}s test audio. Ready!')
"

echo "🐱 KittenTTS setup complete!"
echo "   Venv: $VENV_DIR"
echo "   Default model: nano (15M params, ~5x real-time on CPU)"
