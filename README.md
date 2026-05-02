# ARKSA_ServerMaintainer

A Rust + Slint GUI tool to maintain a personal **ARK: Survival Ascended** dedicated server on Windows.

This is a personal-use **re-implementation** of [ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) by *Dの人*. The upstream author explicitly permits forks and re-implementations in other languages. The reference Object Pascal source is preserved under [`_forked/`](./_forked/) for cross-checking only — it is not built.

> ⚠️ Status: **Phase 0 — workspace skeleton only.** No functional behavior yet. See [`docs/architecture.md`](./docs/architecture.md) for the planned phases.

---

## Goals

- Win32 API access with memory safety → **Rust**
- Native-looking desktop GUI → **Slint**
- Single dedicated server (personal use) — no multi-server orchestration
- English first, Japanese as a second locale

## Non-goals

- Multi-server fleet management (upstream's ARKestra UI is not ported)
- Linux / macOS support — Windows-only

---

## Workspace layout

```
ARKSA_ServerMaintainer/
├── Cargo.toml              # workspace
├── rust-toolchain.toml
├── _forked/                # upstream Pascal source, reference only
├── assets/                 # ModList / EngramData / ItemData / DinoData / List
├── crates/
│   ├── arksa-core/         # lib: server control, RCON, process, INI, mod data
│   ├── arksa-notify/       # lib: Discord webhook + tray notifications
│   ├── arksa-gui/          # bin: main GUI (Slint)
│   ├── arksa-updater/      # bin: self-updater (GitHub Releases)
│   ├── arksa-commander/    # bin: CLI command sender
│   └── arksa-nbcall/       # bin: ConPTY child runner (replaces upstream NBCall.exe)
└── docs/architecture.md
```

## Build (Windows)

Prerequisites:
- Rust stable (`rustup default stable`)
- MSVC toolchain (`x86_64-pc-windows-msvc`) — installed by `rustup` on Windows
- Visual Studio 2022 *Build Tools* (or VS itself) for the MSVC linker

```powershell
# from the project root
cargo run -p arksa-gui
# or release
cargo build --release -p arksa-gui
```

The first build downloads Slint, the `windows` crate and the Skia renderer; expect ~5–10 minutes on a cold cache.

## Provenance & License

- Code: **MIT** (see [`LICENSE`](./LICENSE))
- Upstream attribution: [`LICENSE`](./LICENSE) tail section
- Reference Pascal source under `_forked/` belongs to the upstream author

## Roadmap

See [`docs/architecture.md`](./docs/architecture.md) for the phase-by-phase plan and the .pas → Rust mapping.
