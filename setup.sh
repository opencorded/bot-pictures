#!/bin/sh
# Gets this bot ready to run: fetches the bot kit it is written with into
# ./kit, and says what else it needs. Safe to run again; that updates the kit.
set -e
cd "$(dirname "$0")"
KIT_VERSION="${CORDED_BOT_KIT_VERSION:-main}"
if [ -d kit/.git ]; then
    git -C kit fetch --quiet origin "$KIT_VERSION" && git -C kit checkout --quiet FETCH_HEAD
else
    rm -rf kit
    git clone --quiet --depth 1 --branch "$KIT_VERSION" https://github.com/opencorded/bot-kit kit
fi
echo "The bot kit is in ./kit."
if ! command -v corded-cli >/dev/null 2>&1 && [ -z "$CORDED_CLI" ]; then
    echo "corded-cli was not found on your PATH. Get a Corded release from"
    echo "https://github.com/AndrewCromar/corded/releases and set CORDED_CLI to the corded-cli in it."
fi
echo
if [ "$1" = "--with-picture-program" ]; then
    command -v uv >/dev/null 2>&1 || { echo "uv is needed for this: https://docs.astral.sh/uv"; exit 1; }
    uv venv --python 3.12 sd-env
    uv pip install --python sd-env/bin/python torch --index-url https://download.pytorch.org/whl/cu124
    uv pip install --python sd-env/bin/python diffusers transformers accelerate safetensors
    echo "The picture program's environment is in ./sd-env. Start it with:"
    echo "    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True sd-env/bin/python image_server.py"
    echo "The first picture downloads the model (about 7 GB)."
else
    echo "Pictures also needs a picture program on this machine (an NVIDIA card with 8 GB or more)."
    echo "    ./setup.sh --with-picture-program     sets up the one in this repository (about 6 GB, needs uv)"
    echo "or point the bot at Forge or SD.Next with --api."
fi
command -v ffmpeg >/dev/null 2>&1 || echo "ffmpeg is not installed: pictures will arrive as files to open, not shown in the chat."
