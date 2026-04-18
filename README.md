# Eight.ly Stick

**Eight.ly Stick** is a zero-install, GPU-accelerated, portable AI environment. Plug it into any Windows, macOS, or Linux machine, double-click one file, and have an uncensored local LLM running on GPU in under a minute. Everything lives on the stick (or local drive), nothing is installed on the host, nothing leaves the machine.

Part of the Eight.ly product family. Works equally well on a USB 3.0 stick, external SSD, or a folder on your primary drive.

## Why Eight.ly Stick is different

- **Real GPU acceleration.** Auto-detects Intel Arc, NVIDIA, Apple Silicon, or CPU-only and pulls the right engine. On Intel Arc it uses Intel's IPEX-LLM Ollama (SYCL / Level Zero). Verified **4.86x speedup** on an Arc Pro B50 versus CPU (63 tok/s vs 13 tok/s on Gemma 2 2B).
- **Verifies what it installs.** Old portable-LLM installers write model files and call it done. Eight.ly Stick calls `ollama create` and then checks the manifest is actually registered. If import fails, it tells you - it doesn't silently produce an empty registry.
- **Port-isolated.** Runs the engine on `:11438` and the chat UI on `:3333`, so it never collides with an existing Ollama or WSL Ollama already on `:11434`.
- **One file per platform.** Double-click `Windows\install.bat`, `Mac/install.command`, or `bash Linux/install.sh`. No prerequisites, no package manager.
- **Diagnose button.** Every install ships a `diagnose.bat` that prints your GPU, engine version, and runs a 100-token benchmark so you can *prove* acceleration is happening instead of hoping.

## Verified performance

| Host | Backend | Gemma 2 2B |
|---|---|---|
| Ryzen 9 3900X + Intel Arc Pro B50 (16 GB VRAM) | IPEX-LLM / SYCL | **63 tok/s** |
| Ryzen 9 3900X, CPU only (baseline for comparison) | stock Ollama | 13 tok/s |
| Apple M1 Pro (16 GB) | stock Ollama / Metal | **60 tok/s** |

## Quick start

### Windows
1. `Windows\install.bat` -> picks GPU, downloads engine + models, verifies each registers
2. `Windows\start.bat` -> launches engine + chat UI
3. Optional: `Windows\diagnose.bat` -> proves GPU acceleration

### macOS
1. `Mac/install.command`
2. `Mac/start.command` (opens browser automatically)

### Linux
1. `bash Linux/install.sh`
2. `bash Linux/start.sh`

## Model catalog

Curated GGUFs, Q4_K_M quantization, all from trusted uploaders (bartowski, Mungert, HauhauCS, TrevorJS).

| Model | Size | Notes |
|---|---|---|
| Gemma 2 2B Abliterated | 1.6 GB | Recommended. Fast on any hardware. |
| Phi-3.5 Mini 3.8B | 2.2 GB | Lightweight reasoning. |
| Dolphin 2.9 Llama 3 8B | 4.9 GB | Balanced uncensored. |
| Qwen3 8B Abliterated | 5.2 GB | Smart. Replaces the fake "Qwen 3.5" in the old repo. |
| Gemma 3n E4B Abliterated (Huihui) | 4.2 GB | MatFormer architecture. Replaces the fake "Gemma 4" in the old repo. |
| Gemma 4 E2B HauhauCS Aggressive | 2.4 GB | **Apple Silicon only** - requires Ollama 0.21+ MLX runtime |
| Gemma 4 E4B HauhauCS Aggressive | 4.5 GB | **Apple Silicon only** - multimodal (text/image/video/audio) |
| Gemma 4 E4B TrevorJS abliterated | 4.5 GB | **Apple Silicon only** - expert-granular abliteration |
| NemoMix Unleashed 12B | 7.5 GB | Heavyweight. Needs 16 GB RAM. |

Gemma 4 models are Apple Silicon only for now because Intel's IPEX-LLM build still targets Ollama 0.9.3 (pre-Gemma 4 architecture support). When IPEX-LLM ships a newer nightly, these models will light up on Arc too.

## Folder layout

```
Eight.ly Stick/
├── Windows/      install.bat, start.bat, diagnose.bat, install-core.ps1, diagnose.ps1
├── Mac/          install.command, start.command
├── Linux/        install.sh, start.sh
├── Android/      install.sh, start.sh (Termux, CPU only)
└── Shared/
    ├── catalog.json         single source of truth for engines + models
    ├── install-state.json   written by installer, read by launcher
    ├── chat_server.py       HTTP + WebSocket proxy and static server
    ├── FastChatUI.html      single-file SPA (dark, Eight.ly orange)
    ├── chat_data/           your chats, settings (created on first run)
    ├── models/              GGUFs + Modelfiles + Ollama registry
    └── bin/<backend>/       the engine for the current host
                             (windows-intel = IPEX-LLM, others = stock Ollama)
```

## Architecture decisions

- **One engine per backend.** `Shared/bin/windows-intel/` holds IPEX-LLM Ollama with SYCL/Level Zero. `Shared/bin/windows-nvidia/` holds stock Ollama with CUDA. `Shared/bin/darwin-apple/` holds stock Ollama with Metal. A single stick can carry all three and the launcher picks the right one per host.
- **Catalog-driven.** `Shared/catalog.json` is the source of truth. Installers read it; launchers read it for per-backend env vars; the UI can read it (future). Add a model by editing JSON.
- **No hosted dependencies.** Engines come from ollama/ollama and ipex-llm/ipex-llm releases. Weights come from HuggingFace bartowski/Mungert/HauhauCS/TrevorJS repos. No custom infra.

## LAN mobile access

Start it on your laptop, then on your phone hit `http://<laptop-ip>:3333`. The chat UI is mobile-responsive. If port 3333 is blocked by your firewall, allow inbound connections on 3333 locally.

## Troubleshooting

- **Slow on Windows + Arc.** Run `Windows\diagnose.bat`. If throughput is under 25 tok/s on Gemma 2B, your Arc driver is probably stale - update from https://intel.com/arc-drivers and rerun.
- **"Engine offline" in the UI footer.** The chat server can't reach `:11438`. Either `start.bat` hasn't finished booting the engine yet, or an old engine process is wedged - run `taskkill /f /im ollama.exe` and rerun start.
- **Gemma 4 fails to load.** Expected on Intel Arc until IPEX-LLM ships a newer nightly. On macOS, make sure you're on the latest install (which pins Ollama v0.21.0 for MLX Gemma 4 support).
- **Port conflict on :11434 or :3333.** Eight.ly Stick deliberately uses `:11438` for the engine to avoid your existing Ollama install. If you have another chat UI on `:3333`, edit `start.bat`'s `ELY_CHAT_PORT`.

## Credits

- Forked from TechJarves/USB-Uncensored-LLM and refactored into Eight.ly Stick.
- Intel IPEX-LLM team for the SYCL Ollama build.
- bartowski, Mungert, HauhauCS, TrevorJS for the GGUFs.
- Ollama team for the engine and the v0.21 MLX Gemma 4 runtime.

## License

MIT. See LICENSE file (upstream).

---

*Eight.ly Stick is uncompromising about computational freedom. The curated models are abliterated or aggressively uncensored - they won't moralize, lecture, or refuse. Use responsibly.*
