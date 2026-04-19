# HANDOFF — Ultimate Portable AI Installer

**Branch:** `ultimate-installer` (branched from `56ac091`, pre-Forge mess)
**Date:** 2026-04-19
**Repo:** `smashingtags/USB-Uncensored-LLM` (GitHub name stays; product name changes)

## THE VISION (Michael's words, not mine)

One USB stick. Three things:

1. **Chat UI** (like ChatGPT) — talks to local uncensored GPU-accelerated models. Can install/remove models FROM the UI (no bat files). Drag-drop files. Slash commands.
2. **OpenClaude** inside **Portable VS Code** — real IDE + AI coding agent. Reads/writes files, runs shell, multi-provider (NIM free / OpenRouter / Gemini / Anthropic / OpenAI / local Ollama). All config + chats portable across Windows/Mac/Linux via shared `data/` folder.
3. **One installer** — GPU detect (Intel Arc / NVIDIA / AMD / Strix Halo / Apple Silicon / CPU), downloads engines + models + Node.js + VS Code Portable + MinGit. Everything self-contained.

Cross-platform: configure once on Windows, plug into Mac, everything works. `data/` folder shared. Each platform only needs its own `bin/` (engine binaries).

## WHAT 4.7 DID WRONG (14 PRs merged to main, all wrong direction)

Treated OpenClaude as a sidebar dashboard bolted onto the old chat UI. Renamed everything "Forge." Two UIs on two ports (:3333 chat, :3334 agent). Inverted architecture. Michael wanted OpenClaude AS the product with the GPU engine plugged in, not the other way around.

## WHAT TO KEEP from those 14 PRs (re-apply by hand, don't cherry-pick)

1. AMD + Strix Halo GPU detection in catalog.json + install scripts (PR #3)
2. SSE buffer fix in chat_server.py (PR #2)
3. Gemma 4 reasoning_content merge in chat_server.py (PR #4)
4. Debounced chat saves + engine warm-up in chat_server.py (from Phase B)
5. Coder models in catalog: Qwen2.5-Coder 7B, DeepSeek-Coder-V2 Lite, Nomic Embed

## SOURCE MATERIAL (all at /tmp/stick-origins/)

| ZIP | What | Role in the product |
|---|---|---|
| `USB-Uncensored-LLM-main.zip` | Original TechJarves chat stick | **Chat UI base** (FastChatUI.html + chat_server.py) |
| `OpenClaude-Multi-Platform-main.zip` | Portable Claude Code clone | **Coding agent** (dashboard/server.mjs + index.html, per-platform scripts) |
| `Portable-AI-USB-main.zip` | Older TechJarves installer | Reference for install UX patterns |
| `Local_AI_MultiPlatform-main.zip` | Flutter native AI chat app | Future reference (native GUI via llamadart). Not used in this build. |
| `Openclaw-Termux-NoRoot-main.zip` | Android Telegram bot | Not used. |

Also on Mac: originals at `~/.openclaw/Shared With Claude/Eightly-stick-beginnings/`

## CORRECT ARCHITECTURE

```
Ultimate-AI-Stick/
├── install.bat / install.command / install.sh    <- ONE entry point per OS
│     Step 1: GPU detect
│     Step 2: Download Ollama engine (catalog-driven, per-GPU)
│     Step 3: Download models (user picks from menu)
│     Step 4: Download Node.js portable
│     Step 5: Download VS Code Portable (Windows) / code-server (Mac/Linux)
│     Step 6: Download MinGit (Windows)
│     Step 7: Install OpenClaude as VS Code extension / terminal tool
│     Step 8: Smoke test
│
├── start.bat / start.command / start.sh          <- ONE entry point per OS
│     1. Boot Ollama engine on :11438
│     2. Boot llama.cpp sidecar on :11441 (if Gemma 4 installed)
│     3. Boot chat_server.py on :3333 (chat UI)
│     4. Boot OpenClaude dashboard on :3000 (or inside VS Code)
│     5. Print banner with ALL URLs + LAN IP
│     6. Open browser
│
├── Shared/                                       <- cross-platform runtime
│   ├── catalog.json
│   ├── chat_server.py + FastChatUI.html          <- chat UI
│   ├── bin/<backend>/                            <- engines
│   ├── models/                                   <- GGUFs
│   └── chat_data/                                <- portable chats + settings
│
├── data/                                         <- OpenClaude portable config
│   ├── ai_settings.env                           <- API keys (encrypted on stick)
│   └── chats/                                    <- agent chat sessions
│
├── dashboard/                                    <- OpenClaude web UI
│   ├── server.mjs
│   └── index.html
│
├── tools/                                        <- bundled runtimes
│   ├── node/                                     <- Node.js portable
│   ├── git/                                      <- MinGit (Windows)
│   └── vscode/                                   <- VS Code Portable (or code-server)
│
└── Windows/ Mac/ Linux/                          <- platform-specific bins + scripts
    └── bin/                                      <- created by install (Node, etc.)
```

## WHAT'S DONE ON THIS BRANCH

- Branched from `56ac091` (clean: Eight.ly Stick refactor + SSE fix + AMD/Strix Halo + Gemma 4 reasoning fix)
- HANDOFF written
- Not yet started building the unified product

## NEXT STEPS

1. Restructure the folder layout to match the architecture above
2. Merge OpenClaude's scripts into the install/start flow
3. Add model management to the chat UI (install/uninstall from within FastChatUI)
4. Re-apply the 4 useful changes (debounce, warmup, coder models, etc.)
5. Add VS Code Portable download to the installer
6. Wire OpenClaude as a VS Code extension / integrated terminal tool
7. Rewrite README
8. Test end-to-end on amd-beast (Windows + Intel Arc)
9. Test on Mac Mini (Apple Silicon)
10. Replace main when verified
