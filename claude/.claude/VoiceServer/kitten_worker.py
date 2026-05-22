#!/usr/bin/env python3
"""
KittenTTS Worker — long-running stdin/stdout process for local TTS generation.

Protocol:
  IN  (stdin, one JSON per line):  {"text": "Hello world", "voice": "Jasper", "model": "nano"}
  OUT (stdout, one JSON per line): {"status": "ok", "path": "/tmp/kitten-1234.wav", "duration": 1.23, "gen_time": 0.45}
  ERR:                             {"status": "error", "message": "..."}

The worker loads the model once at startup and reuses it for all requests.
Supported models: nano, micro, mini (default: nano for lowest latency).
Supported voices: Bella, Jasper, Luna, Bruno, Rosie, Hugo, Kiki, Leo.
"""

import json
import sys
import time
import os
import tempfile

# Suppress numpy/torch warnings and KittenTTS stdout prints
import warnings
warnings.filterwarnings("ignore")
os.environ["TOKENIZERS_PARALLELISM"] = "false"

# Redirect stdout during import to suppress KittenTTS internal prints
import io
_real_stdout = sys.stdout
sys.stdout = io.StringIO()
from kittentts import KittenTTS
import soundfile as sf
sys.stdout = _real_stdout

MODEL_MAP = {
    "nano":  "KittenML/kitten-tts-nano-0.8",
    "micro": "KittenML/kitten-tts-micro-0.8",
    "mini":  "KittenML/kitten-tts-mini-0.8",
}

DEFAULT_MODEL = os.environ.get("KITTEN_TTS_MODEL", "nano")
DEFAULT_VOICE = os.environ.get("KITTEN_TTS_VOICE", "Jasper")

def main():
    model_name = DEFAULT_MODEL
    model_id = MODEL_MAP.get(model_name, MODEL_MAP["nano"])

    # Load model once at startup (suppress KittenTTS prints)
    sys.stderr.write(f"[kitten_worker] Loading model: {model_name} ({model_id})...\n")
    sys.stderr.flush()
    t0 = time.time()
    sys.stdout = io.StringIO()
    model = KittenTTS(model_id)
    sys.stdout = _real_stdout
    load_time = time.time() - t0
    sys.stderr.write(f"[kitten_worker] Model loaded in {load_time:.1f}s. Ready.\n")
    sys.stderr.flush()

    # Signal readiness
    print(json.dumps({"status": "ready", "model": model_name, "load_time": round(load_time, 2)}), flush=True)

    # Process requests from stdin
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            req = json.loads(line)
        except json.JSONDecodeError as e:
            print(json.dumps({"status": "error", "message": f"Invalid JSON: {e}"}), flush=True)
            continue

        text = req.get("text", "").strip()
        voice = req.get("voice", DEFAULT_VOICE)
        speed = req.get("speed")  # None means use library default (1.0)

        # Model hot-swap if requested (rare — usually stays on default)
        req_model = req.get("model", model_name)
        if req_model != model_name and req_model in MODEL_MAP:
            sys.stderr.write(f"[kitten_worker] Switching model: {model_name} → {req_model}\n")
            sys.stderr.flush()
            model_name = req_model
            sys.stdout = io.StringIO()
            model = KittenTTS(MODEL_MAP[model_name])
            sys.stdout = _real_stdout

        if not text:
            print(json.dumps({"status": "error", "message": "Empty text"}), flush=True)
            continue

        try:
            t0 = time.time()
            # Suppress KittenTTS stdout prints during generation
            gen_kwargs = {"voice": voice}
            if speed is not None:
                gen_kwargs["speed"] = float(speed)
            sys.stdout = io.StringIO()
            audio = model.generate(text, **gen_kwargs)
            sys.stdout = _real_stdout
            gen_time = time.time() - t0
            duration = len(audio) / 24000

            # Write to temp file
            fd, wav_path = tempfile.mkstemp(suffix=".wav", prefix="kitten-")
            os.close(fd)
            sf.write(wav_path, audio, 24000)

            print(json.dumps({
                "status": "ok",
                "path": wav_path,
                "duration": round(duration, 2),
                "gen_time": round(gen_time, 2),
            }), flush=True)

        except Exception as e:
            sys.stdout = _real_stdout
            print(json.dumps({"status": "error", "message": str(e)}), flush=True)

if __name__ == "__main__":
    main()
