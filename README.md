# ARKSA_ServerMaintainer

A Rust + Slint GUI tool to maintain a personal **ARK: Survival Ascended** dedicated server on Windows.

This is a personal-use **re-implementation** of [ASA Server Manager (ASASM)](https://sites.google.com/view/asa-server-manager) by *Dの人*. The upstream author explicitly permits forks and re-implementations in other languages. The upstream Object Pascal source is **not redistributed** here; obtain it from the upstream distribution above if you need to cross-reference.

> ⚠️ Status: **Phase 4 — first usable build.** Single-server start/stop/status via the GUI, RCON, in-app new-profile dialog, and `Install / Update server` button work end-to-end. Backups, scheduled restarts, and the Discord/tray notification UIs are still pending. See [`docs/architecture.md`](./docs/architecture.md) for the phase-by-phase plan.

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

The first build downloads Slint, the `windows` crate and the software renderer; expect ~5–10 minutes on a cold cache.

## Running the GUI

The tool keeps its working data (profiles, the bundled `steamcmd`, logs) in
the directory pointed to by the `ARKSA_DIR` environment variable. The ARK
dedicated server install location is **separate** and is set per-profile
inside the GUI's New Profile dialog — typically on a different drive or a
larger disk.

Recommended layout:

```
D:\ARK\
├── ARKSA_Tools\           ← ARKSA_DIR (small: ~tens of MB)
│   ├── Profile\           created on first New Profile
│   │   └── MyServer.ini
│   └── steamcmd\          downloaded on first Install / Update
└── ARKSA_Server\          ← per-profile Install location (~tens of GB)
    └── ShooterGame\Binaries\Win64\ArkAscendedServer.exe
```

For convenience there is a [`run.example.ps1`](./run.example.ps1) launcher.
Copy it to `run.ps1` (gitignored), edit the `ARKSA_DIR` line to suit, then:

```powershell
.\run.ps1
```

First-time flow inside the GUI:

1. Click **Create your first server…**.
2. In the dialog, set **Install location** to where you want the dedicated
   server (e.g. `D:\ARK\ARKSA_Server`) and uncheck *Use path relative to
   ARKSA dir* unless you want it inside `ARKSA_DIR`.
3. Pick a map, accept the auto-generated admin password, click **Create**.
4. Back on the main window, click **Install / Update server** — the bundled
   steamcmd downloads and installs the dedicated server (~tens of GB).
5. Click **Start**. Use **Stop (graceful)** to shut down via
   `RCON SaveWorld` + `DoExit`.

Without `ARKSA_DIR` set, the tool defaults to the directory containing
`arksa-gui.exe` — fine for a shipped install, awkward during `cargo run`
because the executable lives under `target\debug\`.

## Provenance & License

- Code: **MIT** (see [`LICENSE`](./LICENSE))
- Upstream attribution: [`LICENSE`](./LICENSE) tail section
- The upstream Pascal/Lazarus source is **not** included here — fetch it from
  the upstream distribution if you need to cross-reference port decisions

## Roadmap

See [`docs/architecture.md`](./docs/architecture.md) for the phase-by-phase plan and the .pas → Rust mapping.
