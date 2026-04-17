---
name: kokoro-tts-install-workaround
description: Install kokoro-onnx for Hyperframes TTS on macOS with pyenv (resolves onnxruntime dependency conflict)
category: media
---

# Kokoro-ONNX TTS Installation Workaround

## Context
On macOS (pyenv-managed Python), `pip install kokoro-onnx soundfile` fails with `ResolutionImpossible` due to onnxruntime version conflicts between packages.

## Solution (verified on macOS)

```bash
# Step 1: Install onnxruntime first (resolves the conflict)
pip install onnxruntime soundfile

# Step 2: Install kokoro-onnx without dependency resolution
pip install kokoro-onnx --no-deps

# Step 3: Verify
python3 -c "import kokoro_onnx; print('kokoro-onnx OK')"
```

## Hyperframes TTS Workflow

```bash
# Generate narration
npx hyperframes tts narration.txt --voice af_heart --speed 1.0 --output narration.wav

# Embed in composition (auto-synced via data-start)
<audio
  id="narration"
  data-start="0"
  data-duration="auto"
  data-track-index="2"
  src="narration.wav"
  data-volume="1"
></audio>
```

## Known Issues
- pyenv shim lock: `pyenv: cannot rehash: couldn't acquire lock ~/.pyenv/shims/.pyenv-shim` — restart shell or run `pyenv rehash` after install
- Kokoro models cached at `~/.cache/hyperframes/tts/` (~311 MB)
