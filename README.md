# Pictures: images from a description, drawn on your own machine

`!imagine a lighthouse in a storm, oil painting` and it posts the picture in
a thread under your message (or as a reply in the channel, if that is chosen
on its page in the app). So does a mention with a description after it, and anything written
to it in a direct chat. The caption gives the words and the seed, so the same
picture can be asked for again.

**Setting it up.** The picture program needs an NVIDIA graphics card with
8 GB or more, its driver, and a Python environment of its own; none of that
is part of this repository. With `uv` (https://docs.astral.sh/uv), which
fetches the right Python by itself:

```sh
# 1. Once: the environment and the libraries (about 6 GB).
uv venv --python 3.12 sd-env
uv pip install --python sd-env/bin/python torch --index-url https://download.pytorch.org/whl/cu124
uv pip install --python sd-env/bin/python diffusers transformers accelerate safetensors

# 2. The picture program. The first picture downloads the model (about 7 GB)
#    into ~/.cache/huggingface, or into the folder HF_HOME names.
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True sd-env/bin/python image_server.py &

# 3. The bot. With ffmpeg installed, pictures show in the chat itself;
#    without it they arrive as files to open.
python3 image_bot.py 127.0.0.1:7443
```

Once the model is there, `HF_HUB_OFFLINE=1` in front of step 2 keeps the
program from asking the internet anything at start. `--model` takes another
SDXL model by its Hugging Face name or a folder. Nothing a picture is made
from or into is kept: the program holds it in memory only long enough to
hand it over, and the bot's one temporary file is deleted once it is sent.

- Options, at the end of a description: `--wide`, `--tall`, `--square`;
  `--seed 1234`; `--steps 30`; `--no things to keep out`.
- `!again` makes the last description of the chat once more with a new seed.
  `!queue` shows the line; `!cancel` takes your own request out of it. One
  picture is made at a time; each person gets five in ten minutes, which
  those who manage bots change with `!images limit 20` (`0` for no limit).
- `!images here` (or `!images here #name`), from the owner or anyone with
  **Manage bots**, chooses a channel; once one is chosen it works only in
  chosen channels and direct chats. `!images leave` and `!images where` go
  with it.
- Adult pictures are refused everywhere until `!images adult nsfw`, which
  allows them in channels marked NSFW only; `!images adult off` goes back.
  Nothing looks at the pictures: the refusal is a check of the words asked
  for, and with adult off a few words are added to what is kept out. The
  model itself has no filter. It can still produce what nobody asked for,
  which is one more reason to choose its channels.

**The picture program.** `image_server.py` is the one file here that needs
more than the standard library: PyTorch and `diffusers`. It listens on this
machine only and answers the request the AUTOMATIC1111 web UI made common
(`/sdapi/v1/txt2img`), so `image_bot.py --api` can as well point at Forge or
SD.Next. The default model is Stable Diffusion XL.

**One graphics card, two models.** On an 8 GB card the picture model and the
chatbot's model do not fit together. The picture program asks Ollama to set
its model down before it loads, and unloads itself 45 seconds after the last
picture (`--idle`). So the chatbot's first answer right after pictures is
slow, and the first picture after a pause takes about ten seconds longer.

Measured on an RTX 4060 with 8 GB, 2026-10-10: about 16 seconds a picture at
1024 pixels and 25 steps; 7.5 GB of the card while drawing; about 4 GB of
ordinary memory. A first way of loading the model, which kept it in ordinary
memory between pictures, ran a 16 GB machine out of memory on the second
picture; the program now keeps the large part on the graphics card only.

## Get it running

You need a Corded server to join, and `corded-cli`, the headless client that
comes with every Corded release ([get one here](https://github.com/AndrewCromar/corded/releases)).

```sh
git clone https://github.com/opencorded/bot-pictures
cd bot-pictures
./setup.sh              # fetches the bot kit into ./kit and says what else is needed
export CORDED_CLI=/path/to/corded-cli     # not needed if corded-cli is on your PATH
python3 image_bot.py 127.0.0.1:7443
```

The first run makes a folder holding the bot's keys and a passphrase file that
only your user can read. Keep it: it *is* the bot's account. On an invite-only
server give an invite link in place of the address. The bot can run on any
machine that reaches the server; it does not have to be the server's.

To keep it running, and to see it on a page with everything else, list it in
the [host](https://github.com/opencorded/host).

## Other models

The picture program draws with any SDXL model that is on the machine in
Hugging Face's own layout (a `unet` and text encoders in half precision).
Fetch one, into the same place the first model went:

```sh
hf download SG161222/RealVisXL_V5.0 --include model_index.json "scheduler/*" "tokenizer*/*" \
    "*/config.json" "unet/*.fp16.safetensors" "text_encoder*/*.fp16.safetensors" "vae/*.fp16.safetensors"
```

(with `HF_HOME` set as it is for the picture program, and `hf` from its
environment). It then shows under **Model** on the bot's page in the app,
where the server's owner picks the one to draw with; the next picture uses
it. Nothing needs restarting. The stock model was trained with little adult
material in it; fine-tunes of it differ, and what a model will draw is its
maker's doing, not this bot's: the bot's own adult rule still decides where.

## Asked by another bot

Other bots can ask for a picture for someone (`picture`, see the kit's
"bots asking bots"): `{prompt, size, no}`, on that person's behalf. Given the
`room_id` and `event_id` of a message that person wrote, the picture is made
and posted under it exactly as if they had asked there, with the channel's
rules; otherwise the file goes back to the asking bot, and never an adult one.

## Turning it off and on

`!NAME off` and `!NAME on`, where NAME is the bot's username, from the server's
owner or anyone whose role has **Manage bots**. Off, it stays connected but
shows as offline and hears nothing except the command that wakes it.
`!NAME status` says which it is. The choice is kept across restarts.

## What it can read

Whatever a member in its place could: every message in the channels and chats
it is in, from the moment it joined. Give it a role that sees only the
channels it needs.

## Tests

```sh
python3 tests/smoke.py /folder/with/cordedd/and/corded-cli
```

runs the bot against a throwaway server on this machine.

Part of [Corded](https://github.com/AndrewCromar/corded). Apache-2.0.
